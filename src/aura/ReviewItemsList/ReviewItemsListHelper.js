({
    getRecords : function(component) {
        var action = component.get("c.getRecordsMap");
        action.setParams({ assessmentId : component.get("v.recordId") });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var map = response.getReturnValue();
                var keys = [];
                for (var key in map) {
                    keys.push(key);
                }
                component.set("v.ReviewItemMap", map);
                component.set('v.ReviewItemMapKeys', keys);
            }
        });
        $A.enqueueAction(action);
    },

    getIsCreateable : function(component) {
        component.set("v.isCreateable", false);
        var action = component.get("c.isReviewItemCreateable");
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.isCreateable", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    }
})