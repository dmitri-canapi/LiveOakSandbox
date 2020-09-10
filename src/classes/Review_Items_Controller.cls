global with sharing class Review_Items_Controller {
    
    @auraenabled
    public Static List <Document__c> getLinkedDocuments(String recordId, String serchCondition){
        serchCondition = '%'+serchCondition+'%';
        List <Document__c> documents = [SELECT 
                                        id, 
                                        Name__c,
                                        (
                                            SELECT 
                                            Tag__r.Name
                                            FROM 
                                            TagDocumentAssociations__r
                                        ),
                                        (
                                            SELECT
                                            id,
                                            Notes__c
                                            FROM
                                            Junctions_Document_ReviewItem__r
                                            WHERE
                                            Review_Item__c=:recordId
                                            
                                        )
                                        FROM Document__c 
                                        WHERE 
                                        Name__c Like :serchCondition
                                        AND
                                        id in 
                                        (
                                            SELECT Document__c
                                            FROM
                                            Junction_Document_ReviewItem__c
                                            WHERE 
                                            Review_Item__c=:recordId
                                        )
                                        /*and OwnerId=:UserInfo.getUserId()*/
                                       ];
        return documents;
    }
    @auraenabled
    public Static void removeJunctionObjectById(String recordId){
        Junction_Document_ReviewItem__c j = new Junction_Document_ReviewItem__c();
        j.id = recordId;
        Delete j;
    }

    @AuraEnabled
    public static config getConfig (){ 
        Id siteId = Network.getNetworkId();//Site.getSiteId(); 
        String commName = '';
        system.debug(siteId);
        if (siteId != null) {
            system.debug([SELECT UrlPathPrefix FROM Network]);
            system.debug([SELECT UrlPathPrefix FROM Network WHERE id =: siteId limit 1].UrlPathPrefix);
            commName = [SELECT UrlPathPrefix FROM Network WHERE id =: siteId limit 1].UrlPathPrefix;
        }
        return new config(siteId != null, commName);
    }

    @RemoteAction
     global static String GetDocNotes (String docid, String reviewItemId){
         try{
        	Junction_Document_ReviewItem__c obj = [ select id,Notes__c from Junction_Document_ReviewItem__c where External_Id__c=:reviewItemId+docid][0];
            return obj.Notes__c;
        } catch(exception e){}
         return '';
     }

    @RemoteAction
    global static void LinkDocToRI(String reviewItemId, String selectedId, String content){
    	Junction_Document_ReviewItem__c obj = new Junction_Document_ReviewItem__c();
        
       try{
        	obj = [ select id from Junction_Document_ReviewItem__c where External_Id__c=:reviewItemId+selectedId][0];
        } catch(exception e){}
        
        obj.Notes__c = content;
        
        if (obj.id!=null){
            update obj;
        } else {
            obj.Document__c = selectedId;
            obj.External_Id__c=reviewItemId+selectedId;
            obj.Review_Item__c = reviewItemId;
            insert obj;
        }
        
    }

    public class config {
        @AuraEnabled
        public Boolean isCommunity {get; set;}
        @AuraEnabled
        public String communityName {get; set;}
        public config(boolean isCommunity, String communityName){
            this.isCommunity = isCommunity;
            this.communityName = communityName;
        }
    }

    /*
    @auraenabled
    public Static List <Tag__c> getTags(String tagSerchCondition){
        tagSerchCondition = '%'+tagSerchCondition+'%';
        List <Tag__c> tags = [SELECT 
                              id,
                              Name,
                              (SELECT id, name FROM Tags__r)
                              FROM
                              Tag__c
            				  WHERE 
							Name like :tagSerchCondition
                              LIMIT 10
        					];
        return tags;
    }
    @auraenabled
    public Static List <Tag__c> getTagsById(List <String> ids, List<String> tagsLoad){
        List <Tag__c> tags = [SELECT 
                              id,
                              Name,
                              (SELECT id, name FROM Tags__r)
                              FROM
                              Tag__c
            				  WHERE 
                                id in :ids 
                              AND id NOT in :tagsLoad
        					];
        return tags;
    }
    
    @auraenabled
    public Static List <Document__c> getDocumentsByTags(List <String> tags, String serchCondition, String recordId){
        serchCondition = '%'+serchCondition+'%';
        List <Document__c> documents = [SELECT 
                              id,
                              Name__c,
                                        (
                                            SELECT 
                                            Tag__r.Name
                                            FROM 
                                            TagDocumentAssociations__r
                                        ),
                                        (
                                            SELECT
                                            Notes__c
                                            FROM
                                            Junctions_Document_ReviewItem__r
                                            Where Review_Item__c = :recordId
                                        )
                              FROM
                              Document__c
            				  WHERE
                                Name__c like :serchCondition
                                        AND
                                id in   (
                                            SELECT Document__c
                                            FROM
                                            TagDocumentAssociation__c
                                            WHERE 
                                            Tag__r.Name in :tags
                                        ) 
                                
        					];
        return documents;
    }
    
    
        @auraenabled
    public Static Void LinkDocumentToReview(String recordId, String jsonObj){
        List<DocumentContainer> documents = (List<DocumentContainer>)JSON.deserialize(jsonObj, List<DocumentContainer>.class);
        List <Junction_Document_ReviewItem__c> junictionObjects = new List<Junction_Document_ReviewItem__c>();
        for(DocumentContainer doc :documents){
            Junction_Document_ReviewItem__c obj = new Junction_Document_ReviewItem__c();
            obj.Review_Item__c = recordId;
            obj.Notes__c = doc.Notes;
            obj.Document__c = doc.DocumentId;
            obj.External_Id__c=recordId+doc.DocumentId;
            junictionObjects.add(obj);
        }
        Schema.SObjectField externalId = Junction_Document_ReviewItem__c.External_Id__c;
        Database.UpsertResult [] saver = Database.upsert(junictionObjects, externalId, false); 
        
    }
    public Class DocumentContainer{
        public String DocumentId{get;set;}
        public String Notes{get;set;}
    }
*/
}