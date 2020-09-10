({
    doInit : function(component, event, helper){
        component.set('v.columns', [
            {label: 'Review Item Name', fieldName: 'Review_Item_Name__c', type: 'text'},
            {label: 'Review Item Status', fieldName: 'Review_Item_Status__c', type: 'text'},
            {label: 'Assets Needed', fieldName: 'Assets_Needed__c', type: 'text'},
            {label: 'Details', type: 'button', initialWidth: 135, typeAttributes: {label: 'Edit', name: 'details', title: 'Click to Edit Details'}}
        ]);

        helper.getIsCreateable(component);
        helper.getRecords(component);
    },

    doRefresh : function(component, event, helper){
        helper.getRecords(component);
    },

    createRecord : function(component, event, helper){
        var createRecordEvent = $A.get("e.force:createRecord");
	    createRecordEvent.setParams({
	        "entityApiName": "review_item__c",
	        "defaultFieldValues":{
	            "Assessment__c" : component.get("v.recordId")
	        }
	    });
	    createRecordEvent.fire();
    }
})