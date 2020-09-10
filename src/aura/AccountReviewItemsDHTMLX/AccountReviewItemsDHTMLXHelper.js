({
    openLinkPopup: function (component, event, RIid, RIName, highlightedDoc) {

        var modalBody;
        $A.createComponent("c:ReviewItemLinkDocument", { recordId: RIid, highlightedDoc: highlightedDoc },
            function (content, status) {
                if (status === "SUCCESS") {
                    modalBody = content;
                    component.find('overlayLib').showCustomModal({
                        header: "Link Documents to Review Item: " + RIName.replace('&nbsp;', ''),
                        body: modalBody,
                        showCloseButton: true,
                        cssClass: "mymodal",
                        closeCallback: function () {
                            console.log('@@@@@@@@@@@@@@@@@@@@@@@');
                            //hlp.doInit(component);
                            var pass_data = { 'func': 'updateGrid' };

                            try {
                                var vfWindow = component.find("ariFrame").getElement().contentWindow;
                                vfWindow.postMessage(JSON.stringify(pass_data), component.get("v.BaseUrl"));
                            } catch (e) {
                                var vfWindow = document.getElementById("ariFrame").contentWindow;
                                vfWindow.postMessage(JSON.stringify(pass_data), component.get("v.BaseUrl"));
                            }
                        }
                    })
                }

            });
    },
    openEditPopup: function (component, event, RIid) {
        var editRecordEvent = $A.get("e.force:editRecord");
        editRecordEvent.setParams({
            "recordId": RIid
        });
        editRecordEvent.fire();
        /*var modalBody;
        $A.createComponent("c:ReviewItemEdit", { recordId: RIid },
            function (content, status) {
                if (status === "SUCCESS") {
                    modalBody = content;
                    component.find('overlayLib').showCustomModal({
                        header: "Edit Review Item",
                        body: modalBody,
                        showCloseButton: true,
                        cssClass: "mymodal",
                        closeCallback: function () {
                            console.log(component.get("v.BaseUrl"));
                            var pass_data = { 'func': 'updateGrid' };

                            try {
                                var vfWindow = component.find("ariFrame").getElement().contentWindow;
                                vfWindow.postMessage(JSON.stringify(pass_data), component.get("v.BaseUrl"));
                            } catch (e) {
                                var vfWindow = document.getElementById("ariFrame").contentWindow;
                                vfWindow.postMessage(JSON.stringify(pass_data), component.get("v.BaseUrl"));
                            }
                        }
                    })
                }

            });*/
    },
    showDD: function (component) {
        var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams({
            "entityApiName": "Assessment__c",
            "defaultFieldValues": {
                "Account__c": component.get("v.accId")
            },
            "navigationLocation": "RELATED_LIST"
        });
        /*createRecordEvent.setParams({
            "entityApiName": "review_item__c",
            "defaultFieldValues": {
                "Assessment__c": component.get("v.recordId")
            }
        });*/
        createRecordEvent.fire();
    },
    fakeCall: function (component, event) {

    }
})