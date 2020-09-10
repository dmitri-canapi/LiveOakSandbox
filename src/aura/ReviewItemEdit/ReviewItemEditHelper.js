({
    saveRow: function (component) {
        var action = component.get("c.saveRecord");
        action.setParams({ RIrec: JSON.stringify(component.get("v.ReviewItemRow")) });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (component.isValid() && state == 'SUCCESS') {
                this.closePopup(component);

            } else {
                console.log('Failed with state: ' + state);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title: 'Error',
                    message: response.getError()[0].message,
                    type: 'error',
                    mode: 'pester'
                });
                toastEvent.fire();

            }
        });
        $A.enqueueAction(action);
    },

    closePopup: function (component) {
        try {
            if (component.find("overlayLib"))
                component.find("overlayLib").notifyClose();
        } catch (e) { }
    }
})