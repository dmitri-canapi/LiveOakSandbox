@IsTest public with sharing class UserContactTagAssociationTriggerTest {
    @IsTest
    private static void test1() {

        CollaborationGroup cg = new CollaborationGroup(Name = 'Alliance Leads', CollaborationType='Public');
        insert cg;

        Id p = [select id from profile where name='Community: Alliance Portal'].id;
       
        Account acc = new Account(name ='test') ;
        insert acc; 
       
        Contact con = new Contact(LastName ='testCon',AccountId = acc.Id);
        insert con;  
                  
        User user = new User(alias = 'test123', email='test123@noemail.com',
                emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                localesidkey='en_US', profileid = p, country='United States',IsActive =true,
                ContactId = con.Id,
                timezonesidkey='America/Los_Angeles', username='tester@noemail.com');
       
        insert user;

        UserContactTag__c tag = new UserContactTag__c(name = 'Finance');
        insert tag;

        

        Document__c doc = new Document__c (Name__c='test',Account__c = acc.Id,Shared_with_Users_from_this_account__c = true, Shared_With_Account__c = acc.id);
        insert doc;

        //TeamManagementController.applyTag(user.Id, tag.Id);

        
        
        UserContactTagAssociation__c tagAssoc = new UserContactTagAssociation__c();
        tagAssoc.UserContactTag__c =  tag.Id;
        
        tagAssoc.User__c = user.Id;
        String cId = [select ContactId from User where id =: user.Id].ContactId;
        tagAssoc.Contact__c = cId;
        delete [select id from UserContactTagAssociation__c where Contact__c =: cId and UserContactTag__c =: tag.Id];
        
        insert tagAssoc;
        


        tag.Name = 'Fin2';
        update tag;

        delete [select id from UserContactTagAssociation__c where User__c =: user.Id];

    }

}