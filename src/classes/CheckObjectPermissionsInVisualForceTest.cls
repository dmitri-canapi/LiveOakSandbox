// this class exists as a workaround to known issue W-2616683 where Apex can't
// correctly determine the current user's access because it runs in system mode.
// see https://success.salesforce.com/issues_view?id=a1p300000008djFAAQ
@isTest
public class CheckObjectPermissionsInVisualForceTest {

    @isTest
    public static void permissionsTest() {
        CheckObjectPermissionsInVisualForce permissions = new CheckObjectPermissionsInVisualForce('review_item__c');

        Test.startTest();
        Boolean isAccessible = permissions.isAccessible();
        Boolean isCreateable = permissions.isCreateable();
        Boolean isDeletable = permissions.isDeletable();
        Boolean isUndeletable = permissions.isUndeletable();
        Boolean isUpdateable = permissions.isUpdateable();
        Test.stopTest();

        System.assert(isAccessible);
        System.assert(isCreateable);
        System.assert(isDeletable);
        System.assert(isUndeletable);
        System.assert(isUpdateable);
    }
}