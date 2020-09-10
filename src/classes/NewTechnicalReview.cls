public class NewTechnicalReview {
  @InvocableMethod(label='Insert Technical Assets' description='Inserts the technical assets related to a particualr account.')
    public static void insertTechReviewItems(List<Id> reviewIDs){
        
        /*List<Assessment__c> reviews = [select id, Name, Review_Date__c, Review_Status__c, Review_Summary__c, Review_Type__c, Total_Grade__c from Assessment__c where Assessment__c.Id in : reviewIDs];
        List<review_item_meta__mdt> reviewItems = [select id, 	MasterLabel , DeveloperName, Rvw_type__c, review_Category__c, Category_Description__c, Item_Assets__c, Item_Description__c from review_item_meta__mdt];
        
        
       	for (Assessment__c review : reviews) {
            if (review.Review_Type__c == 'Technical Review (initial)') {
                
                for (review_item_meta__mdt r:reviewItems) {
                	review_item__c ri = new review_item__c();
                    ri.Assessment__c = review.Id;
                    ri.Assets_Needed__c = r.Item_Assets__c;
                    ri.Item_Category__c = r.review_Category__c;
                    ri.Item_Category_Description__c = 	r.Category_Description__c;
                    ri.Item_Description__c = r.Item_Description__c;
                    ri.Review_Item_Name__c = r.MasterLabel;
                    insert ri;
                    }
                
                  
            }
      
		}
 */
    
    
    }
}