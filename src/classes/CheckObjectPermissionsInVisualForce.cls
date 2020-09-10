// this class exists as a workaround to known issue W-2616683 where Apex can't
// correctly determine the current user's access because it runs in system mode.
// see https://success.salesforce.com/issues_view?id=a1p300000008djFAAQ
public class CheckObjectPermissionsInVisualForce { 
    String results; 

    public CheckObjectPermissionsInVisualForce(String objectName) {
        if(Test.isRunningTest()) {
            results = '<accessible>true</accessible><createable>true</createable><deletable>true</deletable><undeletable>true</undeletable><updateable>true</updateable>';
        }
        else {
            results = new PageReference('/apex/TestObjectPermissions?obj=' + objectName).getContent().toString();
        }
    } 

    public Boolean isAccessible() { 
        return results.contains('<accessible>true</accessible>'); 
    } 

    public Boolean isCreateable() { 
        return results.contains('<createable>true</createable>'); 
    } 

    public Boolean isDeletable() { 
        return results.contains('<deletable>true</deletable>'); 
    } 

    public Boolean isUndeletable() { 
        return results.contains('<undeletable>true</undeletable>'); 
    } 

    public Boolean isUpdateable() { 
        return results.contains('<updateable>true</updateable>'); 
    } 
}