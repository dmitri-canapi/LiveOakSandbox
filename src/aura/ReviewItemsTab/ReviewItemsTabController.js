({
    doInit : function(component, event, helper){
        
        var key = component.get("v.title");
        var map = component.get("v.ReviewItemMap");
        console.log(map);
        if (map) {
            component.set("v.ReviewItemData" , map[key]);
            component.set("v.description", map[key][0].Item_Category_Description__c);
        }
        
        var catList = [];
        
        for ( var key in map ) {
            catList.push({keyName:key});
        }
        component.set("v.catList" , catList);
    },

    handleTabClick : function(component, event){
        var clickedTabTitle = event.getParam("title");
        var thisTabTitle = component.get("v.title");
        var tabdiv = component.find("tabdiv");

        if (clickedTabTitle == thisTabTitle) {
            $A.util.removeClass(tabdiv, "slds-hide");
            $A.util.addClass(tabdiv, "slds-show");
        }
        else {
            $A.util.removeClass(tabdiv, "slds-show");
            $A.util.addClass(tabdiv, "slds-hide");
        }
    },

    handleRowAction : function (component, event, helper) {
        console.log("handleRowAction()");
        var action = event.getParam("action");
        var row = event.getParam("row");
        component.set("v.isLoading", true);
        component.set("v.ReviewItemRow", row);
        helper.getFiles(component);
        helper.getIsEditable(component);
        switch (action.name) {
            case 'details':
                helper.showRowDetails(component, event, helper);
                break;
        }
    },

    saveRowDetails : function(component, event, helper) {
        //component.find("edit").get("e.recordSave").fire();
        helper.saveRow(component);
    },

    submitRowDetails : function(component, event, helper) {
        if (confirm("After submitting this review item you may not be able to make additional updates.")) {
            component.set("v.ReviewItemRow.Finished__c", true);
           // component.find("edit").get("e.recordSave").fire();
           helper.saveRow(component);
        }
    },

    saveRowDetailsSuccess : function(component, event, helper) {
        component.set("v.showDetail", false);
        var finished = component.get("v.ReviewItemRow.Finished__c");
        // if this was just a save, we can send the data change
        //  event straight away so the list is refreshed
        if (!finished) {
            var appEvent = $A.get("e.c:ReviewItemsDataChange");
            appEvent.fire();
        }
        // if this was a submit, mark the record finished first
        //  before sending the data change event so the refreshed
        //  list includes the result of any field changes that
        //  happen when a record is marked finished
        else {
            var action = component.get("c.markRecordFinished");
            action.setParams({ recordId : component.get("v.ReviewItemRow.Id") });
            action.setCallback(this, function(response){
                var state = response.getState();
                if (state === "SUCCESS") {
                    var appEvent = $A.get("e.c:ReviewItemsDataChange");
                    appEvent.fire();
                }
            });
            $A.enqueueAction(action);
        }
    },

    hideRowDetails : function(component, event, helper) { 
        component.set("v.showDetail", false);
    },

    onUploadFinished : function(component, event, helper) {
        helper.getFiles(component);
    },
    showValues : function(component, event, helper) { 
        console.log("showw");
        var optionsDiv = component.find("optionsDiv");
        $A.util.removeClass(optionsDiv, "slds-hide");
        $A.util.addClass(optionsDiv, "slds-show");
    },
    hideValues: function(component, event, helper) { 
        var optionsDiv = component.find("optionsDiv");
        $A.util.removeClass(optionsDiv, "slds-show");
        $A.util.addClass(optionsDiv, "slds-hide");
    },
    selectCategory: function(component, event, helper) { 
        //alert("You selected: " + event.target.dataset.num);
        if (event.target.dataset.num=="CloseCatList"){
            var optionsDiv = component.find("optionsDiv");
            $A.util.removeClass(optionsDiv, "slds-show");
            $A.util.addClass(optionsDiv, "slds-hide");
        } else {
        	component.set("v.ReviewItemRow.Item_Category__c", event.target.dataset.num);
        }
        var optionsDiv = component.find("optionsDiv");
        $A.util.removeClass(optionsDiv, "slds-show");
        $A.util.addClass(optionsDiv, "slds-hide");
    }
})