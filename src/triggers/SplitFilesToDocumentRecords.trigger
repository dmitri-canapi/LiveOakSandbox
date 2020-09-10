trigger SplitFilesToDocumentRecords on Document_Helper__c (after update) {
    List <Id> DHids = new List <Id>();
    map <String,Document_Helper__c> docHmap = new map <String,Document_Helper__c>();
    List <Document__c> docs = new List<Document__c>();
    
    for (Document_Helper__c dh : Trigger.new) {
        if (dh.ConvertToDocuments__c) {
            DHids.add(dh.Id);
            docHmap.put(dh.Id,dh);
        }
    }
    if (DHids.size()>0){

        List <ContentDocumentLink> files = [select ContentDocument.title,ContentDocument.FileExtension,ContentDocumentId,LinkedEntityId,ShareType FROM ContentDocumentLink WHERE LinkedEntityId in:DHids];
        List <TagDocumentAssociation__c> TDAlist = [select id,Tag__r.name, Tag__c,Document_Helper__c,Document__c from TagDocumentAssociation__c where Document_Helper__c in:DHids];
        
        Map <string, List <TagDocumentAssociation__c>> DocHeplerTagAssoc = new map<string, List <TagDocumentAssociation__c>>();
        
        for (TagDocumentAssociation__c tassoc: TDAlist){
            if (DocHeplerTagAssoc.get(tassoc.Document_Helper__c) == null){
                List <TagDocumentAssociation__c> tempList = new List <TagDocumentAssociation__c>();
                tempList.add(tassoc);
                DocHeplerTagAssoc.put(tassoc.Document_Helper__c, tempList);
            } else {
                List <TagDocumentAssociation__c> tempList = DocHeplerTagAssoc.get(tassoc.Document_Helper__c);
                tempList.add(tassoc);
                DocHeplerTagAssoc.put(tassoc.Document_Helper__c, tempList);
            }
        }
        system.debug(DocHeplerTagAssoc);
        
        Map <integer, string> docToDocHepler = new map<integer, string>();
        
        integer j=0;
        for (ContentDocumentLink obj: files){
            Document__c doc = new Document__c();
            doc.Sensitivity__c=docHmap.get(obj.LinkedEntityId).Sensitivity__c;
            doc.Name__c=obj.ContentDocument.title + '.' + obj.ContentDocument.FileExtension;
            String trimmedName = obj.ContentDocument.title + '.' + obj.ContentDocument.FileExtension;
            if (trimmedName.length()>80){
                trimmedName = trimmedName.substring(0,80);
            } 
            doc.Name = trimmedName;
                
            doc.Account__c = docHmap.get(obj.LinkedEntityId).Account__c;
            doc.Board_Meeting__c = docHmap.get(obj.LinkedEntityId).Board_Meeting__c;
            doc.Contact__c = docHmap.get(obj.LinkedEntityId).Contact__c;
            doc.Opportunity__c = docHmap.get(obj.LinkedEntityId).Opportunity__c;
            doc.Round__c = docHmap.get(obj.LinkedEntityId).Round__c;
            doc.Investment__c = docHmap.get(obj.LinkedEntityId).Investment__c;
            doc.Documents_Folder_Template__c = docHmap.get(obj.LinkedEntityId).Documents_Folder_Template__c;
            
            docs.add(doc);
            docToDocHepler.put(j, obj.LinkedEntityId);
            j++;
        }
            
        if (docs.size()>0){
            insert docs;
        }
        
        
        List <ContentDocumentLink> insertLinks = new List <ContentDocumentLink>();
        List <ContentDocumentLink> deleteLinks = new List <ContentDocumentLink>();
        List <TagDocumentAssociation__c> insertTagLinks = new List <TagDocumentAssociation__c>();
        //List <TagDocumentAssociation__c> deleteTagLinks = new List <TagDocumentAssociation__c>();
        
        integer i=0;
        for (ContentDocumentLink obj: files){  
            ContentDocumentLink newclnk = obj.clone();
            newclnk.linkedentityid =docs[i].Id;
            newclnk.ShareType=obj.ShareType;
            insertLinks.add(newclnk);
            deleteLinks.add(obj);
            if(DocHeplerTagAssoc.containsKey(docToDocHepler.get(i)))
            for(TagDocumentAssociation__c tag: DocHeplerTagAssoc.get(docToDocHepler.get(i))){
                TagDocumentAssociation__c newTagAssoc = tag.clone();
                newTagAssoc.Document_Helper__c=null;
                newTagAssoc.Document__c=docs[i].Id;
                insertTagLinks.add(newTagAssoc);
            }        
            i++;
        }
        if (files.size()>0){
             insert insertLinks;
             delete deleteLinks;
            if (insertTagLinks.size()>0){
                insert insertTagLinks;
                delete TDAlist;
            }
            
        }
        if (DHids.size()>0){
            delete [select id from Document_Helper__c where id in:DHids];
        }
     
    }
}