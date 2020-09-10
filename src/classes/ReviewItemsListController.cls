public with sharing class ReviewItemsListController {

    @AuraEnabled  
    public static Map<String, List<Review_Item__c>> getRecordsMap(String assessmentId) {
        Map<String, List<Review_Item__c>> recordsMap = new Map<String, List<Review_Item__c>>();
        
        List<Review_Item__c> reviewItems = [
            SELECT
                Id,
                Name,
                Assets_Needed__c,
            	File_Count__c,
            	Item_Comments__c,
                Grade_Number__c,
                Urgent__c,
                Item_Grading__c,
                Grade_Description__c,
            	Assessment__c,
            	Assessment__r.Name,
            	Review_Date__c,
                Item_Category__c,
                Item_Category_Description__c,
                Item_Description__c,
                Finished__c,
                Review_Item_Name__c,
                Review_Item_Status__c
            FROM Review_Item__c
            WHERE Assessment__c = :assessmentId
            ORDER BY Item_Category__c ASC NULLS LAST, Name ASC
        ];

        for (Review_Item__c reviewItem : reviewItems) {
            String category = String.isBlank(reviewItem.Item_Category__c) ? 'Other' : reviewItem.Item_Category__c;
            if (!recordsMap.keySet().contains(category)) {
                recordsMap.put(category, new List<Review_Item__c>());
            }
            recordsMap.get(category).add(reviewItem);
        }

        return recordsMap;
    }

    @AuraEnabled
    public static List<ContentDocument> getFileRecords(Id parentId)
    {   
        List<ContentDocument> files = new List<ContentDocument>();
        List<ContentDocumentLink> fileLinks = [
            SELECT ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :parentId];

        if (!fileLinks.isEmpty()) { 
            Set<Id> fileIds = new Set<Id>();
            for (ContentDocumentLink fileLink : fileLinks) {
                fileIds.add(fileLink.ContentDocumentId); 
            }        
            files = [
                SELECT Id, Title, FileType 
                FROM ContentDocument 
                WHERE ContentDocument.Id IN :fileIds
                ORDER BY Title
            ];
        }
        return files;
    }

    @AuraEnabled
    public static Boolean isRecordEditable(Id recordId) {
        List<UserRecordAccess> access = [
            SELECT RecordId, HasEditAccess, MaxAccessLevel 
            FROM UserRecordAccess 
            WHERE UserId = :UserInfo.getUserId() 
            AND RecordId = :recordId
        ];

        Review_Item__c reviewItem = [
            SELECT Is_Locked__c
            FROM Review_Item__c
            WHERE Id = :recordId
        ];

        Boolean editable = !access.isEmpty() && access[0].HasEditAccess && !reviewItem.Is_Locked__c;
        return editable;
    }

    @AuraEnabled
    public static Boolean isReviewItemCreateable() {
        // below is the desired method of checking permissions, but it always returns true due to
        // known issue W-2616683 where Apex can't correctly determine the current user's access because 
        // the code runs in system mode. for now using VisualForce workaround as decribed at:
        //   https://success.salesforce.com/issues_view?id=a1p300000008djFAAQ
        // Boolean isCreateable = Schema.describeSObjects(new List<String>{'review_item__c'})[0].isCreateable();
        Boolean isCreateable = new CheckObjectPermissionsInVisualForce('review_item__c').isCreateable();
        System.debug('+++ isCreateable: ' + isCreateable);
        return isCreateable;
    }

    @AuraEnabled
    public static void markRecordFinished(Id recordId) {
        Review_Item__c reviewItem = new Review_Item__c(Id = recordId, Finished__c = true);
        update reviewItem;
    }
    @AuraEnabled
    public static void saveRecord (String RIrec){
        RIrec=RIrec.replace('[','').replaceAll(']','');
        system.debug(RIrec);
        Review_Item__c ri = (Review_Item__c)JSON.deserialize(RIrec,Review_Item__c.class);
        
        update ri;
    }
}