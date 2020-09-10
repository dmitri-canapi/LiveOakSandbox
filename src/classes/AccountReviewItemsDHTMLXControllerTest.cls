@IsTest
public class AccountReviewItemsDHTMLXControllerTest {
    @IsTest
    private static void test1() {
        Account acc = new Account(Name = 'Canapi');
        insert acc;

        Assessment__c assess = new Assessment__c(Account__c = acc.id,Reviewer__c = userInfo.getUserId(), Second_Reviewer__c = userInfo.getUserId());
        insert assess;

        Assessment_Meta_Data__c amd = new Assessment_Meta_Data__c();
        amd.Review_Type__c = 'test';
        amd.Review_Category__c = 'Bronze';
        amd.Name = 'test';
        insert amd;

        AccountReviewItemsDHTMLXController.setDDtype('Legal Assessment',assess.Id);
        AccountReviewItemsDHTMLXController.getDDtemplates();

        review_item__c ri = new review_item__c(
                Assessment__c = assess.Id, 
                Review_Item_Name__c = 'Bronze 1',
                Item_Category__c = 'Bronze',
                Item_Category_Description__c = 'Bronze items',
                Review_Item_Status__c = 'In File',
                Submitter__c = userInfo.getUserId(),
                Template__c = amd.Id);
            
        insert ri;

        AccountReviewItemsDHTMLXController.GetCatTemplateName('Bronze', assess.Id);
        AccountReviewItemsDHTMLXController.updateCatTemplate('Bronze', 'test', assess.Id);
        AccountReviewItemsDHTMLXController.updateTemplate(ri.Id);
        AccountReviewItemsDHTMLXController.updateAllTemplates(assess.Id);

        
        AccountReviewItemsDHTMLXController.setRIData(ri.id,'test','test','test', 'test', '1','Pending', 'test');
        AccountReviewItemsDHTMLXController.updateReviewItems(new List<review_item__c>{ri});
        List <String> statuses = new List <String>{'Pending'};
        Document__c doc = new Document__c (Name__c='test',Account__c=acc.Id);
        insert doc;

        Review_Items_Controller.LinkDocToRI(ri.Id, doc.Id, 'test');
        AccountReviewItemsDHTMLXController.updatePriorities('newcat,' + ri.Id);

        AccountReviewItemsDHTMLXController.createCategory('someCat', assess.Id);
        AccountReviewItemsDHTMLXController.createReviewItem('name', assess.Id, 'someCat');
        AccountReviewItemsDHTMLXController.GetCategoryData('someCat', assess.Id);
        AccountReviewItemsDHTMLXController.setCatData('someCat', 'test', 'newcatName', assess.Id);


        AccountReviewItemsDHTMLXController.GetReviewItemsList(assess.Id,JSON.serialize(statuses),'');
        AccountReviewItemsDHTMLXController.getRIData(ri.id);
        AccountReviewItemsDHTMLXController.getWrapper(ri.id);
        AccountReviewItemsDHTMLXController.saveRecord(JSON.serialize(ri));
        AccountReviewItemsDHTMLXController.setCompleted(ri.id);

        AccountReviewItemsDHTMLXController.removeJunctionObjectById(String.valueOf(ri.Id) + String.valueOf(doc.Id));
        AccountReviewItemsDHTMLXController.GetAllDDchecklists(acc.Id);
        AccountReviewItemsDHTMLXController.getInitValuesWrapper(acc.Id);
        AccountReviewItemsDHTMLXController.getInitValuesWrapper(assess.Id);
        AccountReviewItemsDHTMLXController.getInitValuesWrapper(null);

        AccountReviewItemsDHTMLXController.removeRIById(ri.Id);
        AccountReviewItemsDHTMLXController.removeCategoryByName('newcatName',assess.Id);
        AccountReviewItemsDHTMLXController.removeDDById(assess.Id);

    }

}