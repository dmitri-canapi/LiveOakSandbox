@isTest
public class AssessmentSharingServiceTest {
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

            // disable trigger so we can test service class directly
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
    private static void recalculateSharingForAssessmentsTest() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Account reviewerAccount = [SELECT Id FROM Account WHERE Name = 'Test Reviewer Account' LIMIT 1];
        User reviewerUser = [SELECT Id, AccountId FROM User WHERE UserName = 'reviewer252524@example.com' LIMIT 1];

        // disable trigger so we can test service class directly
        AssessmentSharingService.RecalculateSharingOnAssessmentReviewerChange = false;

        Assessment__c assess = new Assessment__c(
            Account__c = acc.id,
            Account_Reviewer__c = reviewerAccount.id);
        insert assess;

        List<Assessment__c> assessments = [SELECT Id, Account__c, Account_Reviewer__c FROM Assessment__c];

        // there should be one assessment with a reviewer account
        System.assert(!assessments.isEmpty());
        System.assert(assessments[0].Account_Reviewer__c != null);

        List<Assessment__Share> shares = [
            SELECT AccessLevel, ParentId, UserOrGroupId
            FROM Assessment__Share
            WHERE RowCause = 'Manual'
        ];

        // there shouldn't be any manual shares yet
        System.assert(shares.isEmpty());

        Test.startTest();

        AssessmentSharingService.recalculateSharing(new List<Assessment__c>{assess});

        Test.stopTest();

        shares = [
            SELECT AccessLevel, ParentId, UserOrGroupId
            FROM Assessment__Share
            WHERE RowCause = 'Manual'
        ];

        // there should be one manual share
        System.assert(!shares.isEmpty());
        System.assert(shares.size() == 1);
        System.assert(shares[0].UserOrGroupId == reviewerUser.Id);
    }

    @isTest
    private static void recalculateSharingForAssessmentsWithExistingSharesTest() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Account reviewerAccount2 = [SELECT Id FROM Account WHERE Name = 'Test Reviewer Account 2' LIMIT 1];
        User reviewerUser = [SELECT Id FROM User WHERE UserName = 'reviewer252524@example.com' LIMIT 1];
        
        // disable trigger so we can test service class directly
        AssessmentSharingService.RecalculateSharingOnAssessmentReviewerChange = false;

        Assessment__c assess = new Assessment__c(
            Account__c = acc.id,
            Account_Reviewer__c = reviewerAccount2.id);
        insert assess;

        Assessment__Share share = new Assessment__Share(
            AccessLevel = 'Edit', ParentId = assess.Id, UserOrGroupId = reviewerUser.Id
        );
        insert share;

        List<Assessment__c> assessments = [SELECT Id, Account__c, Account_Reviewer__c FROM Assessment__c];

        // there should be one assessment with a reviewer account
        System.assert(!assessments.isEmpty());
        System.assert(assessments[0].Account_Reviewer__c != null);

        List<Assessment__Share> shares = [
            SELECT AccessLevel, ParentId, UserOrGroupId
            FROM Assessment__Share
            WHERE RowCause = 'Manual'
        ];

        // there should be one manual share
        System.assert(!shares.isEmpty());
        System.assert(shares.size() == 1);
        System.assert(shares[0].UserOrGroupId == reviewerUser.Id);

        Test.startTest();

        AssessmentSharingService.recalculateSharing(new List<Assessment__c>{assess});

        Test.stopTest();

        shares = [
            SELECT AccessLevel, ParentId, UserOrGroupId
            FROM Assessment__Share
            WHERE RowCause = 'Manual'
        ];

        // there should be no manual shares because reviewerAccount2 has no users
        System.assert(shares.isEmpty());
    }

    @isTest
    private static void recalculateSharingForUsersTest() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Account reviewerAccount = [SELECT Id FROM Account WHERE Name = 'Test Reviewer Account' LIMIT 1];
        User reviewerUser = [SELECT Id, AccountId FROM User WHERE UserName = 'reviewer252524@example.com' LIMIT 1];

        // disable trigger so we can test service class directly
        AssessmentSharingService.RecalculateSharingOnAssessmentReviewerChange = false;

        Assessment__c assess = new Assessment__c(
            Account__c = acc.id,
            Account_Reviewer__c = reviewerAccount.id);
        insert assess;

        List<Assessment__c> assessments = [SELECT Id, Account__c, Account_Reviewer__c FROM Assessment__c];

        // there should be one assessment with a reviewer account
        System.assert(!assessments.isEmpty());
        System.assert(assessments[0].Account_Reviewer__c != null);

        List<Assessment__Share> shares = [
            SELECT AccessLevel, ParentId, UserOrGroupId
            FROM Assessment__Share
            WHERE RowCause = 'Manual'
        ];

        // there shouldn't be any manual shares yet
        System.assert(shares.isEmpty());

        Test.startTest();

        AssessmentSharingService.recalculateSharing(new List<User>{reviewerUser});

        Test.stopTest();

        shares = [
            SELECT AccessLevel, ParentId, UserOrGroupId
            FROM Assessment__Share
            WHERE RowCause = 'Manual'
        ];

        // there should be one manual share
        System.assert(!shares.isEmpty());
        System.assert(shares.size() == 1);
        System.assert(shares[0].UserOrGroupId == reviewerUser.Id);
    }
}