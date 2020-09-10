trigger UserContactTagTrigger on UserContactTag__c (after update) {

    Map <String,String> uctValues = new Map <String,String> ();
    for (UserContactTag__c uct: trigger.new){
        if(Trigger.oldMap.get(uct.Id).Name != uct.Name){
            uctValues.put(Trigger.oldMap.get(uct.Id).Name, uct.Name);
        }
    }

    //List<String> vals = new List<String>(uctValues.keySet());
    String categories = String.join(new List<String>(uctValues.keySet()), ';');

    List <Contact> conts = [select id, Function_Tags__c, Title_Tags__c from Contact where Function_Tags__c includes (:categories) or Title_Tags__c includes (:categories) limit 10000];

    for (Contact c: conts){
        if (c.Function_Tags__c != null){
            for (String s: uctValues.keyset()){
                c.Function_Tags__c = c.Function_Tags__c.replace(s, uctValues.get(s));
            }
        }
        if (c.Title_Tags__c != null){
            for (String s: uctValues.keyset()){
                c.Title_Tags__c = c.Title_Tags__c.replace(s, uctValues.get(s));
            }
        }
    }
    update conts;
    
}