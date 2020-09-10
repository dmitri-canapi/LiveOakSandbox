@isTest
public class ReviewItemsListControllerTest {

    @isTest
    private static void getRecordsMapTest() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Assessment__c assess = new Assessment__c(Account__c = acc.id);
        insert assess;

        List<review_item__c> reviewItems = new List<review_item__c>{
            new review_item__c(
                Assessment__c = assess.Id, 
                Review_Item_Name__c = 'Bronze 1',
                Item_Category__c = 'Bronze',
                Item_Category_Description__c = 'Bronze items'),
            new review_item__c(
                Assessment__c = assess.Id, 
                Review_Item_Name__c = 'Bronze 2',
                Item_Category__c = 'Bronze',
                Item_Category_Description__c = 'Bronze items'),
            new review_item__c(
                Assessment__c = assess.Id, 
                Review_Item_Name__c = 'Silver 1',
                Item_Category__c = 'Silver',
                Item_Category_Description__c = 'Silver items'),
            new review_item__c(
                Assessment__c = assess.Id, 
                Review_Item_Name__c = 'Gold 1',
                Item_Category__c = 'Gold',
                Item_Category_Description__c = 'Gold items')
        };
        insert reviewItems;

        test.startTest();
        Map<String, List<review_item__c>> reviewItemsMap = ReviewItemsListController.getRecordsMap(assess.Id);
        test.stopTest();

        System.assert(!reviewItemsMap.isEmpty());
        System.assertEquals(2, reviewItemsMap.get('Bronze').size());
    }

    @isTest
    private static void getFileRecordsTest() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Assessment__c assess = new Assessment__c(Account__c = acc.id);
        insert assess;

        review_item__c item = new review_item__c(
            Assessment__c = assess.Id, 
            Review_Item_Name__c = 'Gold 1',
            Item_Category__c = 'Gold',
            Item_Category_Description__c = 'Gold items');
        insert item;

        ContentVersion contentVersion = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;    
        
        List<ContentDocument> documents = [
            SELECT Id, Title, LatestPublishedVersionId 
            FROM ContentDocument
        ];

        ContentDocumentLink cdl = New ContentDocumentLink(
            LinkedEntityId = item.id,
            ContentDocumentId = documents[0].Id,
            shareType = 'V'
        );
        insert cdl;

        test.startTest();
        List<ContentDocument> files = ReviewItemsListController.getFileRecords(item.id);
        test.stopTest();

        System.assert(!files.isEmpty());
    }

    @isTest
    private static void isRecordEditableTest() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Assessment__c assess = new Assessment__c(Account__c = acc.id);
        insert assess;

        review_item__c item = new review_item__c(
            Assessment__c = assess.Id, 
            Review_Item_Name__c = 'Gold 1',
            Item_Category__c = 'Gold',
            Item_Category_Description__c = 'Gold items');
        insert item;

        test.startTest();
        Boolean isEditable = ReviewItemsListController.isRecordEditable(item.Id);
        test.stopTest();
    }

    @isTest
    private static void isReviewItemCreateableTest() {
        test.startTest();
        Boolean isCreateable = ReviewItemsListController.isReviewItemCreateable();
        test.stopTest();
    }
}