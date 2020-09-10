({
    doInit: function (component, event, helper) {
        window.addEventListener("message", function (event) {
            try {
                if (event.data.includes('setBaseUrl')) {
                    component.set("v.BaseUrl", event.data.split('-del-')[1]);
                }
            } catch (e) { }
        }, false);

        var action = component.get("c.getConfig");
        action.setCallback(this, function (response) {
            console.log(response.getReturnValue());
            console.log(component.get("v.recordId"));
            component.set("v.IsCommunity", response.getReturnValue().isCommunity);
            component.set("v.communityName", response.getReturnValue().communityName);

            $A.createComponent('c:UploadedDocumentsForAccount', {
                recordId: component.get("v.recordId"),
                isCommunity: component.get("v.IsCommunity"),
                skin: "terrace",
                communityName: component.get("v.communityName"),
                componentHeight: "400",
                highlightedDoc: component.get("v.highlightedDoc")
            }, function (uplComp, status, errorMessage) {
                //Add the new button to the body array
                if (status === "SUCCESS") {
                    uplComp.addEventHandler("c:DHTMLXgridRowSelect", function (ev) {
                        console.log(ev.getParam("docId"));
                        var pass_data = { 'func': 'rowSelect', 'id': ev.getParam("docId") };

                        try {
                            var vfWindow = component.find("riFrame").getElement().contentWindow;
                            vfWindow.postMessage(JSON.stringify(pass_data), component.get("v.BaseUrl"));
                        } catch (e) {
                            var vfWindow = document.getElementById("riFrame").contentWindow;
                            vfWindow.postMessage(JSON.stringify(pass_data), component.get("v.BaseUrl"));
                        }
                    });
                    var body = component.get("v.body");
                    body.push(uplComp);
                    component.set("v.body", body);
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                    // Show offline error
                }
                else if (status === "ERROR") {
                    console.log("Error: " + errorMessage);
                    // Show error message
                }
            }
            );


        });
        $A.enqueueAction(action);

        window.addEventListener("message", function (event) {
            if (event.data == 'CloseLightningPopupFromVF') {
                try {
                    if (component.find("overlayLib"))
                        component.find("overlayLib").notifyClose();
                } catch (e) { }
            } else if (event.data.includes('showFilePreview')) {
                var fileId = event.data.split('-del-')[1];
                $A.get('e.lightning:openFiles').fire({
                    recordIds: [fileId]
                });

            }
        }, false);
    }

})