@isTest
public class Review_Items_ControllerTest {

    @isTest
    private static void test1() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Assessment__c assess = new Assessment__c(Account__c = acc.id);
        insert assess;

        
        review_item__c ri = new review_item__c(
                Assessment__c = assess.Id, 
                Review_Item_Name__c = 'Bronze 1',
                Item_Category__c = 'Bronze',
                Item_Category_Description__c = 'Bronze items');
            
        insert ri;

        Document__c doc = new Document__c (Name__c='test',Account__c=acc.Id);
        insert doc;

        Review_Items_Controller.getLinkedDocuments(ri.Id, 'test');
        Review_Items_Controller.getConfig();
        Review_Items_Controller.LinkDocToRI(ri.Id, doc.Id, 'test');
        Review_Items_Controller.GetDocNotes(doc.Id, ri.Id);
        Review_Items_Controller.GetDocNotes(doc.Id, ri.Id);
        Review_Items_Controller.removeJunctionObjectById([select id from Junction_Document_ReviewItem__c limit 1].Id);
    }

}