({

    doInit: function (component, event, helper) {
        var action = component.get("c.getWrapper");
        action.setParams({ riID: component.get("v.recordId") });
        action.setCallback(this, function (response) {
            var state = response.getState();
            console.log(state);
            if (state === "SUCCESS") {
                console.log(response.getReturnValue());
                component.set("v.ReviewItemRow", response.getReturnValue().reviewItem);
                component.set("v.isEditable", response.getReturnValue().isRecordEditable);
            }
        });
        $A.enqueueAction(action);

    },

    saveRowDetails: function (component, event, helper) {
        //component.find("edit").get("e.recordSave").fire();
        helper.saveRow(component);
    },
    submitRowDetails: function (component, event, helper) {
        if (confirm("After submitting this review item you may not be able to make additional updates.")) {
            component.set("v.ReviewItemRow.Finished__c", true);
            // component.find("edit").get("e.recordSave").fire();
            helper.saveRow(component);
        }
    },
    closePopup: function (component, event, helper) {
        helper.closePopup(component);
    }
})