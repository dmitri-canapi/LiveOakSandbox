({
    activateTab : function(component, event, helper){
        var appEvent = $A.get("e.c:ReviewItemsTabClick");
        appEvent.setParams({ title : event.currentTarget.title });
        appEvent.fire();
    },

    handleTabClick : function(component, event){
        var clickedTabTitle = event.getParam("title");
        var thisTabTitle = component.get("v.title");
        var tabli = component.find("tabli");

        if (clickedTabTitle == thisTabTitle) {
            $A.util.removeClass(tabli, "is-inactive");
            $A.util.addClass(tabli, "slds-is-active");
            
        }
        else {
            $A.util.removeClass(tabli, "slds-is-active");
            $A.util.addClass(tabli, "is-inactive");
        }
    }
})