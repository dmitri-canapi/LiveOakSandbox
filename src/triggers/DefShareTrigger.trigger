trigger DefShareTrigger on Default_Sharing__c (before insert, before update) {
    
    Map <id,Group> publGroups = new Map <id,Group>([select id, Name from Group]);
    for(Default_Sharing__c ds:trigger.new){
        if (id.valueOf(ds.UserOrGroup__c).getSObjectType().getDescribe().getName() == 'User'){
            ds.User__c = ds.UserOrGroup__c;
        } else {
            ds.Group__c = publGroups.get(ds.UserOrGroup__c).Name;
        }
    }
}