({
    doInit: function (component, event, helper) {
        console.log('init');
        window.addEventListener("message", function (event) {
            try {
                var pass_data = JSON.parse(event.data);
                console.log(pass_data);
                if (pass_data.func)
                    if (pass_data.func == 'link') {
                        helper.openLinkPopup(component, event, pass_data.RIid, pass_data.RIName, pass_data.highlightedDoc);
                    } else if (pass_data.func == 'edit') {
                        helper.openEditPopup(component, event, pass_data.RIid);
                    } else if (pass_data.func == 'setBaseUrl') {
                        component.set("v.BaseUrl", pass_data.RIid);
                    } else if (pass_data.func == 'showFilePrevRI') {
                        $A.get('e.lightning:openFiles').fire({
                            recordIds: [pass_data.RIid]
                        });
                    } else if (pass_data.func == 'fakeCall') {
                        helper.fakeCall(component, event);
                    } else if (pass_data.func == 'setDDNameLabel') {
                        component.set("v.DDLabel", pass_data.RIid);
                    } else if (pass_data.func == 'openNewRICreatingPopup') {
                        var createRecordEvent = $A.get("e.force:createRecord");
                        createRecordEvent.setParams({
                            "entityApiName": "review_item__c",
                            "defaultFieldValues": {
                                "Assessment__c": pass_data.RIid
                            },
                            "navigationLocation": "RELATED_LIST"
                        });
                        createRecordEvent.fire();
                    } else if (pass_data.func == 'navigateTo') {
                        var navEvt = $A.get("e.force:navigateToSObject");
                        navEvt.setParams({
                            "recordId": pass_data.RIid,
                            "slideDevName": "detail"
                        });
                        navEvt.fire();
                    } else if (pass_data.func == 'showNewDDpopup') {
                        helper.showDD(component);
                    }
            } catch (e) { }
        });

        if (component.get("v.ShowDDchecklist") == 'Yes') {
            var cheight = parseInt(component.get("v.componentHeight"));
            component.set("v.componentHeight", cheight + 400);
        }

        component.set("v.isCreateable", false);
        var action = component.get("c.getInitValuesWrapper");
        action.setParams({
            "recId": component.get("v.recordId")
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if (component.get("v.communityName") != null) {
                    component.set("v.isCreateable", false);
                } else {
                    component.set("v.isCreateable", response.getReturnValue().isCreateable);
                }
                component.set("v.accId", response.getReturnValue().accId);
                component.set("v.ddId", response.getReturnValue().ddId);
                component.set("v.acctList", response.getReturnValue().availableAccs);
                component.set("v.IsExternalGrader", response.getReturnValue().IsExternalGrader);

                console.log(response.getReturnValue());
            }
        });
        $A.enqueueAction(action);

        component.set('v.selectAccsColumns', [
            { label: 'Account Name', fieldName: 'Name', type: 'text' },
            { label: 'Website', fieldName: 'Website', type: 'url ' },
            { label: 'Phone', fieldName: 'Phone', type: 'Phone' }
        ]);




    },

    updateRecId: function (component, event) {
        var selectedRows = event.getParam('selectedRows');
        // Display that fieldName of the selected rows
        for (var i = 0; i < selectedRows.length; i++) {
            //alert("You selected: " + selectedRows[i].Id);
            component.set("v.accId", selectedRows[i].Id);
            component.set("v.ddId", '');
        }
    },

    handleFiles: function (component, event, helper) {

        var fileInput = component.find("dealCsv").getElement();

        var file = fileInput.files[0];
        if (file) {
            var reader = new FileReader();
            reader.readAsText(file, "UTF-8");
            reader.onload = function (evt) {
                console.log(evt.target.result);
                var fileContents = evt.target.result;
                if (!fileContents || fileContents == '') {
                    alert('File is empty, please, select correct csv file.');
                } else {
                    let parsedata = [];

                    let newLinebrk = fileContents.split("\n");
                    for (let i = 0; i < newLinebrk.length; i++) {
                        var spl = new RegExp(',(?![^"]*"(?:(?:[^"]*"){2})*[^"]*$)');
                        var line = newLinebrk[i].split(spl);
                        console.log(line);
                        if (line.length > 1)
                            parsedata.push(newLinebrk[i].split(spl));
                        //slice(0, -1)
                    }
                    console.table(parsedata);

                    var idPos, submCommPos, revCommPos;

                    for (let i = 0; i < parsedata[0].length; i++) {

                        var currVal = parsedata[0][i].replace(/\s*$/, '');
                        if (currVal == 'Id') idPos = i;
                        if (currVal == 'Submitter Comments') submCommPos = i;
                        if (currVal == 'Internal Review Comments') revCommPos = i;
                    }
                    var idPos, submCommPos, revCommPos;
                    console.log(idPos + ' ' + submCommPos + ' ' + revCommPos);

                    if (idPos == null || submCommPos == null || revCommPos == null) {
                        alert('File is not correct, It must include Id, Submitter Comments and Internal Review Comments columns');
                        return;
                    }
                    var RIlist = [];
                    for (let i = 1; i < parsedata.length; i++) {
                        if (parsedata[i][idPos] != '') {
                            var ri = {};
                            ri.Id = parsedata[i][idPos];
                            ri.Item_Comments__c = parsedata[i][submCommPos] ? parsedata[i][submCommPos].trim().replace(/^"|"$/g, '') : '';
                            ri.Reviewer_Comments__c = parsedata[i][revCommPos] ? parsedata[i][revCommPos].trim().replace(/^"|"$/g, '') : '';
                            RIlist.push(ri);
                        }
                    }
                    console.log(RIlist);

                    var action = component.get("c.updateReviewItems");
                    action.setParams({
                        "riList": RIlist
                    });
                    action.setCallback(this, function (response) {
                        var state = response.getState();
                        if (state === "SUCCESS") {

                            if (response.getReturnValue() != '') {
                                let errorMessage = 'Upload CSV failed. Unable to import row(s) ' + response.getReturnValue() + '. Please check the data and try importing again';
                                var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    "title": "Error!",
                                    "type": "error",
                                    "message": errorMessage,
                                    "duration": 5000
                                });
                                toastEvent.fire();
                            } else {
                                var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    "title": "Success!",
                                    "type": "success",
                                    "message": "Review Items has been updated successfully."
                                });
                                toastEvent.fire();
                            }
                        } else {
                            let errors = response.getError();
                            let message = 'Unknown error'; // Default error message
                            // Retrieve the error message sent by the server
                            if (errors && Array.isArray(errors) && errors.length > 0) {
                                message = errors[0].message;
                            }
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Error!",
                                "type": "error",
                                "message": message,
                                "duration": 5000
                            });
                            toastEvent.fire();
                        }
                        if (component.get("v.inpFile") == null) {//workaround to make work onchange after selecting the same file
                            component.set("v.inpFile", '');
                        } else {
                            component.set("v.inpFile", null);
                        }

                    });
                    $A.getCallback(function () {
                        $A.enqueueAction(action);
                    })();

                }

            }


            reader.onerror = function (evt) {
                console.log("error reading file");
            }
        }
    },

    changeViewStyle: function (component, event, helper) {
        var pass_data = { 'func': 'changeViewStyle', 'style': component.get("v.mode") };

        try {
            var vfWindow = component.find("ariFrame").getElement().contentWindow;
            vfWindow.postMessage(JSON.stringify(pass_data), component.get("v.BaseUrl"));
        } catch (e) {
            var vfWindow = document.getElementById("ariFrame").contentWindow;
            vfWindow.postMessage(JSON.stringify(pass_data), component.get("v.BaseUrl"));
        }

    },
    sendUpdateAllTemplates: function (component, event, helper) {
        var pass_data = { 'func': 'sendUpdateAllTemplates' };

        try {
            var vfWindow = component.find("ariFrame").getElement().contentWindow;
            vfWindow.postMessage(JSON.stringify(pass_data), component.get("v.BaseUrl"));
        } catch (e) {
            var vfWindow = document.getElementById("ariFrame").contentWindow;
            vfWindow.postMessage(JSON.stringify(pass_data), component.get("v.BaseUrl"));
        }

    },
    sendDownloadCSV: function (component, event, helper) {
        var pass_data = { 'func': 'DownloadCSV' };

        try {
            var vfWindow = component.find("ariFrame").getElement().contentWindow;
            vfWindow.postMessage(JSON.stringify(pass_data), component.get("v.BaseUrl"));
        } catch (e) {
            var vfWindow = document.getElementById("ariFrame").contentWindow;
            vfWindow.postMessage(JSON.stringify(pass_data), component.get("v.BaseUrl"));
        }

    },
    sendUploadCSV: function (component, event, helper) {
        var pass_data = { 'func': 'UploadCSV' };

        try {
            var vfWindow = component.find("ariFrame").getElement().contentWindow;
            vfWindow.postMessage(JSON.stringify(pass_data), component.get("v.BaseUrl"));
        } catch (e) {
            var vfWindow = document.getElementById("ariFrame").contentWindow;
            vfWindow.postMessage(JSON.stringify(pass_data), component.get("v.BaseUrl"));
        }

    },
    sendRefreshDD: function (component, event, helper) {
        var pass_data = { 'func': 'updateDDGrid' };

        try {
            var vfWindow = component.find("ariFrame").getElement().contentWindow;
            vfWindow.postMessage(JSON.stringify(pass_data), component.get("v.BaseUrl"));
        } catch (e) {
            var vfWindow = document.getElementById("ariFrame").contentWindow;
            vfWindow.postMessage(JSON.stringify(pass_data), component.get("v.BaseUrl"));
        }

    },
    checkChanges: function (component, event, helper) {
        var pass_data = { 'func': 'checkChangesBeforeShowingPopup' };

        try {
            var vfWindow = component.find("ariFrame").getElement().contentWindow;
            vfWindow.postMessage(JSON.stringify(pass_data), component.get("v.BaseUrl"));
        } catch (e) {
            var vfWindow = document.getElementById("ariFrame").contentWindow;
            vfWindow.postMessage(JSON.stringify(pass_data), component.get("v.BaseUrl"));
        }
    }

})