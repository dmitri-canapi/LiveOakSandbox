public without sharing class CustomDocumentControllerWoutSharing {
    public static String getCurrentPermissionsForTheDocument (String currentDocId){
        JSONGenerator generator = JSON.createGenerator(true);
        generator.writeStartObject(); 
        generator.writeFieldName('rows');
        generator.writeStartArray(); //Write the starting marker of a JSON object '['
        List <Document__Share> dshares = [select id,UserOrGroupId,AccessLevel,RowCause from Document__Share where ParentId=:currentDocId and RowCause!= 'Owner'];
        Boolean FinanceTeamShare = [select Shared_with_Users_from_this_account__c from Document__c where id =: currentDocId].Shared_with_Users_from_this_account__c;
        
        Map <id,string> UserOrGroupIds = new map <id,string>();
        
        for (Document__Share  ds: dshares){
            UserOrGroupIds.put(ds.UserOrGroupId,ds.AccessLevel);
        }
        
        for (Group  g: [select Id, Name, DeveloperName, Type FROM Group where id in: UserOrGroupIds.KeySet() order by name asc, DeveloperName asc]){
            generator.writeStartObject(); //Write the starting marker of a JSON object '{'
            generator.writeStringField('id', g.Id);
            List<String> strlist = new List<String>();
            strlist.add( 'Group' );
            if (g.Name == '' || g.Name == null){
                strlist.add( g.DeveloperName );
            } else {
                strlist.add( g.Name );
            }
            strlist.add(UserOrGroupIds.get(g.Id));
            String link='';
            link = 'javascript:removeAccess("' + g.Id + '","' + currentDocId + '")';
            strlist.add( 'X'  + '^' + link + '^_self');
            generator.writeObjectField('data', strlist);
            generator.writeEndObject(); //Write the end marker of a JSON object '}'
        }

        /*if (FinanceTeamShare){
            generator.writeStartObject(); //Write the starting marker of a JSON object '{'
            generator.writeStringField('id', 'OwnAccount');
            List<String> strlist = new List<String>();
            strlist.add( 'Group' );
            strlist.add( 'Finance Team - This account only' );
            strlist.add('Read');
            String link='';
            link = 'javascript:removeAccess("' + 'OwnAccount' + '","' + currentDocId + '")';
            strlist.add( 'X'  + '^' + link + '^_self');
            generator.writeObjectField('data', strlist);
            generator.writeEndObject(); //Write the end marker of a JSON object '}'
        }*/
        
        for (User  u: [select name, (select id from UserContactTagAssociations__r where UserContactTag__r.name ='Finance') from User where id in: UserOrGroupIds.KeySet() order by name asc]){
            generator.writeStartObject(); //Write the starting marker of a JSON object '{'
            generator.writeStringField('id', u.Id);
            List<String> strlist = new List<String>();
            strlist.add( 'User' );
            String Uname = u.Name;
            if (u.UserContactTagAssociations__r.size() > 0 ){
                Uname += ' (Finance Team)';
            }
            strlist.add( Uname );
            strlist.add(UserOrGroupIds.get(u.Id));
            String link='';
            link = 'javascript:removeAccess("' + u.Id + '","' + currentDocId + '")';
            strlist.add( 'X'  + '^' + link + '^_self');
            generator.writeObjectField('data', strlist);
            generator.writeEndObject(); //Write the end marker of a JSON object '}'
        }
        
        generator.writeEndArray(); //Write the end marker of a JSON object ']'
        generator.writeEndObject();
        
        return generator.getAsString();
    }
    
    public static String getCurrentPermissionsForObject (String accId, String DocumentParentObjectId){
        Profile p = [Select Name from Profile where Id =: userinfo.getProfileid()];
        String FullaccId = accId;
        accId = accId.substring(0, 15);
        List <Document__c> docList = new List <Document__c>();   
        
        List <Default_Sharing__c> folderSharings = new List <Default_Sharing__c>();

        String dsQuery = 'select id, UserOrGroup__c, Access__c, Account__r.Name,Board_Meeting__r.Name, Contact__r.Name, Documents_Folder_Template__r.Name,Investment__r.name, Object_For_Share__c,Opportunity__r.name from Default_Sharing__c where Account__c=: accId';
        Set <String> dsQueryTemplFolderidSet = new Set <String>();
        string query = 'select id, Name__c,UserRecordAccess.HasEditAccess, Owner.Name, OwnerId from Document__c where id!=null';
        if (DocumentParentObjectId==FullaccId){
            query+=' AND (Account__c=:accId OR Opportunity__r.AccountId=:accId OR Contact__r.AccountId=:accId OR Board_Meeting__r.Account__c=:accId OR Round__r.Target_Company__c=:accId OR Investment__r.Investor__c=:accId or Investment__r.Round__r.Target_Company__c=:accId)'; 
            dsQuery+=' AND Board_Meeting__c=null AND Contact__c=null AND Documents_Folder_Template__c=null AND Investment__c=null AND Object_For_Share__c=null AND Opportunity__c=null';
        } else if(DocumentParentObjectId=='Opportunities'){
            query+=' AND Opportunity__r.AccountId=:accId'; 
            dsQuery+=' AND Object_For_Share__c =: DocumentParentObjectId';
        } else if(DocumentParentObjectId=='Contacts'){
            query+=' AND Contact__r.AccountId=:accId'; 
            dsQuery+=' AND Object_For_Share__c =: DocumentParentObjectId';
        } else if(DocumentParentObjectId=='Board_Meetings__r'){
            query+=' AND Board_Meeting__r.Account__c=:accId'; 
            dsQuery+=' AND Object_For_Share__c =: DocumentParentObjectId';
        } else if(DocumentParentObjectId=='Investment__r'){// round Relationship name
            query+=' AND Round__r.Target_Company__c=:accId'; 
            dsQuery+=' AND Object_For_Share__c =: DocumentParentObjectId';
        } else if(DocumentParentObjectId=='Investments__r'){// investment Relationship name
            query+=' AND (Investment__r.Investor__c=:accId or Investment__r.Round__r.Target_Company__c=:accId)';     
            dsQuery+=' AND Object_For_Share__c =: DocumentParentObjectId'; 
        } else if(DocumentParentObjectId.contains(',')){
            List <String> docIds = DocumentParentObjectId.split(',');
            query+=' AND Id in:docIds';
        } else if(DocumentParentObjectId=='Documents'){
            query+= ' AND (Documents_Folder_Template__c != null AND Account__c=:accId)';
            dsQuery+=' AND Object_For_Share__c =: DocumentParentObjectId ';
        } else {
            string objName = Id.valueOf(DocumentParentObjectId).getSObjectType().getDescribe().getName(); 
            system.debug(objName);
            if(!objName.contains('__c')){
                objName = objName + '__c';
            }
            if (objName == 'Documents_Folder_Template__c'){
                query+=' AND ((Documents_Folder_Template__c =: DocumentParentObjectId OR Documents_Folder_Template__r.Parent_Folder__c =: DocumentParentObjectId) and (Account__c=:accId))';

                for (Documents_Folder_Template__c dft: [select id,(select id from Documents_Folder_Templates__r where id=: DocumentParentObjectId) from Documents_Folder_Template__c]){
                    if (dft.Documents_Folder_Templates__r.size()>0)
                    dsQueryTemplFolderidSet.add(dft.Id);
                }

                dsQuery+=' AND (Documents_Folder_Template__c =: DocumentParentObjectId OR Documents_Folder_Template__c in: dsQueryTemplFolderidSet or (Object_For_Share__c = \'Documents\'))';
            } else {
                query+=' AND ' + objName + '=:DocumentParentObjectId';
                if (objName == 'Opportunity__c'){
                    dsQuery += (' AND  (' + objName + ' =: DocumentParentObjectId or Object_For_Share__c = \'Opportunities\')');
                } else if (objName == 'Board_Meeting__c'){
                    dsQuery += (' AND  (' + objName + ' =: DocumentParentObjectId or Object_For_Share__c = \'Board_Meetings__r\')');
                } else {
                    dsQuery += (' AND  ' + objName + ' =: DocumentParentObjectId');
                }
                
            }
        }
        
        if (p.Name!='System Administrator' && p.Name != 'Canapi System Admin'){
            string Uid = userInfo.getUserId();
             query+=' AND OwnerId =: Uid';
        }
        query+=' order by Name__c desc';

        dsQuery+=' order by Object_For_Share__c asc nulls last';
        system.debug(dsQuery);
        
		map <Id,Document__c> docsIds = new  map <Id,Document__c>();
		for (Document__c doc:Database.query(query)){
            docsIds.put(doc.Id, doc);
        }

        List <Document__Share> dshares = [select id,UserOrGroupId,AccessLevel,RowCause,ParentId from Document__Share where ParentId in: docsIds.keySet() and RowCause!= 'Owner'];
        Set <id> UserOrGroupIds = new Set <id>();
        map <id,string> UserOrGroupIdstonameMap = new map <id,string>();

        List <Default_Sharing__c> userDefSharings = [select id, UserOrGroup__c, Access__c from Default_Sharing__c where CreatedBy__c =: userInfo.getUserId() and Account__c =: null];
        List <Default_Sharing__c> accDefSharings = [select id, UserOrGroup__c, Access__c,Account__r.Name from Default_Sharing__c where Board_Meeting__c=null AND Contact__c=null AND Documents_Folder_Template__c=null AND Investment__c=null AND Object_For_Share__c=null AND Opportunity__c=null and Account__c =: accId];

        
        folderSharings = Database.query(dsQuery);
        
        for(Default_Sharing__c ds: userDefSharings){
            UserOrGroupIds.add(ds.UserOrGroup__c);
        }

        for(Default_Sharing__c ds: accDefSharings){
            UserOrGroupIds.add(ds.UserOrGroup__c);
        }

        for(Default_Sharing__c ds: folderSharings){
            UserOrGroupIds.add(ds.UserOrGroup__c);
        }

        for (Document__Share  ds: dshares){
            UserOrGroupIds.add(ds.UserOrGroupId);
        }
        for (Group  g: [select Id, Name, DeveloperName, Type FROM Group where id in: UserOrGroupIds order by name asc, DeveloperName asc]){
            string gName='';
            if (g.Name == '' || g.Name == null){
                gName = g.DeveloperName;
            } else {
                 gName = g.Name;
            }
            UserOrGroupIdstonameMap.put(g.Id, gName);
        }
        for (User  u: [select name from User where id in: UserOrGroupIds order by name asc]){
            UserOrGroupIdstonameMap.put(u.Id, u.name);
        }
        
        
        JSONGenerator generator = JSON.createGenerator(true);
        generator.writeStartObject(); 
        generator.writeFieldName('rows');
        generator.writeStartArray(); //Write the starting marker of a JSON object '['

        for (Default_Sharing__c ds : userDefSharings){
            generator.writeStartObject(); //Write the starting marker of a JSON object '{'
            generator.writeStringField('id', ds.Id);
            List<String> strlist = new List<String>();
            
            strlist.add('[U] User Default');
                        
            if (String.ValueOf(ds.UserOrGroup__c).startsWithIgnoreCase('005')){
            	strlist.add( 'User' );
            } else {
                strlist.add( 'Group' );
            }
            strlist.add( UserOrGroupIdstonameMap.get(ds.UserOrGroup__c) );
            strlist.add(ds.Access__c);
            String link='';
            link = 'javascript:removeDefaultSharing("' + ds.Id + '")';
            strlist.add( 'X'  + '^' + link + '^_self');
            generator.writeObjectField('data', strlist);
            generator.writeEndObject(); //Write the end marker of a JSON object '}'
        }

        for (Default_Sharing__c ds : accDefSharings){
            generator.writeStartObject(); //Write the starting marker of a JSON object '{'
            generator.writeStringField('id', ds.Id);
            List<String> strlist = new List<String>();
            
            strlist.add('[F] ' + ds.Account__r.Name + ' (Account)');
                        
            if (String.ValueOf(ds.UserOrGroup__c).startsWithIgnoreCase('005')){
            	strlist.add( 'User' );
            } else {
                strlist.add( 'Group' );
            }
            strlist.add( UserOrGroupIdstonameMap.get(ds.UserOrGroup__c) );
            strlist.add(ds.Access__c);
            String link='';
            link = 'javascript:removeDefaultSharing("' + ds.Id + '")';
            strlist.add( 'X'  + '^' + link + '^_self');
            generator.writeObjectField('data', strlist);
            generator.writeEndObject(); //Write the end marker of a JSON object '}'
        }

        for (Default_Sharing__c ds : folderSharings){
            generator.writeStartObject(); //Write the starting marker of a JSON object '{'
            generator.writeStringField('id', ds.Id);
            List<String> strlist = new List<String>();
            
            String shareLabel = '[F] ';
            if (ds.Opportunity__c != null){
                shareLabel += ds.Opportunity__r.Name;
            } else if (ds.Object_For_Share__c != null){
                if (ds.Object_For_Share__c == 'Opportunities'){
                    ds.Object_For_Share__c = 'Deals';
                } else if (ds.Object_For_Share__c == 'Board_Meetings__r'){
                    ds.Object_For_Share__c = 'Board Meetings';
                }
                shareLabel += ds.Object_For_Share__c;
            } else if (ds.Investment__c != null){
                shareLabel += ds.Investment__r.name;
            } else if (ds.Documents_Folder_Template__c != null){
                shareLabel += ds.Documents_Folder_Template__r.Name;
            } else if (ds.Contact__c != null){
                shareLabel += ds.Contact__r.Name;
            } else if (ds.Board_Meeting__c != null){
                shareLabel += ds.Board_Meeting__r.Name;
            } else {
                shareLabel += ds.Account__r.Name;
            } 
            strlist.add(shareLabel);
            
            
            if (String.ValueOf(ds.UserOrGroup__c).startsWithIgnoreCase('005')){
            	strlist.add( 'User' );
            } else {
                strlist.add( 'Group' );
            }
            strlist.add( UserOrGroupIdstonameMap.get(ds.UserOrGroup__c) );
            strlist.add(ds.Access__c);
            String link='';
            link = 'javascript:removeDefaultSharing("' + ds.Id + '")';
            strlist.add( 'X'  + '^' + link + '^_self');
            generator.writeObjectField('data', strlist);
            generator.writeEndObject(); //Write the end marker of a JSON object '}'
        }

        for (Document__Share ds : dshares){
            generator.writeStartObject(); //Write the starting marker of a JSON object '{'
            generator.writeStringField('id', ds.Id);
            List<String> strlist = new List<String>();
            strlist.add(docsIds.get(ds.ParentId).Name__c);
            
            if (String.ValueOf(ds.UserOrGroupId).startsWithIgnoreCase('005')){
            	strlist.add( 'User' );
            } else {
                strlist.add( 'Group' );
            }
            strlist.add( UserOrGroupIdstonameMap.get(ds.UserOrGroupId) );
            strlist.add(ds.AccessLevel);
            String link='';
            link = 'javascript:removeBulkAccess("' + ds.Id + '")';
            strlist.add( 'X'  + '^' + link + '^_self');
            generator.writeObjectField('data', strlist);
            generator.writeEndObject(); //Write the end marker of a JSON object '}'
        }
        
        generator.writeEndArray(); //Write the end marker of a JSON object ']'
        generator.writeEndObject();
        
        return generator.getAsString();
    }
    
    public static String getCurrentDefaultSharings(){
    	JSONGenerator generator = JSON.createGenerator(true);
        generator.writeStartObject(); 
        generator.writeFieldName('rows');
        generator.writeStartArray(); //Write the starting marker of a JSON object '['
        List <Default_Sharing__c> dshares = [select id, UserOrGroup__c, Access__c, createdById  from Default_Sharing__c where CreatedBy__c =: userInfo.getUserId() and Account__c = null];
        Map <id,Default_Sharing__c> UserOrGroupIds = new map <id,Default_Sharing__c>();

        for (Default_Sharing__c  ds: dshares){
            UserOrGroupIds.put(ds.UserOrGroup__c,ds);
        }
        
        for (Group  g: [select Id, Name, DeveloperName, Type FROM Group where id in: UserOrGroupIds.KeySet() order by name asc, DeveloperName asc]){
            generator.writeStartObject(); //Write the starting marker of a JSON object '{'
            generator.writeStringField('id', UserOrGroupIds.get(g.Id).Id);
            List<String> strlist = new List<String>();
            strlist.add( 'Group' );
            if (g.Name == '' || g.Name == null){
                strlist.add( g.DeveloperName );
            } else {
                strlist.add( g.Name );
            }
            strlist.add(UserOrGroupIds.get(g.Id).Access__c);
            String link='';
            link = 'javascript:removeDSAccess("' + UserOrGroupIds.get(g.Id).Id + '")';
            strlist.add( 'X'  + '^' + link + '^_self' );
            generator.writeObjectField('data', strlist);
            generator.writeEndObject(); //Write the end marker of a JSON object '}'
        }
        
        for (User  u: [select name from User where id in: UserOrGroupIds.KeySet() order by name asc]){
            generator.writeStartObject(); //Write the starting marker of a JSON object '{'
            generator.writeStringField('id', UserOrGroupIds.get(u.Id).Id);
            List<String> strlist = new List<String>();
            strlist.add( 'User' );
            strlist.add( u.Name );
            strlist.add(UserOrGroupIds.get(u.Id).Access__c);
            String link='';
            link = 'javascript:removeDSAccess("' + UserOrGroupIds.get(u.Id).Id + '")';
            strlist.add( 'X'  + '^' + link + '^_self');
            generator.writeObjectField('data', strlist);
            generator.writeEndObject(); //Write the end marker of a JSON object '}'
        }
        
        generator.writeEndArray(); //Write the end marker of a JSON object ']'
        generator.writeEndObject();
        
        return generator.getAsString();
    }

    public static String getFavoriteGroups(){
        Favorite_Group__mdt favGroupsids = [select id,List_of_Id_s__c from Favorite_Group__mdt limit 1];
        JSONGenerator generator = JSON.createGenerator(true);
        generator.writeStartArray();
        for (Group g: [select id, Name, DeveloperName from Group where id in: favGroupsids.List_of_Id_s__c.split(',')]){
            generator.writeStartObject();
            generator.writeStringField('id', 'ShareWithGroup' + g.Id);
            if (g.Name == '' || g.Name == null){
                generator.writeStringField('text', g.DeveloperName);
            } else {
                generator.writeStringField('text', g.Name);
            }
            generator.writeEndObject();
        }
        generator.writeStartObject();
        generator.writeStringField('id', 'OwnAccount');
        generator.writeStringField('text', 'Finance Team - This account only');
        generator.writeEndObject();

        generator.writeStartObject();
        generator.writeStringField('id', 'RestrictAccess');
        generator.writeStringField('text', 'Edit Sharing...');
        generator.writeEndObject();

        generator.writeEndArray();
        return generator.getAsString(); 
    }
    
    private static String getGroups(String profileName){
        list <Group> groups = [SELECT Id, Name, DeveloperName, Type FROM Group where type='Regular' Or type ='AllCustomerPortal' Or type ='Organization' order by Name asc,DeveloperName asc  limit 1000];
        JSONGenerator generator = JSON.createGenerator(true);
        generator.writeStartObject(); 
        generator.writeFieldName('options');
        generator.writeStartArray(); //Write the starting marker of a JSON object '['
        
        for (Group u: groups){
            if (profileName == '' || (profileName != '' && u.Name == 'Alliance Portal Users')){
                generator.writeStartObject(); //Write the starting marker of a JSON object '{'
                generator.writeStringField('value', u.Id);
                generator.writeStringField('img', '');
                if (u.Name == '' || u.Name == null){
                    generator.writeStringField('text', u.DeveloperName);
                } else {
                    generator.writeStringField('text', u.Name);
                }
                generator.writeEndObject(); //Write the end marker of a JSON object '}'
            }
        }

        generator.writeEndArray(); //Write the end marker of a JSON object ']'
        generator.writeEndObject();
        
        return generator.getAsString();
    }
    public static CustomDocumentController.UsersSelectData getUsers(String profileName){
        list <User> usrs = [select id,name,SmallPhotoUrl,Profile.Name from User where id!=:userInfo.getUserId() and isActive=true and name!='Automated Process' and (Profile.UserLicense.Name='Salesforce' or Profile.UserLicense.Name='Customer Community Plus' or Profile.UserLicense.Name='Customer Community Plus Login') order By name ASC];
        JSONGenerator generator = JSON.createGenerator(true);
        generator.writeStartObject(); 
        generator.writeFieldName('options');
        generator.writeStartArray(); //Write the starting marker of a JSON object '['
        
        for (User u: usrs){
            if(u.Profile.Name == profileName || profileName == ''){
                generator.writeStartObject(); //Write the starting marker of a JSON object '{'
                generator.writeStringField('value', u.Id);
                generator.writeStringField('img', u.SmallPhotoUrl);
                generator.writeStringField('text', u.Name);
                generator.writeEndObject(); //Write the end marker of a JSON object '}'
            }
        }
        generator.writeEndArray(); //Write the end marker of a JSON object ']'
        generator.writeEndObject();
        
        return new CustomDocumentController.UsersSelectData (generator.getAsString(), getGroups(profileName));
        
    }

    public static List <User> getUsersWithAccessForDocs (String accId){

        Map<ID, Document__c> docs = new Map<ID, Document__c>((List <Document__c>)([select id from Document__c where (Account__c=:accId OR Contact__r.AccountId=:accId OR Board_Meeting__r.Account__c=:accId OR Opportunity__r.AccountId=:accId)]));


        List <Document__share> dsList = getDocShares(docs.KeySet());

        set <String> usersids = new set <String>();


        Map<Id, Set <String>> groupWithUsers = new Map<Id, Set <String>>();
        for (Document__share ds: dsList){
            if (id.valueOf(ds.UserOrGroupId).getSObjectType().getDescribe().getName() == 'Group'){
                groupWithUsers.put(ds.UserOrGroupId, new Set <String>());
            } else {
                usersids.add(ds.UserOrGroupId);
            }
        }

        for (GroupMember gm: [SELECT UserOrGroupId, GroupId FROM GroupMember WHERE GroupId in: groupWithUsers.KeySet()]){
            if (id.valueOf(gm.UserOrGroupId).getSObjectType().getDescribe().getName() == 'User'){
                usersids.add(gm.UserOrGroupId);
            }
        }

        return [select id, Name from User where id in: usersids];

    }

    public static void sendEmail(List <String> usersAndGroups, String accId, String Range){
        String accName = [select Name from account where id =: accId].Name;
        Set <String> allUsersIds = new set <string>();
        Set <String> groupsIds = new set <string>();
        for (String s: usersAndGroups){
            if (id.valueOf(s).getSObjectType().getDescribe().getName() == 'User'){
                allUsersIds.add(s);
            } else {
                groupsIds.add(s);
            }
        }
        Set <String> usersFromGroups = new set <string>(); 
        
        for (GroupMember gm: [SELECT UserOrGroupId FROM GroupMember WHERE GroupId in: groupsIds]){
            if (id.valueOf(gm.UserOrGroupId).getSObjectType().getDescribe().getName() == 'User'){
                usersFromGroups.add(gm.UserOrGroupId);
            }
        }
        for (User u: [select id from User where Profile.Name = 'Community: Alliance Portal' and id in: usersFromGroups]){
            allUsersIds.add(u.Id);
        }
        system.debug(allUsersIds);

        Map <String, Set<Id>> usersWithDocs = new Map <String, Set<Id>> ();

        for(String uId: allUsersIds){
            usersWithDocs.put(uId,New Set<Id>());
        }

        String todayDate = DateTime.now().format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');


        string query = 'select id, Name__c, CreatedDate from Document__c where (Account__c=:accId OR Contact__r.AccountId=:accId OR Board_Meeting__r.Account__c=:accId OR Opportunity__r.AccountId=:accId) and ';
        if (Range == 'Today'){
            query += '(CreatedDate >= ' + todayDate +  'OR LastModifiedDate >=  ' + todayDate + ')';
        } else if (Range == 'This Week'){
            query += '(CreatedDate >= THIS_WEEK OR LastModifiedDate >= THIS_WEEK)';
        } else if (Range == '7 Days'){
            query += '(CreatedDate >= LAST_N_DAYS:7 OR LastModifiedDate >= LAST_N_DAYS:7)';
        } else if (Range == 'This Month'){
            query += '(CreatedDate >= THIS_MONTH OR LastModifiedDate >= THIS_MONTH)';
        }
        query+=' order by Name__c asc';
        system.debug(query);
        
        Map<ID, Document__c> docs = new Map<ID, Document__c>((List <Document__c>)(Database.query(query)));


        List <Document__share> dsList = getDocShares(docs.KeySet());


        Map<Id, Set <String>> groupWithUsers = new Map<Id, Set <String>>();
        for (Document__share ds: dsList){
            if (id.valueOf(ds.UserOrGroupId).getSObjectType().getDescribe().getName() == 'Group'){
                groupWithUsers.put(ds.UserOrGroupId, new Set <String>());
            }
        }
        for (GroupMember gm: [SELECT UserOrGroupId, GroupId FROM GroupMember WHERE GroupId in: groupWithUsers.KeySet()]){
            if (id.valueOf(gm.UserOrGroupId).getSObjectType().getDescribe().getName() == 'User'){
                Set<String> tempUsers =  groupWithUsers.get(gm.GroupId);
                tempUsers.add(gm.UserOrGroupId);
                groupWithUsers.put(gm.GroupId, tempUsers);
            }
        }

        for (Document__share ds: dsList){
            if (id.valueOf(ds.UserOrGroupId).getSObjectType().getDescribe().getName() == 'User'){
                if (usersWithDocs.containsKey(ds.UserOrGroupId)){
                    Set <Id> docsIds = usersWithDocs.get(ds.UserOrGroupId);
                    docsIds.add(ds.ParentId);
                    usersWithDocs.put(ds.UserOrGroupId, docsIds);
                }
            } else {
                for (String uId: groupWithUsers.get(ds.UserOrGroupId)){
                    if (usersWithDocs.containsKey(uId)){
                        Set <Id> docsIds = usersWithDocs.get(uId);
                        docsIds.add(ds.ParentId);
                        usersWithDocs.put(uId, docsIds);
                    }
                }
            } 
        }

        List <Messaging.SingleEmailMessage> messages = new List <Messaging.SingleEmailMessage>();

        if (Test.IsRunningTest()){
            usersWithDocs.put(userInfo.getUserId(), new Set <Id>());
        }

        for(String Uid: usersWithDocs.KeySet()){
            if(usersWithDocs.get(Uid).size()>0 || Test.IsRunningTest()){
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setSubject('New Documents Available');
                message.setTargetObjectId(Uid);
                message.setSaveAsActivity(false);
                message.setUseSignature(false);

                String emailBody = '<H2>New Documents Available</H2><br/>';
                emailBody += 'The following ' + accName + ' document(s) were recently updated on Alliance:<br/>';
                emailBody += '<ul>';
                for (String docId: usersWithDocs.get(Uid)){
                    emailBody += '<li><a href="https://canapi.force.com/alliance/s/account/' + accId + '?tabset-35136=3">' + docs.get(docId).Name__c + '</a> - ' + docs.get(docId).CreatedDate +  '</li>';
                }
                emailBody += '</ul>';
                message.setHTMLBody(emailBody);

                messages.add(message);

            }

        }

        if (messages.size() > 0){
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        }

        




    }


    public static void addPermission (String userOrGroupId,String currentDocId, String AccessType){
        Document__Share ds = new Document__Share();
        ds.ParentId = currentDocId;
        ds.UserOrGroupId = userOrGroupId;
        ds.AccessLevel = AccessType;
        insert ds;
        
        List <ContentDocumentLink> cdlList = new List <ContentDocumentLink> ();
        cdlList=  [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =:currentDocId];
        for(ContentDocumentLink l:cdlList) {
            l.Visibility='AllUsers';
        } 
        if (cdlList.size()>0){
            update cdlList;
        }
            
    }
    
    public static void addDefaultPermission (String userOrGroupId, String AccessType){
        Default_Sharing__c ds = new Default_Sharing__c();
        try {
            ds = [select id, UserOrGroup__c, Access__c, createdById from Default_Sharing__c where UserOrGroup__c= : userOrGroupId and CreatedBy__c =:userInfo.getUserId() ];
        } catch(exception e){}
        ds.CreatedBy__c = userInfo.getUserId();
        ds.UserOrGroup__c = userOrGroupId;
        ds.Access__c = AccessType;
        upsert ds;
    }

    public static void setAccountShareOnly(String docIds, boolean state, String AccId, String AccessLevel){
        List <Document__c> docs = [select id, OwnerId from Document__c where id in: docIds.split(',')];
        
        if (state){
            list <Document__Share> dsList = new list <Document__Share>();
            
            List <User> FinTeamUsers = [select id from User where Account_Id__c =: AccId and id !=: userInfo.getUserId() and IsActive = true and id in (select User__c from UserContactTagAssociation__c where UserContactTag__r.Name = 'Finance')];
            if (FinTeamUsers.size() == 0 && !Test.IsRunningTest()){
                throw new CustomDocumentController.applicationException('Unable to share with Finance Team. No portal users tagged "Finance" found for this account');
            }
            for (User u: FinTeamUsers){
                for (Document__c doc : docs){   
                    doc.Shared_with_Users_from_this_account__c = state; 
                    doc.Shared_With_Account__c = AccId;
                    if (doc.OwnerId != u.Id){
                        Document__Share ds = new Document__Share();
                        ds.ParentId = doc.Id;
                        ds.UserOrGroupId = u.Id;
                        ds.AccessLevel = AccessLevel;
                        dsList.add(ds);
                    }
                }
            }
            insert dsList;

            List <ContentDocumentLink> cdlList = new List <ContentDocumentLink> ();
            cdlList=  [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =:docIds.split(',')];
            for(ContentDocumentLink l:cdlList) {
                l.Visibility='AllUsers';
            } 
            if (cdlList.size()>0){
                update cdlList;
            }
        } else {
            delete [select id from Document__Share where ParentId in: docIds.split(',') and RowCause='Manual'];
        }
        update docs;
    }

    public static void shareForFavGroups(String userOrGroupId,String docIds){
        userOrGroupId = userOrGroupId.replace('ShareWithGroup','');
        
        list <Document__Share> dsList = new list <Document__Share>();

        for (String doc : docIds.split(',')){
            Document__Share ds = new Document__Share();
            ds.ParentId = doc;
            ds.UserOrGroupId = userOrGroupId;
            ds.AccessLevel = 'Read';
            dsList.add(ds);
        }

        
        insert dsList;
        
        List <ContentDocumentLink> cdlList = new List <ContentDocumentLink> ();
        cdlList=  [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =:docIds.split(',')];
        for(ContentDocumentLink l:cdlList) {
            l.Visibility='AllUsers';
        } 
        if (cdlList.size()>0){
            update cdlList;
        }
    }
    
    public static void addBulkPermission (String userOrGroupId,String accId, String DocumentParentObjectId, String AccessType){
        Profile p = [Select Name from Profile where Id =: userinfo.getProfileid()];
        String FullaccId = accId;
        accId = accId.substring(0, 15);
        List <Document__c> docList = new List <Document__c>();   
        Default_Sharing__c ds = new Default_Sharing__c (Account__c = accId,UserOrGroup__c = userOrGroupId, Access__c = AccessType);
        String dsQuery = 'select id from Default_Sharing__c where Account__c =: accId and UserOrGroup__c=: userOrGroupId';
        
        string query = 'select id, Name__c,UserRecordAccess.HasEditAccess, Owner.Name, OwnerId from Document__c where id!=null';
        if (DocumentParentObjectId==FullaccId){
            query+=' AND (Account__c=:accId OR Opportunity__r.AccountId=:accId OR Contact__r.AccountId=:accId OR Board_Meeting__r.Account__c=:accId OR Round__r.Target_Company__c=:accId OR Investment__r.Investor__c=:accId or Investment__r.Round__r.Target_Company__c=:accId)'; 
            dsQuery+=' AND Board_Meeting__c=null AND Contact__c=null AND Documents_Folder_Template__c=null AND Investment__c=null AND Object_For_Share__c=null AND Opportunity__c=null';
        } else if(DocumentParentObjectId=='Opportunities'){
            query+=' AND Opportunity__r.AccountId=:accId';
            ds.Object_For_Share__c = 'Opportunities';
            dsQuery += 'Object_For_Share__c =: ds.Object_For_Share__c';
        } else if(DocumentParentObjectId=='Contacts'){
            query+=' AND Contact__r.AccountId=:accId'; 
            ds.Object_For_Share__c = DocumentParentObjectId;
            dsQuery += 'Object_For_Share__c =: ds.Object_For_Share__c';
        } else if(DocumentParentObjectId=='Board_Meetings__r'){
            query+=' AND Board_Meeting__r.Account__c=:accId'; 
            ds.Object_For_Share__c = DocumentParentObjectId;
            dsQuery += 'Object_For_Share__c =: ds.Object_For_Share__c';
        } else if(DocumentParentObjectId=='Investment__r'){// round Relationship name
            query+=' AND Round__r.Target_Company__c=:accId'; 
            ds.Object_For_Share__c = DocumentParentObjectId;
            dsQuery += 'Object_For_Share__c =: ds.Object_For_Share__c';
        } else if(DocumentParentObjectId=='Investments__r'){// investment Relationship name
            query+=' AND (Investment__r.Investor__c=:accId or Investment__r.Round__r.Target_Company__c=:accId)';  
            ds.Object_For_Share__c = DocumentParentObjectId;
            dsQuery += 'Object_For_Share__c =: ds.Object_For_Share__c';
        } else if(DocumentParentObjectId.contains(',')){
            List <String> docIds = DocumentParentObjectId.split(',');
            query+=' AND Id in:docIds';
        } else if(DocumentParentObjectId=='Documents'){
            query+= ' AND (Documents_Folder_Template__c != null AND Account__c=:accId)';
            ds.Object_For_Share__c = DocumentParentObjectId;
            dsQuery += 'Object_For_Share__c =: ds.Object_For_Share__c';
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

            ds.put(objName,DocumentParentObjectId);
            dsQuery += (' and  ' + objName + ' =: DocumentParentObjectId');
        }
        
        if (p.Name!='System Administrator' && p.Name != 'Canapi System Admin'){
            string Uid = userInfo.getUserId();
            query+=' AND OwnerId =: Uid';
        }
        system.debug(query);
        if (userOrGroupId.startsWithIgnoreCase('005')){
            query+=' AND OwnerId !=:userOrGroupId';
        }
        system.debug(query);
        
		list <Document__Share> dsList = new list <Document__Share>();
		Set<Id> docIds = new Set<Id>();
        
        for (Document__c doc:Database.query(query)){
            Document__Share dshare = new Document__Share();
            dshare.ParentId = doc.Id;
            dshare.UserOrGroupId = userOrGroupId;
            dshare.AccessLevel = AccessType;
            dsList.add(dshare);
            docIds.add(doc.Id);
        }
        
        if (dsList.size()>0){
            insert dsList;
        }
        
        List <ContentDocumentLink> cdlList = new List <ContentDocumentLink> ();
        if (!Test.isRunningTest()){
            cdlList=  [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId  in: docIds  or ContentDocumentId=:userInfo.getUserId()];
            for(ContentDocumentLink l:cdlList) {
                l.Visibility='AllUsers';
            } 
            if (cdlList.size()>0){
                update cdlList;
            }
        }

        try{
            dsQuery += ' limit 1';
            system.debug(dsQuery);
            Default_Sharing__c existingDS = Database.query(dsQuery);
            ds.Id = existingDS.Id;
        } catch(exception e){
            system.debug(e);
        }
        upsert ds;
    }
    
    public static void removeAccess (String userOrGroupId, String currentDocId){
        delete [select id from Document__Share where userOrGroupId=:userOrGroupId and ParentId=:currentDocId];
    }
    
    public static void removeBulkAccess (String dsId){
        delete [select id from Document__Share where id=:dsId];
    }

    public static void removeDefaultSharing (String dsId){
        delete [select id from Default_Sharing__c where id=:dsId];
    }
    
    public static List <Document__share> getDocShares (Set <Id> docsIds){
        List <Document__share> dsList = new List <Document__share>();
        dsList = [select id, ParentId, AccessLevel,UserOrGroupId,RowCause from Document__share where ParentId in:docsIds and RowCause='Manual'];
        return dsList;
    }

    public static void shareWithUsers (List <String> fileids){
        List <ContentDocumentLink> cdlList =  [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId  in: fileids];
        for(ContentDocumentLink l:cdlList) {
            l.Visibility='AllUsers';
        } 
        update cdlList;
        
    }
}