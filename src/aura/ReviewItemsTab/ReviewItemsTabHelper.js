({
    showRowDetails : function(component, event, helper) {
        component.set("v.showDetail", true);
    },

    getFiles : function(component) {
        component.set("v.ReviewItemFiles", null);
        var action = component.get("c.getFileRecords");
        action.setParams({ parentId : component.get("v.ReviewItemRow").Id });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.ReviewItemFiles", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },

    getIsEditable : function(component) {
        component.set("v.isEditable", false);
        var action = component.get("c.isRecordEditable");
        action.setParams({ recordId : component.get("v.ReviewItemRow").Id });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.isEditable", response.getReturnValue());
            }
            component.set("v.isLoading", false);
        });
        $A.enqueueAction(action);
    },
    saveRow : function (component) {
        var action = component.get("c.saveRecord");
            action.setParams({ RIrec: JSON.stringify(component.get("v.ReviewItemRow"))});
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (component.isValid() && state == 'SUCCESS') {   
                     component.set("v.showDetail", false);
                    
                } else {
                    console.log('Failed with state: ' + state);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : 'Error',
                        message: response.getError()[0].message,
                        type: 'error',
                        mode: 'pester'
                    });
                    toastEvent.fire();
                    
                }
            });
            $A.enqueueAction(action);
    }
})