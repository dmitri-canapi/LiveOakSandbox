@isTest
public class AssessmentTriggerTest {
    @TestSetup
    private static void createTestData() {
        UserRole role = new UserRole(Name = 'Test Role');
        insert role;

        User testUser = new User(
            Alias = 'test', 
            Email = 'test@example.com',
            FirstName = 'Test', 
            LastName = 'User',
            UserName = 'test42445245@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Localesidkey = 'en_US', 
            ProfileId = UserInfo.getProfileId(),
            UserRoleId = role.Id,
            TimezoneSidKey = 'America/Los_Angeles',
            IsActive = true
        );
        insert testUser;

        System.runAs(testUser) {
            Account acc = new Account(Name = 'Test Account');
            insert acc;

            Account reviewerAccount = new Account(
                Name = 'Test Reviewer Account', 
                OwnerId = testUser.Id
            );
            insert reviewerAccount;

            Account reviewerAccount2 = new Account(
                Name = 'Test Reviewer Account 2', 
                OwnerId = testUser.Id
            );
            insert reviewerAccount2;

            Contact reviewerContact = new Contact(
                AccountId = reviewerAccount.Id, 
                FirstName = 'Test', 
                LastName = 'Reviewer'
            );
            insert reviewerContact;

            // disable user trigger so we can test assessment trigger in isolation
            AssessmentSharingService.RecalculateSharingOnCommunityUserCreation = false;

            Profile p = [SELECT Id, Name FROM Profile WHERE UserType = 'PowerCustomerSuccess' LIMIT 1];
            User reviewerUser = new User(
                ContactId = reviewerContact.Id,
                Alias = 'reviewer', 
                Email = 'reviewer@example.com',
                FirstName = 'Test', 
                LastName = 'Reviewer',
                UserName = 'reviewer252524@example.com',
                CommunityNickname = 'reviewer',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                Localesidkey = 'en_US', 
                ProfileId = p.Id, 
                TimezoneSidKey = 'America/Los_Angeles',
                IsActive = true
            );
            insert reviewerUser;
        }
    }

    @isTest
    private static void triggerTest() {
        List<Assessment__Share> shares = [
            SELECT AccessLevel, ParentId, UserOrGroupId
            FROM Assessment__Share
            WHERE RowCause = 'Manual'
        ];

        // there shouldn't be any manual shares yet
        System.assert(shares.isEmpty());

        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Account reviewerAccount = [SELECT Id FROM Account WHERE Name = 'Test Reviewer Account' LIMIT 1];

        Test.startTest();

        Assessment__c assess = new Assessment__c(
            Account__c = acc.id,
            Account_Reviewer__c = reviewerAccount.id);
        insert assess;

        Test.stopTest();

        shares = [
            SELECT AccessLevel, ParentId, UserOrGroupId
            FROM Assessment__Share
            WHERE RowCause = 'Manual'
        ];

        // there should be one manual share 
        //System.assert(!shares.isEmpty());
    }
}