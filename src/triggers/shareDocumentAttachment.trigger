trigger shareDocumentAttachment on Document__c (before update,after insert) {

    Set<string> docids = new set <string>();
    map <id,Document__c> DocsMap = new map <id,Document__c>();
    String accId;
    for(Document__c d:Trigger.new) {
        docids.add(d.Id);
        DocsMap.put(d.Id,d);
        accId = d.Account_Id__c;
    }
    map <Id, String> docAttachmentMap = new map <Id, String>();
    List <ContentDocumentLink> cdlList = new List <ContentDocumentLink> ();
    if(docids.size()>0){
        if (Trigger.isUpdate) {
            cdlList=  [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId in:docids];
            system.debug(cdlList);
            for(ContentDocumentLink l:cdlList) {
                l.Visibility='AllUsers';
            } 
            if (cdlList.size()>0){
                update cdlList;
            }
        }
        if (Trigger.isInsert && Trigger.IsAfter) {
            map <id, List <String>> tagKeywords = new map <id, List <String>>();
            String AccRecordTypeName = accId != null ? [select recordType.Name from account where id=: accId].recordType.Name : null;
            List <Tag__c>  tags = new List <Tag__c>();
            if (AccRecordTypeName == 'Limited Partner' || AccRecordTypeName == 'Bank' || AccRecordTypeName == 'LP (Individuals)'){
                tags = [select id, name, (select id,Tag__c,Tag__r.Name, Keywords__c from Keywords__r where IsKeywordEnabled__c = true)  from Tag__c where Type__c = 'Bank Or LP' order by name asc];
            } else {
                tags = [select id, name, (select id,Tag__c,Tag__r.Name, Keywords__c from Keywords__r where IsKeywordEnabled__c = true) from Tag__c where Account__c =: accId limit 50000];
            }

            for (Tag__c tag: tags){
                tagKeywords.put(tag.id,new list <String>{tag.name});
                for (Keyword__c kw: tag.Keywords__r){
                    system.debug(kw.Keywords__c);
                    if(kw.Keywords__c!=null){
                        String kwords = kw.Keywords__c.replaceAll('</div>','');
                        List <String> kwList = kwords.split('<div>');
                        kwList.add(kw.Tag__r.Name);
                        system.debug(kwList);
                        tagKeywords.put(tag.id,kwList);
                    }
                    
                }
            }
            List <TagDocumentAssociation__c> tdaList = new List <TagDocumentAssociation__c>();
            List <Default_Sharing__c> defSharings = [select id, UserOrGroup__c, Access__c, createdById from Default_Sharing__c where (createdById=:userInfo.getUserId() or CreatedBy__c =:userInfo.getUserId()) and Account__c =: null];
            List <Default_Sharing__c> folderSharings = [select id, UserOrGroup__c, Access__c,Account__c,Board_Meeting__c, Contact__c, Documents_Folder_Template__c,Investment__c, Object_For_Share__c,Opportunity__c from Default_Sharing__c where Account__c =: accId];
            List <Document__Share> docShares = new List <Document__Share>();
            
            
            for (Document__c doc: DocsMap.values()){
                for (ID tagId : tagKeywords.keySet() ){
                    for (String keyword: tagKeywords.get(tagId)){
                        system.debug(keyword);
                        if(doc.Name.toLowerCase().Contains(keyword.toLowerCase())){
                            TagDocumentAssociation__c tda = new TagDocumentAssociation__c(Tag__c=tagId,Document__c=doc.Id);
                            tdaList.add(tda);
                        }
                    }
                }
                /* Creating default shares */
                for (Default_Sharing__c ds: defSharings){
                    Document__Share dShare = new Document__Share();
                    dShare.ParentId = doc.Id;
                    dShare.UserOrGroupId = ds.UserOrGroup__c;
                    dShare.AccessLevel = ds.Access__c;
                    docShares.add(dShare);
                }
                /* Creating default shares */

                /* Creating folder shares */
                for (Default_Sharing__c ds: folderSharings){
                    if(
                        (ds.Board_Meeting__c==null && ds.Contact__c==null && ds.Documents_Folder_Template__c==null && ds.Investment__c==null && ds.Object_For_Share__c==null && ds.Opportunity__c==null) || //shared all account records
                        (doc.Opportunity__c != null && doc.Opportunity__c == ds.Opportunity__c) ||
                        (doc.Opportunity__c != null && ds.Object_For_Share__c == 'Opportunities') ||
                        (doc.Board_Meeting__c != null && doc.Board_Meeting__c == ds.Board_Meeting__c) ||
                        (doc.Board_Meeting__c != null && ds.Object_For_Share__c == 'Board_Meetings__r') ||
                        (doc.Documents_Folder_Template__c != null && doc.Documents_Folder_Template__c == ds.Documents_Folder_Template__c) ||
                        (doc.Documents_Folder_Template__c != null && ds.Object_For_Share__c == 'Documents')
                        
                    ){

                    
                        Document__Share dShare = new Document__Share();
                        dShare.ParentId = doc.Id;
                        dShare.UserOrGroupId = ds.UserOrGroup__c;
                        dShare.AccessLevel = ds.Access__c;
                        docShares.add(dShare);
                    }
                }
                /* Creating folder shares */
                
            }
            if (tdaList.size()>0){
                insert tdaList;
            }
            
		    if (docShares.size()>0){
                insert docShares;
            }        
            
            
            
            
        }

       
    }
}