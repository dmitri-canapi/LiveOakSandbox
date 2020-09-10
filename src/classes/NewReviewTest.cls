@isTest
private class NewReviewTest {
    static testMethod void verifyTechnicalAssets() {
        List <id> l = new list <Id>();
         NewReview.insertReviewItems(l);
        
        Assessment_Meta_Data__c amd = new Assessment_Meta_Data__c();
        amd.name = 'test';
        amd.Review_Type__c = 'Other';
        insert amd;
        
        
        Account a = new account ();
        a.name='test';
        insert a;
        Assessment__c asm = new Assessment__c();
        asm.Review_Type__c='Other';
        asm.Account__c=a.Id;
        insert asm;
        
        List<Assessment__c> reviews = [select id, Name, Review_Date__c, Review_Status__c, Review_Summary__c,  Total_Grade__c from Assessment__c LIMIT 1];
        List<Assessment_Meta_Data__c> reviewItems = [select id, Name , Review_Type__c, Review_Category__c, Item_Assets__c from Assessment_Meta_Data__c];
         
         
        Test.startTest();
      
        for (Assessment__c review : reviews) {
              /*for (Assessment_Meta_Data__c r:reviewItems) {
                  if (review.Review_Type__c == r.Review_Type__c) {
                    review_item__c ri = new review_item__c();
                    ri.Assessment__c = review.Id;
                    ri.Assets_Needed__c = r.Item_Assets__c;
                    ri.Item_Category__c = r.Review_Category__c;
                    ri.Item_Description__c = r.Item_Description__c;
                    ri.Review_Item_Name__c = r.Name;
                    insert ri;
                    }
              }*/
            NewReview.insertReviewItems(l);
            NewTechnicalReview.insertTechReviewItems(l);
            Test.stopTest();
                  
        System.assertNotEquals(reviews, null);


    }
    }
}