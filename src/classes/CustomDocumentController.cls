global with sharing class CustomDocumentController {
    	private static set <String> knowedFileExtensions = new set <String>{'doc','docx','ppt','pptx', 'xls','xlsx', 'html', 'txt', 'pdf', 'jpg', 'gif', 'png', 'tiff'};
    	Transient public String filecontent{get;set;}
        Transient public String filename{get;set;}
        Transient public String filetype{get;set;}
        Transient public String parentId{get;set;} 
        Transient public String accId{get;set;} 
        Transient public String selectedTags{get;set;}
        
    @AuraEnabled @RemoteAction
    global static boolean isCommunity(){
        Id siteId = Site.getSiteId(); 
        if (siteId != null) {
            return true;
        }
        return false;
    }
    
	@AuraEnabled
    global static List<ContentDocument> getFileRecords(Id parentId)
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
    

    global void uploadAttachment(){
        Document__c doc = new Document__c();
        String trimmedName;
        if (filename.length()>80){
            trimmedName = filename.substring(0,80);
        } else {
            trimmedName=filename;
        }
        doc.Name = trimmedName;
        doc.Name__c = filename;

        if (parentId InstanceOf Id){
            if(id.valueOf(parentId).getSObjectType().getDescribe().getName()=='Account'){
                doc.Account__c=parentId;
            } else if (id.valueOf(parentId).getSObjectType().getDescribe().getName()=='Contact'){
                doc.Contact__c=parentId;
            } else if (id.valueOf(parentId).getSObjectType().getDescribe().getName()=='Opportunity'){
                doc.Opportunity__c=parentId;
            } else if (id.valueOf(parentId).getSObjectType().getDescribe().getName()=='Board_Meeting__c'){
                doc.Board_Meeting__c=parentId;
            } else if (id.valueOf(parentId).getSObjectType().getDescribe().getName()=='Round__c'){
                doc.Round__c=parentId;
            } else if (id.valueOf(parentId).getSObjectType().getDescribe().getName()=='Investment__c'){
                doc.Investment__c=parentId;
            } 
            
        }
            else {
            doc.Account__c=accId;
        }
        
        insert doc;
        
        if (selectedTags!=null){
            CustomDocumentController.addTagForDocument (doc.Id, selectedTags);
        }
        
        
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(filecontent);
        cv.Title = filename;
        cv.PathOnClient = filename;
        insert cv;
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [ SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
        cdl.LinkedEntityId = doc.Id;
        cdl.ShareType = 'V';
        insert cdl;
        system.debug(cdl);
    }
    
    @AuraEnabled
    public static String createNewRec(){
        Document_Helper__c doc = new Document_Helper__c();
        insert doc;
        return doc.Id;
    }
    
    @AuraEnabled
    public static void DeleteRec(String recId){
        Document_Helper__c dh = [select id from Document_Helper__c where id=:recId];
        delete dh;
    }
    
    @AuraEnabled
     public static void saveRecordContr(String rec){
         try{
             system.debug(rec);
             rec=rec.replace('[','').replaceAll(']','');
             system.debug(rec);
             Document_Helper__c ms = (Document_Helper__c)JSON.deserialize(rec,Document_Helper__c.class);
             update ms;
         }catch(exception e){
            throw new AuraHandledException('Error: ' + e.getMessage());   
         }
     }
     @AuraEnabled
     public static List <TagDocumentAssociation__c> getTags (String docHid){
         List <TagDocumentAssociation__c> tags = new List <TagDocumentAssociation__c>();
         tags = [select id,Tag__r.name,Tag__r.ParentTag__c,Tag__r.ParentTag__r.ParentTag__c,Tag__r.ParentTag__r.name,Tag__r.ParentTag__r.ParentTag__r.name, Tag__c,Document_Helper__c,Document__c from TagDocumentAssociation__c where Document_Helper__c=:docHid];
         return tags;
     }
    
    @AuraEnabled @RemoteAction
     global static void removeDocHelperTagAssoc (String dhTagAssocid){
         delete  [select id from TagDocumentAssociation__c where id=:dhTagAssocid];
     }
    
    @RemoteAction
     global static List <TagDocumentAssociation__c> getTagsRecords (String docHid){
         List <TagDocumentAssociation__c> tags = new List <TagDocumentAssociation__c>();
         tags= [select id,Tag__r.name,Tag__r.ParentTag__r.name, Tag__c,Document_Helper__c,Document__c from TagDocumentAssociation__c where Document_Helper__c=:docHid];
       
         return tags;
     }

    @RemoteAction
     global static List <Tag__c> getAccountTagsRecords (String AccId, String AccRecordTypeName){
        List <Tag__c> tags = new List <Tag__c>();
        if (AccRecordTypeName =='') {
            AccRecordTypeName = [select recordType.Name from account where id=: AccId].recordType.Name;
        }
        if (AccRecordTypeName == 'Limited Partner' || AccRecordTypeName == 'Bank' || AccRecordTypeName == 'LP (Individuals)'){
            return tags = [select id, name, ParentTag__c  from Tag__c where Type__c = 'Bank Or LP' order by name asc];
        } else {
            tags = [select id, name, ParentTag__c  from Tag__c where Account__c=:AccId order by name asc];
            if (tags.size()==0){
            List<TagsTemplate__mdt> tagsTemplate = [select id,Tag_Name__c,Parent_Tag_Name__c from TagsTemplate__mdt];

            List <Tag__c> Temptags = new List <Tag__c>();
            List <Tag__c> Temptags2 = new List <Tag__c>();
            
            map<String,String> ttMap3 = new map<String,String>();
            map<String,String> ttMap4 = new map<String,String>();

            for (TagsTemplate__mdt tt: tagsTemplate){
                Temptags.add(new Tag__c(name=tt.Tag_Name__c, Account__c=AccId));
                if(tt.Parent_Tag_Name__c!=null && tt.Parent_Tag_Name__c!='')
                ttMap3.put(tt.Tag_Name__c, tt.Parent_Tag_Name__c);
            }
            if(Temptags.size()>0){
            insert Temptags;
            }
            for (Tag__c t:Temptags){
                if(!ttMap3.containsKey(t.Name)){
                ttMap4.put(t.Name, t.id);
                }
            }
            for (Tag__c t:Temptags){
                if(ttMap3.containsKey(t.Name)){
                    t.ParentTag__c  = ttMap4.get(ttMap3.get(t.Name));
                }
            }
            update Temptags;
            tags.addAll(Temptags);
            return tags;
            } 
        }  
        return tags;
     }
	    
    @RemoteAction @AuraEnabled
     global static void setTagsVF (String docHid, List <String> tags){
         delete [select id from TagDocumentAssociation__c where Document_Helper__c=:docHid];
         list <TagDocumentAssociation__c> tdassoc = new list <TagDocumentAssociation__c>();
         for (Tag__c tagDoc: [select id,name  from Tag__c where id in:tags]){
             TagDocumentAssociation__c tda = new TagDocumentAssociation__c(Tag__c=tagDoc.Id,Document_Helper__c=docHid);
             tdassoc.add(tda);
         }
         if (tdassoc.size()>0){
             insert tdassoc;
         }
     }
     @RemoteAction
     global static void setTagParent (String tagId, String parentTagId){
         Tag__c tag = [select id,ParentTag__c from Tag__c where id=:tagId];
         if (parentTagId!='0' && parentTagId!='All'){
         	tag.ParentTag__c = parentTagId;
         } else {
             tag.ParentTag__c = null;
         }
         update tag;
     }
    
    @RemoteAction
     global static void removeTag (String tagId){
         delete [select id from Tag__c where id=:tagId or ParentTag__c =:tagId];
     }
    
    @RemoteAction
     global static String addNewTag (String tagId,String tagName,String AccId, String AccRecordTypeName){
        Tag__c tag = new Tag__c();
        tag.name = tagName;
        tag.Account__c = AccId;
        if(tagId!='All'){
            tag.ParentTag__c = tagId;
        }
        if (AccRecordTypeName =='') {
            AccRecordTypeName = [select recordType.Name from account where id=: AccId].recordType.Name;
        }
        tag.Type__c = (AccRecordTypeName == 'Limited Partner' || AccRecordTypeName == 'Bank' || AccRecordTypeName == 'LP (Individuals)') ? 'Bank Or LP' :null;
        insert tag;
        return tag.Id;
     }
    
    @RemoteAction
     global static void renameTag (String tagId,String tagName){
         Tag__c tag = [select id, name from Tag__c where id=:tagId];
         tag.name = tagName;
         update tag;
     }
    
    @RemoteAction
    global static String GetDocuments(){
        List <Document__c> docList = new List <Document__c>();
        docList = [select id, Name__c, Sensitivity__c,CreatedDate,Owner.Name from Document__c where OwnerId=:UserInfo.getUserId() order by CreatedDate desc ];
        Set <Id> docsIds = new  Set <Id>();
        for (Document__c doc:docList){
            docsIds.add(doc.Id);
        }
        map <Id, String> docAttachmentMap = new map <Id, String>();
        if(docsIds.size()>0){
            for (ContentDocumentLink cdl: [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId in:docsIds]){
                docAttachmentMap.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
            }
        }
        system.debug(docAttachmentMap);
            
        JSONGenerator generator = JSON.createGenerator(true);
        generator.writeStartObject(); 
        generator.writeFieldName('rows');
        generator.writeStartArray(); //Write the starting marker of a JSON object '['
        
        Id siteId = Site.getSiteId(); 
        for (Document__c d: docList){
            generator.writeStartObject(); //Write the starting marker of a JSON object '{'
            generator.writeStringField('id', d.Id);
            List<String> strlist = new List<String>();
            String link='';
           	
            if(d.Name__c.contains('.')){
                list<String> parsedDocName = d.Name__c.split('\\.');
                if(knowedFileExtensions.contains(parsedDocName[parsedDocName.size()-1].toLowerCase())){
                    strlist.add(parsedDocName[parsedDocName.size()-1].toLowerCase() + '.png');
                } else {
                    strlist.add('file.png');
                }
            } else {
                strlist.add('file.png');
            }
            
            if (docAttachmentMap.containsKey(d.Id)){
                boolean isCommunity = false;
                if (siteId != null) { 
                	isCommunity=true;
                }
                if (siteId != null) { 
                    if (d.Sensitivity__c=='Public'){
                    	//link = '/fintech/s/contentdocument/'+ docAttachmentMap.get(d.Id);
                    	link = 'javascript:openModal("' + docAttachmentMap.get(d.Id) + '","public"' + ',' + isCommunity + ')^_self';
                    } else {
                        //link = '/fintech/apex/RestrictedFilePreview?id='+ docAttachmentMap.get(d.Id);
                        link = 'javascript:openModal("' + docAttachmentMap.get(d.Id) + '","restricted"' + ',' + isCommunity + ')^_self';
                    }
                } else {
                    //link = '/'+ docAttachmentMap.get(d.Id);
                    link = 'javascript:openModal("' + docAttachmentMap.get(d.Id) + '","public"' + ',' + isCommunity + ')^_self';
                } 
            }
			 
            strlist.add( d.Name__c + '^' + link );
            
           strlist.add(d.CreatedDate.month() + '/' +d.CreatedDate.day() +'/' + d.CreatedDate.year());
            
            string ownerName = '';
            if(d.Owner!=null)
                if (d.Owner.Name.length()>4){
                    ownerName = d.Owner.Name.substring(0,4) + '...';
                } else {
                    ownerName = d.Owner.Name;
                }
            strlist.add(ownerName);
            strlist.add(d.Sensitivity__c);
            strlist.add(d.Id);
            strlist.add(d.Owner.Name);
            generator.writeObjectField('data', strlist);
            generator.writeEndObject(); //Write the end marker of a JSON object '}'
        }
        generator.writeEndArray(); //Write the end marker of a JSON object ']'
        generator.writeEndObject();
            
        return generator.getAsString();
    }
    
    @RemoteAction
    global static String GetDocumentsHomePage(){
        List <Document__c> docList = new List <Document__c>();
        docList = [select id, Name__c, Sensitivity__c,CreatedDate from Document__c where OwnerId=:UserInfo.getUserId() order by CreatedDate desc limit 5];
        Set <Id> docsIds = new  Set <Id>();
        for (Document__c doc:docList){
            docsIds.add(doc.Id);
        }
        map <Id, String> docAttachmentMap = new map <Id, String>();
        if(docsIds.size()>0){
            for (ContentDocumentLink cdl: [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId in:docsIds]){
                docAttachmentMap.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
            }
        }
        system.debug(docAttachmentMap);
            
        JSONGenerator generator = JSON.createGenerator(true);
        generator.writeStartObject(); 
        generator.writeFieldName('rows');
        generator.writeStartArray(); //Write the starting marker of a JSON object '['
        
        Id siteId = Site.getSiteId(); 
       	for (Document__c d: docList){
            generator.writeStartObject(); //Write the starting marker of a JSON object '{'
            generator.writeStringField('id', d.Id);
            List<String> strlist = new List<String>();
            String link='';
            
            if(d.Name__c.contains('.')){
                list<String> parsedDocName = d.Name__c.split('\\.');
                if(knowedFileExtensions.contains(parsedDocName[parsedDocName.size()-1].toLowerCase())){
                    strlist.add(parsedDocName[parsedDocName.size()-1].toLowerCase() + '.png');
                } else {
                    strlist.add('file.png');
                }
            } else {
                strlist.add('file.png');
            }
           
            if (docAttachmentMap.containsKey(d.Id)){
                if (siteId != null) {  
                    if (d.Sensitivity__c=='Public'){
                    	link = '/fintech/s/contentdocument/'+ docAttachmentMap.get(d.Id);
                    } else {
                        link = '/fintech/apex/RestrictedFilePreview?id='+ docAttachmentMap.get(d.Id);
                        //link = 'javascript:openModal("' + docAttachmentMap.get(d.Id) + '")^_self';
                    }
                } else {
                    link = '/'+ docAttachmentMap.get(d.Id);
                    
                }   
            }
			 
            strlist.add( d.Name__c + '^' + link );
            strlist.add(d.CreatedDate.month() + '/' +d.CreatedDate.day() +'/' + d.CreatedDate.year());
            
            strlist.add(d.Sensitivity__c);
            strlist.add(d.Id);
            generator.writeObjectField('data', strlist);
            generator.writeEndObject(); //Write the end marker of a JSON object '}'
        }
        generator.writeEndArray(); //Write the end marker of a JSON object ']'
        generator.writeEndObject();
            
        return generator.getAsString();
    }
    
    @RemoteAction
    global static String GetDocumentsAccPage(String accId){//deprecated
        accId = accId.substring(0, 15);
        List <Document__c> docList = new List <Document__c>();
        set <id> users = new set <id>();
        for (User u: [select id from user where Account_Id__c=:accId]){
            users.add(u.id);
        }
        docList = [select id, Name__c, Sensitivity__c,CreatedDate,Owner.Name,Account__c from Document__c where OwnerId in:users or Account__c=:accId order by CreatedDate desc];
        Set <Id> docsIds = new  Set <Id>();
        for (Document__c doc:docList){
            docsIds.add(doc.Id);
        }
        map <Id, String> docAttachmentMap = new map <Id, String>();
        if(docsIds.size()>0){
            for (ContentDocumentLink cdl: [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId in:docsIds]){
                docAttachmentMap.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
            }
        }
        system.debug(docAttachmentMap);
            
        JSONGenerator generator = JSON.createGenerator(true);
        generator.writeStartObject(); 
        generator.writeFieldName('rows');
        generator.writeStartArray(); //Write the starting marker of a JSON object '['
        
        Id siteId = Site.getSiteId(); 
        boolean isCommunity = false;
        if (siteId != null) { 
            isCommunity=true;
        }
        for (Document__c d: docList){
            generator.writeStartObject(); //Write the starting marker of a JSON object '{'
            generator.writeStringField('id', d.Id);
            List<String> strlist = new List<String>();
            String link='';
            
            if(d.Name__c.contains('.')){
                list<String> parsedDocName = d.Name__c.split('\\.');
                if(knowedFileExtensions.contains(parsedDocName[parsedDocName.size()-1].toLowerCase())){
                    strlist.add(parsedDocName[parsedDocName.size()-1].toLowerCase() + '.png');
                } else {
                    strlist.add('file.png');
                }
            } else {
                strlist.add('file.png');
            }
           
            if (docAttachmentMap.containsKey(d.Id)){
                 link = 'javascript:openModal("' + docAttachmentMap.get(d.Id) + '","public"' + ',' + isCommunity + ')^_self';
                /*if (siteId != null) {  
                    if (d.Sensitivity__c=='Public'){
                    	link = '/fintech/s/contentdocument/'+ docAttachmentMap.get(d.Id);
                    } else {
                        link = '/fintech/apex/RestrictedFilePreview?id='+ docAttachmentMap.get(d.Id);
                        //link = 'javascript:openModal("' + docAttachmentMap.get(d.Id) + '")^_self';
                    }
                } else {
                    link = '/'+ docAttachmentMap.get(d.Id);
                    
                } */  
            }
			 
            strlist.add( d.Name__c + '^' + link );
            if(d.Account__c==null){
            	strlist.add('true');
            } else {
                strlist.add('false');
            }
            strlist.add(d.CreatedDate.month() + '/' +d.CreatedDate.day() +'/' + d.CreatedDate.year());
            string ownerName = '';
            if(d.Owner!=null)
                if (d.Owner.Name.length()>4){
                    ownerName = d.Owner.Name.substring(0,4) + '...';
                } else {
                    ownerName = d.Owner.Name;
                }
            strlist.add(ownerName);
            strlist.add(d.Sensitivity__c);
            strlist.add(d.Id);
            strlist.add(d.Owner.Name);
            generator.writeObjectField('data', strlist);
            generator.writeEndObject(); //Write the end marker of a JSON object '}'
        }
        generator.writeEndArray(); //Write the end marker of a JSON object ']'
        generator.writeEndObject();
            
        return generator.getAsString();
    }   
        
    @RemoteAction
    global static String GetDocumentsFiltered(String tagId, String searchCondition){//deprecated

       List <Document__c> docList = new List <Document__c>();
        
       string query = 'select id, Name__c, Sensitivity__c,CreatedDate,Owner.Name from Document__c where OwnerId = \'' +  UserInfo.getUserId() + '\'';
       if (searchCondition!=null && searchCondition!=''){
           
            searchCondition = '%'+searchCondition+'%';
            query+=' AND Name__c like  \'' + searchCondition + '\'';
       } 

        if (tagId!=null && tagId!='' && tagId!='All'){
            query+=' AND id in (SELECT Document__c FROM TagDocumentAssociation__c WHERE Tag__r.Id = \'' + tagId +'\' or Tag__r.ParentTag__r.id = \'' + tagId +'\' or  Tag__r.ParentTag__r.ParentTag__r.id = \'' + tagId +'\')';
        }
        query+=' order by CreatedDate desc';

        docList =  Database.query(query);
        
        Set <Id> docsIds = new  Set <Id>();
        for (Document__c doc:docList){
            docsIds.add(doc.Id);
        }
        map <Id, String> docAttachmentMap = new map <Id, String>();
        
        if (docsIds.size()>0){
            for (ContentDocumentLink cdl: [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId in:docsIds]){
                docAttachmentMap.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
            }
                
            JSONGenerator generator = JSON.createGenerator(true);
            generator.writeStartObject(); 
            generator.writeFieldName('rows');
            generator.writeStartArray(); //Write the starting marker of a JSON object '['
            
            Id siteId = Site.getSiteId(); 
           boolean isCommunity = false;
            if (siteId != null) { 
                isCommunity=true;
            }
            for (Document__c d: docList){
                generator.writeStartObject(); //Write the starting marker of a JSON object '{'
                generator.writeStringField('id', d.Id);
                List<String> strlist = new List<String>();
                String link='';
                
                if(d.Name__c.contains('.')){
                    list<String> parsedDocName = d.Name__c.split('\\.');
                    if(knowedFileExtensions.contains(parsedDocName[parsedDocName.size()-1].toLowerCase())){
                        strlist.add(parsedDocName[parsedDocName.size()-1].toLowerCase() + '.png');
                    } else {
                        strlist.add('file.png');
                    }
                } else {
                    strlist.add('file.png');
                }
               
                if (docAttachmentMap.containsKey(d.Id)){
                    if (siteId != null) { 
                        if (d.Sensitivity__c=='Public'){
                            //link = '/fintech/s/contentdocument/'+ docAttachmentMap.get(d.Id);
                            link = 'javascript:openModal("' + docAttachmentMap.get(d.Id) + '","public"' + ',' + isCommunity + ')^_self';
                        } else {
                            //link = '/fintech/apex/RestrictedFilePreview?id='+ docAttachmentMap.get(d.Id);
                            link = 'javascript:openModal("' + docAttachmentMap.get(d.Id) + '","restricted"' + ',' + isCommunity + ')^_self';
                        }
                    } else {
                        //link = '/'+ docAttachmentMap.get(d.Id);
                        link = 'javascript:openModal("' + docAttachmentMap.get(d.Id) + '","public"' + ',' + isCommunity + ')^_self';
                    } 

                }
                 
                strlist.add( d.Name__c + '^' + link );
                strlist.add(d.CreatedDate.month() + '/' +d.CreatedDate.day() +'/' + d.CreatedDate.year());
                string ownerName = '';
                if(d.Owner!=null)
                    if (d.Owner.Name.length()>4){
                        ownerName = d.Owner.Name.substring(0,4) + '...';
                    } else {
                        ownerName = d.Owner.Name;
                    }
                strlist.add(ownerName);
                strlist.add(d.Sensitivity__c);
                strlist.add(d.Id);
                strlist.add(d.Owner.Name);
                generator.writeObjectField('data', strlist);
                generator.writeEndObject(); //Write the end marker of a JSON object '}'
            }
            generator.writeEndArray(); //Write the end marker of a JSON object ']'
            generator.writeEndObject();
                
            return generator.getAsString();
        }
        return '';
    }
    
    @RemoteAction
    global static String GetDocumentsRI(){
        List <Document__c> docList = new List <Document__c>();
        if (Site.getSiteId()!=null){
            String accId = CustomDocumentController.getCommunityAccId();

            docList = [select id, Name__c, Sensitivity__c,CreatedDate,Owner.Name from Document__c where (Account__c=:accId OR Opportunity__r.AccountId=:accId OR Contact__r.AccountId=:accId OR Board_Meeting__r.Account__c=:accId) order by CreatedDate desc ];
        } else {
            docList = [select id, Name__c, Sensitivity__c,CreatedDate,Owner.Name from Document__c where OwnerId=:UserInfo.getUserId() order by CreatedDate desc ];
        }
        Set <Id> docsIds = new  Set <Id>();
        for (Document__c doc:docList){
            docsIds.add(doc.Id);
        }
        map <Id, String> docAttachmentMap = new map <Id, String>();
        if(docsIds.size()>0){
            for (ContentDocumentLink cdl: [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId in:docsIds]){
                docAttachmentMap.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
            }
        }
        system.debug(docAttachmentMap);
            
        JSONGenerator generator = JSON.createGenerator(true);
        generator.writeStartObject(); 
        generator.writeFieldName('rows');
        generator.writeStartArray(); //Write the starting marker of a JSON object '['
        
        Id siteId = Site.getSiteId(); 
       	for (Document__c d: docList){
            generator.writeStartObject(); //Write the starting marker of a JSON object '{'
            generator.writeStringField('id', d.Id);
            List<String> strlist = new List<String>();
            String link='';
            
            if(d.Name__c.contains('.')){
                list<String> parsedDocName = d.Name__c.split('\\.');
                if(knowedFileExtensions.contains(parsedDocName[parsedDocName.size()-1].toLowerCase())){
                    strlist.add(parsedDocName[parsedDocName.size()-1].toLowerCase() + '.png');
                } else {
                    strlist.add('file.png');
                }
            } else {
                strlist.add('file.png');
            }
           
            if (docAttachmentMap.containsKey(d.Id)){
                boolean isCommunity = false;
                if (siteId != null) { 
                	isCommunity=true;
                }
                //if (siteId != null) { 
                    if (d.Sensitivity__c=='Public'){
                    	//link = '/fintech/s/contentdocument/'+ docAttachmentMap.get(d.Id);
                    	link = 'javascript:openModal("' + docAttachmentMap.get(d.Id) + '","public"' + ',' + isCommunity + ')^_self';
                    } else {
                        //link = '/fintech/apex/RestrictedFilePreview?id='+ docAttachmentMap.get(d.Id);
                        link = 'javascript:openModal("' + docAttachmentMap.get(d.Id) + '","restricted"' + ',' + isCommunity + ')^_self';
                    }
                /*} else {
                    link = '/'+ docAttachmentMap.get(d.Id);
                } */
            }
			 
            strlist.add( d.Name__c + '^' + link );
            strlist.add(d.Id);
            generator.writeObjectField('data', strlist);
            generator.writeEndObject(); //Write the end marker of a JSON object '}'
        }
        generator.writeEndArray(); //Write the end marker of a JSON object ']'
        generator.writeEndObject();
            
        return generator.getAsString();
    }
    
    @RemoteAction
    global static String GetDocumentsFilteredRI(String tagId, String searchCondition){
       List <Document__c> docList = new List <Document__c>();
        string query;
        if (Site.getSiteId()!=null){
            String accId = CustomDocumentController.getCommunityAccId();
            query = 'select id, Name__c, Sensitivity__c,CreatedDate,Owner.Name from Document__c where (Account__c=:accId OR Opportunity__r.AccountId=:accId OR Contact__r.AccountId=:accId OR Board_Meeting__r.Account__c=:accId)';
        } else {
            query = 'select id, Name__c, Sensitivity__c,CreatedDate,Owner.Name from Document__c where OwnerId = \'' +  UserInfo.getUserId() + '\'';
        }
       
       
       if (searchCondition!=null && searchCondition!=''){
           string searchConditionFiltered = '*' +  String.escapeSingleQuotes(searchCondition) + '*';
           List<List<sObject>> searchList = [FIND :searchConditionFiltered in ALL Fields returning ContentVersion(ContentDocumentId,FileExtension,OwnerId)];
			ContentVersion[] searchContentVersion = (ContentVersion[])searchList[0];
           system.debug(searchContentVersion);
           if(searchContentVersion.size()>0){
               Set <String> cvIds = new Set <String>();
               for (ContentVersion cv: searchContentVersion){
                   cvIds.add(cv.ContentDocumentId);
               }
               Set <String> filteredDocsIds = new Set <String>();
               for(ContentDocumentLink cdl: [select LinkedEntityId  From ContentDocumentLink where ContentDocumentId in: cvIds]){
                   filteredDocsIds.add(cdl.LinkedEntityId);
               }
               if (filteredDocsIds.size()>0){
                   query+=' AND id in: filteredDocsIds';
               } else {
                   return '';
               }
               	
           } else {
               return '';
           }
       } 

        if (tagId!=null && tagId!='' && tagId!='All'){
            query+=' AND id in (SELECT Document__c FROM TagDocumentAssociation__c WHERE Tag__r.Id = \'' + tagId +'\' or Tag__r.ParentTag__r.id = \'' + tagId +'\' or  Tag__r.ParentTag__r.ParentTag__r.id = \'' + tagId +'\')';
        }
        query+=' order by CreatedDate desc';

        docList =  Database.query(query);
        
        Set <Id> docsIds = new  Set <Id>();
        for (Document__c doc:docList){
            docsIds.add(doc.Id);
        }
        map <Id, String> docAttachmentMap = new map <Id, String>();
        if (docsIds.size()>0){
            for (ContentDocumentLink cdl: [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId in:docsIds]){
                docAttachmentMap.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
            }
                
            JSONGenerator generator = JSON.createGenerator(true);
            generator.writeStartObject(); 
            generator.writeFieldName('rows');
            generator.writeStartArray(); //Write the starting marker of a JSON object '['
            
            Id siteId = Site.getSiteId(); 
           	for (Document__c d: docList){
                generator.writeStartObject(); //Write the starting marker of a JSON object '{'
                generator.writeStringField('id', d.Id);
                List<String> strlist = new List<String>();
                String link='';
                
                if(d.Name__c.contains('.')){
                    list<String> parsedDocName = d.Name__c.split('\\.');
                    if(knowedFileExtensions.contains(parsedDocName[parsedDocName.size()-1].toLowerCase())){
                        strlist.add(parsedDocName[parsedDocName.size()-1].toLowerCase() + '.png');
                    } else {
                        strlist.add('file.png');
                    }
                } else {
                    strlist.add('file.png');
                }
               
                if (docAttachmentMap.containsKey(d.Id)){
                    //if (siteId != null) {  
                        if (d.Sensitivity__c=='Public'){
                    		//link = '/fintech/s/contentdocument/'+ docAttachmentMap.get(d.Id);
                    		link = 'javascript:openModal("' + docAttachmentMap.get(d.Id) + '","public"' + ',' + true + ')^_self';
                        } else {
                            //link = '/fintech/apex/RestrictedFilePreview?id='+ docAttachmentMap.get(d.Id);
                            //link = 'javascript:openModal("' + docAttachmentMap.get(d.Id) + '")';
                            link = 'javascript:openModal("' + docAttachmentMap.get(d.Id) + '","restricted"' + ',' + true + ')^_self';
                        }
                    /*} else {
                        link = '/'+ docAttachmentMap.get(d.Id);
                    } */  
                }
                 
                strlist.add( d.Name__c + '^' + link );
                strlist.add(d.Id);
                generator.writeObjectField('data', strlist);
                generator.writeEndObject(); //Write the end marker of a JSON object '}'
            }
            generator.writeEndArray(); //Write the end marker of a JSON object ']'
            generator.writeEndObject();
            return generator.getAsString();
        }
        return '';
    }
    
    @RemoteAction
    global static Integer GetAccountDocumentsFilteredCount(String tagId, String searchCondition, String accId, String AccRecordTypeName, String DocumentParentObjectId){
        String FullaccId = accId;
        accId = accId.substring(0, 15);

        string query = 'select id, Name__c from Document__c where id!=null';
            
       if (searchCondition!=null && searchCondition!=''){
           string searchConditionFiltered = '*' +  String.escapeSingleQuotes(searchCondition) + '*';
           List<List<sObject>> searchList = [FIND :searchConditionFiltered in ALL Fields returning ContentVersion(Title,ContentDocumentId,FileExtension,OwnerId)];
			ContentVersion[] searchContentVersion = (ContentVersion[])searchList[0];
           system.debug(searchContentVersion);
           
           if (searchContentVersion.size()==0 && Test.isRunningTest()){
               searchContentVersion = [select ContentDocumentId from ContentVersion];
           }
           if(searchContentVersion.size()>0){
               Set <String> cvIds = new Set <String>();
               for (ContentVersion cv: searchContentVersion){
                   cvIds.add(cv.ContentDocumentId);
               }
               Set <String> filteredDocsIds = new Set <String>();
               for(ContentDocumentLink cdl: [select LinkedEntityId  From ContentDocumentLink where ContentDocumentId in: cvIds]){
                   filteredDocsIds.add(cdl.LinkedEntityId);
               }
               if (filteredDocsIds.size()>0){
                   query+=' AND id in: filteredDocsIds';
               } else {
                   return 0;
               }
               	
           } else {
               return 0;
           }
           	
       } 

        if (tagId!=null && tagId!='' && tagId!='All'){
            string tagName = [select name from Tag__c where id=:tagId limit 1].name;
            query+=' AND id in (SELECT Document__c FROM TagDocumentAssociation__c WHERE Tag__r.name = \'' + tagName +'\' or Tag__r.ParentTag__r.name = \'' + tagName +'\' or  Tag__r.ParentTag__r.ParentTag__r.name = \'' + tagName +'\')';
        }

        if ((AccRecordTypeName == 'Limited Partner' || AccRecordTypeName == 'Bank' || AccRecordTypeName == 'LP (Individuals)') && Site.getSiteId()!=null) {
                query+=' AND Unverified__c = false'; 
        }
        if (DocumentParentObjectId==FullaccId){
            if (AccRecordTypeName == 'Limited Partner' || AccRecordTypeName == 'Bank' || AccRecordTypeName == 'LP (Individuals)') {
                query+=' AND (Documents_Folder_Template__c != null and Account__c=:accId)'; 
            } else {
                query+=' AND (Account__c=:accId OR Opportunity__r.AccountId=:accId OR Contact__r.AccountId=:accId OR Board_Meeting__r.Account__c=:accId OR Round__r.Target_Company__c=:accId OR Investment__r.Investor__c=:accId or Investment__r.Round__r.Target_Company__c=:accId)'; 
            }
        } else if(DocumentParentObjectId=='Opportunities'){
            query+=' AND Opportunity__r.AccountId=:accId'; 
        } else if(DocumentParentObjectId=='Contacts'){
            query+=' AND Contact__r.AccountId=:accId'; 
        } else if(DocumentParentObjectId=='Board_Meetings__r'){
            query+=' AND Board_Meeting__r.Account__c=:accId'; 
        } else if(DocumentParentObjectId=='Investment__r'){// round Relationship name
            query+=' AND Round__r.Target_Company__c=:accId'; 
        } else if(DocumentParentObjectId=='Investments__r'){// investment Relationship name
            query+=' AND (Investment__r.Investor__c=:accId or Investment__r.Round__r.Target_Company__c=:accId)'; 
        } else if(DocumentParentObjectId=='Documents'){
            query+= ' AND (Documents_Folder_Template__c != null and Account__c=:accId)';
        } else {
            string objName = Id.valueOf(DocumentParentObjectId).getSObjectType().getDescribe().getName(); 
            system.debug(objName);
            if(!objName.contains('__c')){
                objName = objName + '__c';
            }
            if (objName == 'Documents_Folder_Template__c'){
                query+=' AND ((Documents_Folder_Template__c =: DocumentParentObjectId OR Documents_Folder_Template__r.Parent_Folder__c =: DocumentParentObjectId) and (Account__c=:accId))';
            } else {
                query+=' AND ' + objName + '=:DocumentParentObjectId';
            }
        }
        
        Set <String> uniqueDocs = new Set <String>();
        for (Document__c doc: Database.query(query)){
            uniqueDocs.add(doc.Name__c);
        }
        return uniqueDocs.size();
    }

    @RemoteAction
    global static void shareForFavGroups(String userOrGroupId,String docIds){
        CustomDocumentControllerWoutSharing.shareForFavGroups(userOrGroupId, docIds);
    }

    @RemoteAction
    global static void setAccountShareOnly(String docIds, boolean state, String AccId, String AccessLevel){
        CustomDocumentControllerWoutSharing.setAccountShareOnly(docIds, state, AccId, AccessLevel);
    }
    
    @RemoteAction
    global static void addPermission (String userOrGroupId,String currentDocId,String accessType){
        CustomDocumentControllerWoutSharing.addPermission(userOrGroupId,currentDocId,accessType);
    }
    
    @RemoteAction
    global static void addDefaultPermission (String userOrGroupId,String accessType){
        CustomDocumentControllerWoutSharing.addDefaultPermission(userOrGroupId,accessType);
    }
    
    @RemoteAction
    global static void addBulkPermission (String userOrGroupId,String accId, String objId, String accessType){
        CustomDocumentControllerWoutSharing.addBulkPermission(userOrGroupId, accId, objId, accessType);
    }
    
    @RemoteAction
    global static String getCurrentPermissionsForTheDocument (String currentDocId){
        return CustomDocumentControllerWoutSharing.getCurrentPermissionsForTheDocument (currentDocId);
    }
    
    @RemoteAction
    global static String getCurrentPermissionsForObject (String accId, String ObjectsTreeId){
        return CustomDocumentControllerWoutSharing.getCurrentPermissionsForObject (accId, ObjectsTreeId);
    }
    
    @RemoteAction
    global static String getCurrentDefaultSharings (){
       return CustomDocumentControllerWoutSharing.getCurrentDefaultSharings();
    }
   
    @RemoteAction
    global static CustomDocumentController.UsersSelectData getUsers(String profileName){
        return CustomDocumentControllerWoutSharing.getUsers(profileName);
    }

    @RemoteAction
    global static String getFavoriteGroups(){
        return CustomDocumentControllerWoutSharing.getFavoriteGroups();
    }

        
    @RemoteAction
    global static void removeAccess (String userOrGroupId, String currentDocId){
        CustomDocumentControllerWoutSharing.removeAccess (userOrGroupId, currentDocId);
    }
    
    @RemoteAction
    global static void removeBulkAccess (String dsId){
        CustomDocumentControllerWoutSharing.removeBulkAccess (dsId);
    }

    @RemoteAction
    global static void removeDefaultSharing (String dsId){
        CustomDocumentControllerWoutSharing.removeDefaultSharing (dsId);
    }
        
    @RemoteAction
    global static String GetDocVersionsData (String accId, String DocId, String docName){
        if (docName==null || docName==''){
            docName = [select name__c from Document__c where id=:DocId].name__c;
        } 
        String FullaccId = accId;
        accId = accId.substring(0, 15);

        List <Document__c> docList = new List <Document__c>();
        
        string query = 'select id, Name__c, CreatedDate,Owner.Name from Document__c where Name__c=:docName';
       
        query+=' AND (Account__c=:accId OR Opportunity__r.AccountId=:accId OR Contact__r.AccountId=:accId OR Board_Meeting__r.Account__c=:accId OR Round__r.Target_Company__c=:accId OR Investment__r.Investor__c=:accId or Investment__r.Round__r.Target_Company__c=:accId)'; 
        
        query+=' order by CreatedDate desc';
		system.debug(query);
        docList =  Database.query(query);
        
        Set <Id> docsIds = new  Set <Id>();
        
        for (Document__c d: docList){
            docsIds.add(d.Id);
        }
        
        map <Id, String> docAttachmentMap = new map <Id, String>();
        if (docsIds.size()>0){
            for (ContentDocumentLink cdl: [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId in:docsIds]){
                docAttachmentMap.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
            }
                
            JSONGenerator generator = JSON.createGenerator(true);
            generator.writeStartObject(); 
            generator.writeFieldName('rows');
            generator.writeStartArray(); //Write the starting marker of a JSON object '['
            
            Id siteId = Site.getSiteId(); 
           	boolean isCommunity = false;
            if (siteId != null) { 
                isCommunity=true;
            }
            integer i = docList.size();
            for (Document__c d: docList){
                if (docAttachmentMap.containsKey(d.Id)){
                    generator.writeStartObject(); //Write the starting marker of a JSON object '{'
                    generator.writeStringField('id', d.Id);
                    List<String> strlist = new List<String>();
                    String link='';
                    
                    link = 'javascript:openModal("' + docAttachmentMap.get(d.Id) + '","public"' + ',' + isCommunity + ')^_self';
                   
                    strlist.add( d.Name__c  + '^' + link );

                   	strlist.add(String.valueOf(i));
                    
                    strlist.add(d.CreatedDate.month() + '/' +d.CreatedDate.day() +'/' + d.CreatedDate.year());
                    string ownerName = '';
                    if (d.Owner!=null){
                        ownerName = d.Owner.Name;  
                    }    
                    strlist.add(ownerName);

                    generator.writeObjectField('data', strlist);
                    generator.writeEndObject(); //Write the end marker of a JSON object '}'
                    i--;
                }
            }
            generator.writeEndArray(); //Write the end marker of a JSON object ']'
            generator.writeEndObject();
                
            return generator.getAsString();
        }
        return '';
        
    }
    
    @RemoteAction
    global static String GetAccountDocumentsFiltered(String tagId, String searchCondition, String accId, String AccRecordTypeName, String DocumentParentObjectId){
        system.debug(accId);
        system.debug(DocumentParentObjectId);
        
        String FullaccId = accId;
        accId = accId.substring(0, 15);

        List <Document__c> docList = new List <Document__c>();
        
        string query = 'select id, Name__c,UserRecordAccess.HasEditAccess, Unverified__c, Sensitivity__c, CreatedDate, Owner.Name, OwnerId, Notes__c, Release_date__c, Shared_with_Users_from_this_account__c from Document__c where id!=null';
            
       if (searchCondition!=null && searchCondition!=''){
           string searchConditionFiltered = '*' +  String.escapeSingleQuotes(searchCondition) + '*';
           List<List<sObject>> searchList = [FIND :searchConditionFiltered in ALL Fields returning ContentVersion(ContentDocumentId,FileExtension,OwnerId)];
			ContentVersion[] searchContentVersion = (ContentVersion[])searchList[0];
            
           if(searchContentVersion.size()>0){
               Set <String> cvIds = new Set <String>();
               for (ContentVersion cv: searchContentVersion){
                   cvIds.add(cv.ContentDocumentId);
               }
               Set <String> filteredDocsIds = new Set <String>();
               for(ContentDocumentLink cdl: [select LinkedEntityId  From ContentDocumentLink where ContentDocumentId in: cvIds]){
                   filteredDocsIds.add(cdl.LinkedEntityId);
               }
               if (filteredDocsIds.size()>0){
                   query+=' AND id in: filteredDocsIds';
               } else {
                   return '';
               }
               	
           } else {
               return '';
           }
       } 
        
        if (Site.getSiteId()!=null){
            DateTime utcTime = datetime.now();
            User u = [SELECT ID, TimeZoneSidKey FROM User WHERE ID = :UserInfo.getUserId() LIMIT 1];
            Integer offset =  TimeZone.getTimeZone(u.TimeZoneSidKey).getOffset(utcTime);
            Datetime local = utcTime.addSeconds(offset/1000);
            
            String usId = userInfo.getUserId();
            query+=' AND (Release_date__c <=:local or Release_date__c = null or OwnerId =: usId)' ;
        }

        if (tagId!=null && tagId!='' && tagId!='All'){
            string tagName = [select name from Tag__c where id=:tagId limit 1].name;
            query+=' AND id in (SELECT Document__c FROM TagDocumentAssociation__c WHERE Tag__r.name = \'' + tagName +'\' or Tag__r.ParentTag__r.name = \'' + tagName +'\' or  Tag__r.ParentTag__r.ParentTag__r.name = \'' + tagName +'\')';
        }

        if ((AccRecordTypeName == 'Limited Partner' || AccRecordTypeName == 'Bank' || AccRecordTypeName == 'LP (Individuals)') && Site.getSiteId()!=null) {
                query+=' AND Unverified__c = false'; 
        }

        if (DocumentParentObjectId==FullaccId){
            if (AccRecordTypeName == 'Limited Partner' || AccRecordTypeName == 'Bank' || AccRecordTypeName == 'LP (Individuals)') {
                query+=' AND (Documents_Folder_Template__c != null and Account__c=:accId)'; 
            } else {
                query+=' AND (Account__c=:accId OR Opportunity__r.AccountId=:accId OR Contact__r.AccountId=:accId OR Board_Meeting__r.Account__c=:accId OR Round__r.Target_Company__c=:accId OR Investment__r.Investor__c=:accId or Investment__r.Round__r.Target_Company__c=:accId)'; 
            }
        } else if(DocumentParentObjectId=='Opportunities'){
            query+=' AND Opportunity__r.AccountId=:accId'; 
        } else if(DocumentParentObjectId=='Contacts'){
            query+=' AND Contact__r.AccountId=:accId'; 
        } else if(DocumentParentObjectId=='Board_Meetings__r'){
            query+=' AND Board_Meeting__r.Account__c=:accId'; 
         } else if(DocumentParentObjectId=='Investment__r'){// round Relationship name
            query+=' AND Round__r.Target_Company__c=:accId'; 
        } else if(DocumentParentObjectId=='Investments__r'){// investment Relationship name
            query+=' AND (Investment__r.Investor__c=:accId or Investment__r.Round__r.Target_Company__c=:accId)';  
        } else if(DocumentParentObjectId=='Documents'){
            query+= ' AND (Documents_Folder_Template__c != null AND Account__c=:accId)';
        } else {
            string objName = Id.valueOf(DocumentParentObjectId).getSObjectType().getDescribe().getName(); 
            system.debug(objName);
            if(!objName.contains('__c')){
                objName = objName + '__c';
            }
            if (objName == 'Documents_Folder_Template__c'){
                query+=' AND ((Documents_Folder_Template__c =: DocumentParentObjectId OR Documents_Folder_Template__r.Parent_Folder__c =: DocumentParentObjectId) and (Account__c=:accId))';
            } else {
                query+=' AND ' + objName + '=:DocumentParentObjectId';
            }
        }
        
        query+=' order by CreatedDate desc';
		system.debug(query);
        docList =  Database.query(query);
        
        Set <Id> docsIds = new  Set <Id>();
        
        Map<String,List<String>> docsVersionMap = new Map<String,List<String>>();
        
        for (Document__c doc:docList){
            if(docsVersionMap.containsKey(doc.Name__c)){
                List<String> tempVersion =  docsVersionMap.get(doc.Name__c);
                //tempVersion[0]=doc.Id;
                tempVersion[1]=String.valueOf(Integer.valueOf(tempVersion[1])+1);
                docsVersionMap.put(doc.Name__c,tempVersion);
            } else {
                List<String> tempVersion = new List <String>();
                tempVersion.add(doc.Id);
                tempVersion.add('1');
                docsVersionMap.put(doc.Name__c,tempVersion);    
            }
        }
        
        for (String docId: docsVersionMap.KeySet()){
            docsIds.add(docsVersionMap.get(docId)[0]);
        }
        map <Id, String> docAttachmentMap = new map <Id, String>();
        if (docsIds.size()>0){
            for (ContentDocumentLink cdl: [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId in:docsIds]){
                docAttachmentMap.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
            }
                
            JSONGenerator generator = JSON.createGenerator(true);
            generator.writeStartObject(); 
            generator.writeFieldName('rows');
            generator.writeStartArray(); //Write the starting marker of a JSON object '['
            
            Id siteId = Site.getSiteId(); 
           	boolean isCommunity = false;
            if (siteId != null) { 
                isCommunity=true;
            }
            
            List <Document__share> docShares = CustomDocumentControllerWoutSharing.getDocShares(docAttachmentMap.KeySet());
            map <id,List<Integer>> docToMemberShareCount = new  map <id,List<Integer>>();
            for (Document__share ds: docShares){
                if(docToMemberShareCount.containsKey(ds.ParentId)){
                    List<Integer> tempVersion =  docToMemberShareCount.get(ds.ParentId);
                    if (String.ValueOf(ds.UserOrGroupId).startsWithIgnoreCase('005')){
                        tempVersion[0] = tempVersion[0]+1;
                    } else {
                         tempVersion[1] = tempVersion[1]+1;
                    }
                    docToMemberShareCount.put(ds.ParentId,tempVersion);
                } else {
                    List<Integer> tempVersion = new List <Integer>();
                    if (String.ValueOf(ds.UserOrGroupId).startsWithIgnoreCase('005')){
                        tempVersion.add(1);
                        tempVersion.add(0);
                    } else {
                        tempVersion.add(0);
                    	tempVersion.add(1);
                    }
                    
                    docToMemberShareCount.put(ds.ParentId,tempVersion);    
                }
            }
            
            for (Document__c d: docList){
                if (docAttachmentMap.containsKey(d.Id)){
                    generator.writeStartObject(); //Write the starting marker of a JSON object '{'
                    generator.writeStringField('id', d.Id);
                    
                    generator.writeFieldName('userdata');
                    generator.writeStartObject();
                    generator.writeStringField('ReleaseDate', d.Release_date__c != null ? String.ValueOf(d.Release_date__c) : '');
                    generator.writeBooleanField('SharedWithAccountOnly', d.Shared_with_Users_from_this_account__c);
                    generator.writeBooleanField('Unverified', d.Unverified__c);
                    
                    // end object (})
                    generator.writeEndObject();
                    
                    //generator.writeStringField('ReleaseDate', d.Release_date__c != null ? String.ValueOf(d.Release_date__c) : '');
                    List<String> strlist = new List<String>();
                    String link='';
                    
                    if(d.Name__c.contains('.')){
                        list<String> parsedDocName = d.Name__c.split('\\.');
                        if(knowedFileExtensions.contains(parsedDocName[parsedDocName.size()-1].toLowerCase())){
                            strlist.add(parsedDocName[parsedDocName.size()-1].toLowerCase() + '.png');
                        } else {
                            strlist.add('file.png');
                        }
                    } else {
                        strlist.add('file.png');
                    }
                    
                        link = 'javascript:openModal("' + docAttachmentMap.get(d.Id) + '","public"' + ',' + isCommunity + ')^_self';
                    //}
                    
                    String docName = (docsVersionMap.get(d.Name__c)[1]!='1' ? d.Name__c + ' <span class="docVersion">V.' + docsVersionMap.get(d.Name__c)[1] + '</span>' : (d.Unverified__c ? '[Unverified] ': '') + d.Name__c );
                    strlist.add( docName  + '^' + link );
                    
                    strlist.add('');
                    //strlist.add(d.CreatedDate.month() + '/' +d.CreatedDate.day() +'/' + d.CreatedDate.year());
                    strlist.add(d.CreatedDate.format('MM/dd/YY'));
                    string ownerName = '';
                    if (d.Owner!=null)
                        if (d.Owner.Name.length()>4){
                            ownerName = d.Owner.Name.substring(0,4) + '...';
                        } else {
                            ownerName = d.Owner.Name;
                        }
                    strlist.add(ownerName);
                    String shares = '';
                    if (!docToMemberShareCount.ContainsKey(d.Id)){
                        if(d.OwnerId==userInfo.getUserId()){
                            shares = 'me';
                            strlist.add(shares);
                        } else {
                            shares = d.Owner.Name;
                            strlist.add(shares);
                        }
                    } else {
                        if (docToMemberShareCount.get(d.Id)[1]!=0){
                            shares = docToMemberShareCount.get(d.Id)[1] + ' group(s)';
                        }
                        if (docToMemberShareCount.get(d.Id)[1]!=0 && docToMemberShareCount.get(d.Id)[0]!=0){
                            shares += ' and ' + docToMemberShareCount.get(d.Id)[0] + ' member(s)';
                        } else if (docToMemberShareCount.get(d.Id)[1]==0 && docToMemberShareCount.get(d.Id)[0]!=0){
                            shares = docToMemberShareCount.get(d.Id)[0] + ' member(s)';
                        }
                    	strlist.add(shares);
                    }
                    strlist.add(d.Notes__c);
                    strlist.add(d.Release_date__c != null ? d.Release_date__c.month() + '/' +d.Release_date__c.day() +'/' + d.Release_date__c.year() : '');
                    strlist.add(d.Id);
                    strlist.add(d.Owner.Name);
                    strlist.add(d.OwnerId);
                    strlist.add(String.ValueOf(d.UserRecordAccess.HasEditAccess));
                    strlist.add(shares);
                    generator.writeObjectField('data', strlist);
                    generator.writeEndObject(); //Write the end marker of a JSON object '}'
                }
            }
            generator.writeEndArray(); //Write the end marker of a JSON object ']'
            generator.writeEndObject();
                
            return generator.getAsString();
        }
        return '';
    }
    
    @RemoteAction
     global static List <TagDocumentAssociation__c> getDocsTagsRecords (String docid){
         List <TagDocumentAssociation__c> tags = new List <TagDocumentAssociation__c>();
         tags = [select id,Tag__r.name,Tag__r.ParentTag__r.name, Tag__c,Document_Helper__c,Document__c from TagDocumentAssociation__c where Document__c=:docid];
         return tags;
     }
    
    @RemoteAction
     global static void addTagForDocument (String docid, String tagId){
         list <String> tagsIds = tagId.split(',');
         /*if ([select id,Tag__c,Document__c from TagDocumentAssociation__c where Tag__c=:tagId and Document__c=:docid].size()==0){
             TagDocumentAssociation__c tda = new TagDocumentAssociation__c(Tag__c=tagId,Document__c=docid);
             insert tda;
     	}*/
         set <String> existingTagsAssoc = new set <String>();
         for(TagDocumentAssociation__c tda: [select Tag__c from TagDocumentAssociation__c where Tag__c in : tagsIds and Document__c=:docid]){
             existingTagsAssoc.add(tda.Tag__c);
         }
         List <TagDocumentAssociation__c> tdaInsert = new List <TagDocumentAssociation__c>();
         for (Tag__c tag: [select id from Tag__c where id in:tagsIds and id not in: existingTagsAssoc]){
             TagDocumentAssociation__c tda = new TagDocumentAssociation__c(Tag__c=tag.Id,Document__c=docid);
             tdaInsert.add(tda);
         }
         if (tdaInsert.size()>0)
         	insert tdaInsert;

     }
    @RemoteAction
    global static void LinkDocToRI(String reviewItemId, String selectedId, String content){
        system.debug(content);
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
    
     @RemoteAction
     global static String GetDocNotes (String docid, String reviewItemId){
         try{
        	Junction_Document_ReviewItem__c obj = [ select id,Notes__c from Junction_Document_ReviewItem__c where External_Id__c=:reviewItemId+docid][0];
            return obj.Notes__c;
        } catch(exception e){}
         return '';
     }
    
    @RemoteAction
    global static objectTreeWrapper GetAccountsRelatedLists (String recId){
         if(id.valueOf(recId).getSObjectType().getDescribe().getName()=='Contact'){
             recId = [select id, AccountId from Contact where id=:recId].AccountId;
         }
         if(id.valueOf(recId).getSObjectType().getDescribe().getName()=='Opportunity'){
             recId = [select id, AccountId from Opportunity where id=:recId].AccountId;
         }
         if(id.valueOf(recId).getSObjectType().getDescribe().getName()=='Board_Meeting__c'){
             recId = [select id, Account__c from Board_Meeting__c where id=:recId].Account__c;
         }
         if (id.valueOf(recId).getSObjectType().getDescribe().getName()=='Financial_Report__c'){
             recId = [select id, Account__c from Financial_Report__c where id=:recId].Account__c;
         }
         if (id.valueOf(recId).getSObjectType().getDescribe().getName()=='Round__c'){
             recId = [select id, Target_Company__c from Round__c where id=:recId].Target_Company__c;
         }
         if (id.valueOf(recId).getSObjectType().getDescribe().getName()=='Investment__c'){
             recId = [select id, Investor__c from Investment__c where id=:recId].Investor__c;
         }
         if (id.valueOf(recId).getSObjectType().getDescribe().getName()=='Task'){
             recId = [SELECT Id, AccountId from Task where id=:recId].AccountId;
         }
         if (id.valueOf(recId).getSObjectType().getDescribe().getName()=='review_item__c'){
             system.debug(recId);
            recId = [SELECT Id, Assessment__r.Account__c from review_item__c where id=:recId].Assessment__r.Account__c;
        }

        
        
        Account a = [select Id,name,RecordType.Name,(select id,name from opportunities order by name asc), (select id, name from contacts order by name asc),(select id, name from Board_Meetings__r order by Date__c desc nulls last),(select id, name from Investment__r order by name asc),(select id, name from Investments__r order by name asc) from Account where id=:recId];
        List <Documents_Folder_Template__c> folders = [select id, Name, Parent_Folder__c from Documents_Folder_Template__c order by name];
        objectTreeWrapper wrap = new objectTreeWrapper(a,folders);
        return wrap;
    }
    @AuraEnabled
     global static string getAccNameById (String recordId){
         if(id.valueOf(recordId).getSObjectType().getDescribe().getName()=='Account'){
             Account a = [select id, Name from Account where id=:recordId];
         	return a.Id + '-del-' + a.Name;
         } else if (id.valueOf(recordId).getSObjectType().getDescribe().getName()=='Contact'){
             Contact c = [select AccountId,Account.Name from Contact where id=:recordId];
         	return c.AccountId + '-del-' + c.Account.Name;
         } else if (id.valueOf(recordId).getSObjectType().getDescribe().getName()=='Opportunity'){
             Opportunity o = [select AccountId,Account.Name from Opportunity where id=:recordId];
         	return o.AccountId + '-del-' + o.Account.Name;
         } else if (id.valueOf(recordId).getSObjectType().getDescribe().getName()=='Board_Meeting__c'){
             Board_Meeting__c bm = [select Account__c,Account__r.Name from Board_Meeting__c where id=:recordId];
         	return bm.Account__c + '-del-' + bm.Account__r.Name;
         } else if (id.valueOf(recordId).getSObjectType().getDescribe().getName()=='Round__c'){
             Round__c r = [select Target_Company__c,Target_Company__r.Name from Round__c where id=:recordId];
         	return r.Target_Company__c + '-del-' + r.Target_Company__r.Name;
         } else if (id.valueOf(recordId).getSObjectType().getDescribe().getName()=='Investment__c'){
             Investment__c i = [select Investor__c,Investor__r.Name from Investment__c where id=:recordId];
         	return i.Investor__c + '-del-' + i.Investor__r.Name;
         } else if (id.valueOf(recordId).getSObjectType().getDescribe().getName()=='review_item__c'){
            review_item__c ri = [SELECT Id, Assessment__r.Account__c, Assessment__r.Account__r.Name from review_item__c where id=:recordId];
         	return ri.Assessment__r.Account__c + '-del-' + ri.Assessment__r.Account__r.Name;
        }
         return '';
     }
    
    @RemoteAction
    global static void updateDocument(String docId, String notes, String releaseDate, String docName){
        

        Document__c doc = [select id, Name__c from Document__c where id =: docId];
        if (doc.Name__c.contains('.')){
            List <String> t = doc.Name__c.split('\\.');
            system.debug(t);
            String ext = t[t.size()-1];
            doc.Name__c = docName + '.' + ext;
        } else {
            doc.Name__c = docName;
        }
        doc.Notes__c = notes;
        doc.Release_date__c = releaseDate != null ? DateTime.valueOf(releaseDate.replace('T', ' ')) : null;
        update doc;
    }
    
    
    @RemoteAction
    global static void deleteDocument(String DocId){
        list <String> docs = DocId.split(',');
        list <String> files = new List <String>();
        for (ContentDocumentLink cdl: [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId in:docs]){
            files.add(cdl.ContentDocumentId);
        }
        List <ContentDocument>  cdList= [select id from ContentDocument where id in:files];
        if (cdList.size()>0){
            delete cdList;
        }
        
        delete [select id from Document__c where id in : docs];
    }
    @RemoteAction
    global static String prepareDocumentForUpload(String filename, String parentId, String accId, String selectedTags){
        Document__c doc = new Document__c();
        String trimmedName;
        if (filename.length()>80){
            trimmedName = filename.substring(0,80);
        } else {
            trimmedName=filename;
        }
        doc.Name = trimmedName;
        doc.Name__c = filename;
        
        if (parentId InstanceOf Id){
            if(id.valueOf(parentId).getSObjectType().getDescribe().getName()=='Account'){
                String AccRecordTypeName = [select recordType.Name from account where id=: parentId].recordType.Name;
                if ((AccRecordTypeName == 'Limited Partner' || AccRecordTypeName == 'Bank' || AccRecordTypeName == 'LP (Individuals)') && !Test.isRunningTest()){
                    throw new applicationException('Please, select one of the folders.');
                }
                doc.Account__c=parentId;
                List <Document__c> checkDocPermission = [select id, UserRecordAccess.HasEditAccess from Document__c where Account__c=:parentId and Name__c=:filename order by CreatedDate desc limit 1];
                if (checkDocPermission.size() > 0 && checkDocPermission[0].UserRecordAccess.HasEditAccess!= true){
                    throw new applicationException('You can\'t edit ' + filename + '.');
                }
            } else if (id.valueOf(parentId).getSObjectType().getDescribe().getName()=='Contact'){
                doc.Contact__c=parentId;
                List <Document__c> checkDocPermission = [select id, UserRecordAccess.HasEditAccess from Document__c where Contact__c=:parentId and Name__c=:filename order by CreatedDate desc limit 1];
                if (checkDocPermission.size() > 0 && checkDocPermission[0].UserRecordAccess.HasEditAccess!= true){
                    throw new applicationException('You can\'t edit ' + filename + '.');
                }
            } else if (id.valueOf(parentId).getSObjectType().getDescribe().getName()=='Opportunity'){
                doc.Opportunity__c=parentId;
                List <Document__c> checkDocPermission = [select id, UserRecordAccess.HasEditAccess from Document__c where Opportunity__c=:parentId and Name__c=:filename order by CreatedDate desc limit 1];
                if (checkDocPermission.size() > 0 && checkDocPermission[0].UserRecordAccess.HasEditAccess!= true){
                    throw new applicationException('You can\'t edit ' + filename + '.');
                }
            } else if (id.valueOf(parentId).getSObjectType().getDescribe().getName()=='Board_Meeting__c'){
                doc.Board_Meeting__c=parentId;
                List <Document__c> checkDocPermission = [select id, UserRecordAccess.HasEditAccess from Document__c where Board_Meeting__c=:parentId and Name__c=:filename order by CreatedDate desc limit 1];
                if (checkDocPermission.size() > 0 && checkDocPermission[0].UserRecordAccess.HasEditAccess!= true){
                    throw new applicationException('You can\'t edit ' + filename + '.');
                }
            } else if (id.valueOf(parentId).getSObjectType().getDescribe().getName()=='Round__c'){
                doc.Round__c=parentId;
                List <Document__c> checkDocPermission = [select id, UserRecordAccess.HasEditAccess from Document__c where Round__c=:parentId and Name__c=:filename order by CreatedDate desc limit 1];
                if (checkDocPermission.size() > 0 && checkDocPermission[0].UserRecordAccess.HasEditAccess!= true){
                    throw new applicationException('You can\'t edit ' + filename + '.');
                }
            } else if (id.valueOf(parentId).getSObjectType().getDescribe().getName()=='Investment__c'){
                doc.Investment__c=parentId;
                List <Document__c> checkDocPermission = [select id, UserRecordAccess.HasEditAccess from Document__c where Investment__c=:parentId and Name__c=:filename order by CreatedDate desc limit 1];
                if (checkDocPermission.size() > 0 && checkDocPermission[0].UserRecordAccess.HasEditAccess!= true){
                    throw new applicationException('You can\'t edit ' + filename + '.');
                }
            } else if (id.valueOf(parentId).getSObjectType().getDescribe().getName() == 'Documents_Folder_Template__c'){
                doc.Documents_Folder_Template__c=parentId;
                doc.Account__c = accId;
                List <Document__c> checkDocPermission = [select id, UserRecordAccess.HasEditAccess from Document__c where Documents_Folder_Template__c=:parentId and Name__c=:filename and Account__c =: accId order by CreatedDate desc limit 1];
                if (checkDocPermission.size() > 0 && checkDocPermission[0].UserRecordAccess.HasEditAccess!= true){
                    throw new applicationException('You can\'t edit ' + filename + '.');
                }
            }
        } else {
            if (parentId == 'Documents'){
                throw new applicationException('Please, select one of the folders.');
            }
            doc.Account__c=accId;
            List <Document__c> checkDocPermission = [select id, UserRecordAccess.HasEditAccess from Document__c where Account__c=:accId and Name__c=:filename order by CreatedDate desc limit 1];
            if (checkDocPermission.size() > 0 && checkDocPermission[0].UserRecordAccess.HasEditAccess!= true){
                throw new applicationException('You can\'t edit ' + filename + '.');
            }
        }
        
        insert doc;
        
        if (selectedTags!=null){
            CustomDocumentController.addTagForDocument (doc.Id, selectedTags);
        }
        
        return doc.Id;
    }
    
    @RemoteAction
    global static void changeDocumentsParent(String docsids, String targetId){
        list <String> docs = docsids.split(',');
        List <Document__c> documents = [select id from Document__c where id in : docs];
        for (Document__c doc: documents){
            if (id.valueOf(targetId).getSObjectType().getDescribe().getName()!= 'Documents_Folder_Template__c') doc.Account__c = null;
            doc.Board_Meeting__c=null;
            doc.Contact__c=null;
            doc.Opportunity__c=null;
            doc.Round__c=null;
            doc.Investment__c=null;
            doc.Documents_Folder_Template__c=null;
            if(id.valueOf(targetId).getSObjectType().getDescribe().getName()=='Account'){
                doc.Account__c = targetId;
            } else if (id.valueOf(targetId).getSObjectType().getDescribe().getName()=='Contact'){
                doc.Contact__c = targetId;
            } else if (id.valueOf(targetId).getSObjectType().getDescribe().getName()=='Opportunity'){
                doc.Opportunity__c = targetId;
            } else if (id.valueOf(targetId).getSObjectType().getDescribe().getName()=='Board_Meeting__c'){
                doc.Board_Meeting__c = targetId;
            } else if (id.valueOf(targetId).getSObjectType().getDescribe().getName()=='Round__c'){
                doc.Round__c = targetId;
            } else if (id.valueOf(targetId).getSObjectType().getDescribe().getName()=='Investment__c'){
                doc.Investment__c = targetId;
            } else if (id.valueOf(targetId).getSObjectType().getDescribe().getName()=='Documents_Folder_Template__c'){
                doc.Documents_Folder_Template__c = targetId;
            } 
            
        }
        update documents;
    }
    
    @RemoteAction
     global static Keyword__c getKeywordByTag (String tagId){
         system.debug(tagId);
         Keyword__c kw = new Keyword__c();
         try{
             kw = [select id,Tag__r.name,Tag__c,Keywords__c,IsKeywordEnabled__c from Keyword__c where Tag__r.Id=:tagId limit 1];
         } catch(exception e){}
         
         return kw;
     }
    @RemoteAction
     global static void saveKeywords(String tagId,boolean autoCheckbox, string keywords){ 
     	Keyword__c kw = new Keyword__c();
         try{
             kw = [select id,Keywords__c,IsKeywordEnabled__c from Keyword__c where Tag__r.Id=:tagId limit 1];
         } catch(exception e){}
         kw.Keywords__c = keywords;
         kw.IsKeywordEnabled__c = autoCheckbox;
         kw.Tag__c = tagId;
         upsert kw;
     }
    
    @RemoteAction
    global static void reApplyTags(String AccId){
        
        map <id, List <String>> tagKeywords = new map <id, List <String>>();
        String AccRecordTypeName = accId != null ? [select recordType.Name from account where id=: AccId].recordType.Name : null;
        List <Tag__c> tags = new List <Tag__c>();
        if (AccRecordTypeName == 'Limited Partner' || AccRecordTypeName == 'Bank' || AccRecordTypeName == 'LP (Individuals)'){
            tags = [select id, name, (select id,Tag__c,Tag__r.Name, Keywords__c from Keywords__r where IsKeywordEnabled__c = true)  from Tag__c where Type__c = 'Bank Or LP' order by name asc];
        } else {
            tags = [select id, name, (select id,Tag__c,Tag__r.Name, Keywords__c from Keywords__r where IsKeywordEnabled__c = true) from Tag__c where Account__c =: AccId limit 50000];
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
        for (Document__c doc: [Select id, Name,(select id,Tag__c,Document__c from TagDocumentAssociations__r) from Document__c where 
                               Account__c =:AccId or
                               Board_Meeting__r.Account__c =:AccId or
                               Contact__r.AccountId =:AccId or
                               Opportunity__r.AccountId =:AccId or 
                               Round__r.Target_Company__c =:AccId or
                               Investment__r.Investor__c =:AccId 
                              ]){
            for (ID tagId : tagKeywords.keySet() ){
                for (String keyword: tagKeywords.get(tagId)){
                    if(doc.Name.toLowerCase().Contains(keyword.toLowerCase())){
                        boolean isTagUsed = false;
                        for (TagDocumentAssociation__c currentTDA: doc.TagDocumentAssociations__r){
                            if (currentTDA.Tag__c==tagId){
                                isTagUsed = true;
                            }
                        }
                        if (!isTagUsed){
                            TagDocumentAssociation__c tda = new TagDocumentAssociation__c(Tag__c=tagId,Document__c=doc.Id);
                            tdaList.add(tda);
                        }
                    }
                }
            }
        }
        if (tdaList.size()>0){
            insert tdaList;
        }
    }

    @RemoteAction
    global static void sendEmail(List <String> usersAndGroups, String AccId, String Range){
        CustomDocumentControllerWoutSharing.sendEmail(usersAndGroups, AccId, Range);
    }

    @RemoteAction
    global static List <User> getUsersWithAccessForDocs (String accId){
        return CustomDocumentControllerWoutSharing.getUsersWithAccessForDocs (accId);
    }

    @RemoteAction
    global static void shareWithUsers (List <String> fileids){
        CustomDocumentControllerWoutSharing.shareWithUsers(fileids);
    }
    
    @AuraEnabled
     global static string getCommunityAccId(){
        String accId;
        accId = [select id,Account_Id__c from user where id=:UserInfo.getUserId()].Account_Id__c;
        if (accId == null){
            accId = [select id from Account where Name = 'Canapi' limit 1].Id;
        }
        return accId;
    }
    
     @AuraEnabled
    public static String getBaseUrl(){
        return URL.getSalesforceBaseUrl().toExternalForm() + '/';
    }
    

     @AuraEnabled
     public static objWrapper getCommunityPageHeaderInitValues2 (String recId){ 
         String sobjName = Id.valueOf(recId).getSObjectType().getDescribe().getName(); 
         
         DescribeSObjectResult objResult = Schema.getGlobalDescribe().get(sobjName).getDescribe();
         SObject record;
         String accID = null;
         String accName = null;
         String accDescription = null;
         
         if (sobjName!='Account'){
             try{
                 record = Database.query('Select Name, Account__c, Account__r.Name From ' + sobjName + ' Where Id = :recId');
                 accID = String.ValueOf(record.get('Account__c'));
                 accName = String.ValueOf(record.getSobject('Account__r').get('Name'));
             } catch(exception e){
                 record = Database.query('Select Name, AccountId, Account.Name From ' + sobjName + ' Where Id = :recId');
                 accID = String.ValueOf(record.get('AccountId'));
                 accName = String.ValueOf(record.getSobject('Account').get('Name'));
             }
         } else {
             record = Database.query('Select Name,Description, pbk__Company_Status__c From ' + sobjName + ' Where Id = :recId');
             accDescription = String.ValueOf(record.get('Description')) != null ? String.ValueOf(record.get('Description')) : String.ValueOf(record.get('pbk__Company_Status__c'));
         }

         objWrapper ow = new objWrapper(sobjName, String.ValueOf(record.get('Name')), accID, accName, accDescription);
         return ow;
     }

    global class objectTreeWrapper {
        @AuraEnabled
        public Account acc {get; set;}
        @AuraEnabled
        public List<Documents_Folder_Template__c> folders {get; set;}

        public objectTreeWrapper(Account acc, List<Documents_Folder_Template__c> folders){
            this.folders = folders;
            this.acc = acc;
        }
    }
    
    public class objWrapper {
        @AuraEnabled
        public String sobjName {get; set;}
        @AuraEnabled
        public String recordName {get; set;}
        @AuraEnabled
        public String accID {get; set;}
        @AuraEnabled
        public String accName {get; set;}
        @AuraEnabled
        public String accDescription {get; set;}
        public objWrapper(String sobjName, String recordName, String accID, String accName, String accDescription){
            this.sobjName = sobjName;
            this.recordName = recordName;
            this.accID = accID;
            this.accName = accName;
            this.accDescription = accDescription;
        }
    }

    global class UsersSelectData {
        public String users { get; set; }
        public String groups {get; set;}
        public UsersSelectData(String users, String groups){
            this.users = users;
            this.groups = groups;
        }
    }
    
    public class applicationException extends Exception {}
        
}