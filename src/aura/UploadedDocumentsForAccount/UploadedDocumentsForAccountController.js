({
    doInit: function (component, event, helper) {
        var action = component.get("c.isCommunity");
        action.setCallback(this, function (response) {
            component.set("v.IsCommunity", response.getReturnValue());
        });
        $A.enqueueAction(action);



        console.log(component.get("v.recordId"));

        if (component.get("v.recordId") == null) {
            var querystring = location.search.substr(1);
            var paramValue = {};
            querystring.split("&").forEach(function (part) {
                var param = part.split("=");
                paramValue[param[0]] = decodeURIComponent(param[1]);
            });

            console.log(paramValue.id);
            if (paramValue.id != null) {
                console.log('SET ID ----');
                component.set("v.recordId", paramValue.id);
                var a = component.get('c.prepareStartValues');
                $A.enqueueAction(a);
            } else {
                action = component.get("c.getCommunityAccId");
                action.setCallback(this, function (response) {
                    console.log(response.getReturnValue());
                    component.set("v.recordId", response.getReturnValue());
                    var a = component.get('c.prepareStartValues');
                    $A.enqueueAction(a);
                });
                $A.enqueueAction(action);
            }


        } else {
            var a = component.get('c.prepareStartValues');
            $A.enqueueAction(a);
        }



    },

    prepareStartValues: function (component, event, helper) {
        var action = component.get("c.getAccNameById");

        action.setParams({ recordId: component.get("v.recordId") });
        action.setCallback(this, function (response) {
            component.set("v.recordName", response.getReturnValue().split('-del-')[1]);
            component.set("v.AccRecordId", response.getReturnValue().split('-del-')[0]);
        });
        $A.enqueueAction(action);


        window.addEventListener("message", function (event) {
            try {
                if (event.data.includes('showFilePreview')) {
                    console.log(event.data);
                    $A.get('e.lightning:openFiles').fire({
                        recordIds: [event.data.split('-del-')[1]]
                    });
                } else if (event.data.includes('openUploadWindow')) {

                    console.log(event.data.split('-del-')[1]);
                    component.set("v.defaultOptions", null);
                    component.set("v.ReviewItemFiles", null);
                    var cmpTarget = component.find('Modalbox');
                    var cmpBack = component.find('Modalbackdrop');
                    $A.util.addClass(cmpTarget, 'slds-fade-in-open');
                    $A.util.addClass(cmpBack, 'slds-backdrop--open');
                    var action = component.get("c.createNewRec");
                    action.setCallback(this, function (response) {
                        var state = response.getState();
                        if (state === "SUCCESS") {
                            component.set("v.Document.Id", response.getReturnValue());
                            if (event.data.split('-del-')[1] != null && event.data.split('-del-')[1] != '') {
                                //console.log(event.data.split('-del-'));
                                var action2 = component.get("c.setTagsVF");
                                action2.setParams({ docHid: response.getReturnValue(), tags: event.data.split('-del-')[1].split(',') });
                                action2.setCallback(this, function (response) {
                                    var state = response.getState();
                                    if (component.isValid() && state == 'SUCCESS') {
                                        var a = component.get('c.chageViewToUpload');
                                        $A.enqueueAction(a);
                                    }
                                });
                                $A.enqueueAction(action2);
                            }
                        }
                    });
                    $A.enqueueAction(action);

                } else if (event.data.includes('setFileParent')) {
                    console.log(event.data);
                    var fileId = event.data.split('-del-')[1];
                    var parentFolder = event.data.split('-del-')[2];
                    if (fileId == 'Opportunities' || fileId == 'Contacts' || fileId == 'Board_Meetings__r' || fileId == 'Documents') {
                        component.set("v.customRecordId", null);
                        component.set("v.customRecordType", null);
                        component.set("v.customRecordName", ' Account ' + component.get("v.recordName"));
                    } else {
                        if (parentFolder == '0') {
                            component.set("v.customRecordId", null);
                            component.set("v.customRecordType", null);
                            component.set("v.customRecordName", ' Account ' + component.get("v.recordName"));
                        } else {
                            component.set("v.customRecordId", fileId);
                            component.set("v.customRecordType", parentFolder);
                            if (parentFolder == 'Contacts') {
                                component.set("v.customRecordName", ' Contact ' + event.data.split('-del-')[3]);
                            } else if (parentFolder == 'Opportunities') {
                                component.set("v.customRecordName", ' Opportunity ' + event.data.split('-del-')[3]);
                            } else if (parentFolder == 'Board_Meetings__r') {
                                component.set("v.customRecordName", ' Board Meeting ' + event.data.split('-del-')[3]);
                            } else if (parentFolder == 'Documents') {
                                component.set("v.customRecordName", ' Document Folder ' + event.data.split('-del-')[3]);
                            }
                        }
                    }

                } else if (event.data.includes('setBaseUrl')) {
                    component.set("v.BaseUrl", event.data.split('-del-')[1]);
                } else if (event.data.includes('setSelectedRow')) {
                    var updateLookup = $A.get("e.c:DHTMLXgridRowSelect");
                    updateLookup.setParams({ "docId": event.data.split('-del-')[1] });
                    updateLookup.fire();
                }
            } catch (e) { }
        }, false);
    },
    onUploadFinished: function (component, event, helper) {
        component.set("v.ReviewItemFiles", null);
        var action = component.get("c.getFileRecords");
        action.setParams({ parentId: component.get("v.Document.Id") });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.ReviewItemFiles", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },

    saveRecord: function (component, event, helper) {
        var record = component.get("v.Document");
        var riFiles = component.get("v.ReviewItemFiles");
        if (riFiles == null) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title: 'Error',
                message: 'Please, attach documents.',
                type: 'error',
                mode: 'pester'
            });
            toastEvent.fire();
        } else {
            if (component.get("v.customRecordId") == null) {
                component.set("v.Document.Account__c", component.get("v.AccRecordId"));
                component.set("v.Document.Board_Meeting__c", null);
                component.set("v.Document.Opportunity__c", null);
                component.set("v.Document.Contact__c", null);
                component.set("v.Document.Documents_Folder_Template__c", null);
            } else if (component.get("v.customRecordType") == 'Opportunities') {
                component.set("v.Document.Opportunity__c", component.get("v.customRecordId"));
                component.set("v.Document.Board_Meeting__c", null);
                component.set("v.Document.Account__c", null);
                component.set("v.Document.Contact__c", null);
                component.set("v.Document.Documents_Folder_Template__c", null);
            } else if (component.get("v.customRecordType") == 'Contacts') {
                component.set("v.Document.Contact__c", component.get("v.customRecordId"));
                component.set("v.Document.Board_Meeting__c", null);
                component.set("v.Document.Account__c", null);
                component.set("v.Document.Opportunity__c", null);
                component.set("v.Document.Documents_Folder_Template__c", null);
            } else if (component.get("v.customRecordType") == 'Board_Meetings__r') {
                component.set("v.Document.Board_Meeting__c", component.get("v.customRecordId"));
                component.set("v.Document.Contact__c", null);
                component.set("v.Document.Account__c", null);
                component.set("v.Document.Opportunity__c", null);
                component.set("v.Document.Documents_Folder_Template__c", null);
            } else if (component.get("v.customRecordType") == 'Documents') {
                component.set("v.Document.Documents_Folder_Template__c", component.get("v.customRecordId"));
                component.set("v.Document.Board_Meeting__c", null);
                component.set("v.Document.Contact__c", null);
                component.set("v.Document.Account__c", component.get("v.AccRecordId"));
                component.set("v.Document.Opportunity__c", null);
            }

            var action = component.get("c.saveRecordContr");
            action.setParams({ rec: JSON.stringify(component.get("v.Document")) });
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (component.isValid() && state == 'SUCCESS') {
                    //document.getElementById('vfFrame').src = document.getElementById('vfFrame').src;
                    console.log(component.get("v.BaseUrl"));
                    console.log(component.get("v.recordId"));

                    try {
                        var vfWindow = component.find("vfFrame").getElement().contentWindow;
                        vfWindow.postMessage('RefreshGrid', component.get("v.BaseUrl") + 'apex/UploadedDocumentsForAccount?recordId=' + component.get("v.recordId"));
                    } catch (e) {
                        var vfWindow = document.getElementById("vfFrame").contentWindow;
                        vfWindow.postMessage('RefreshGrid', component.get("v.BaseUrl"));
                    }

                    console.log('1');




                    var cmpTarget = component.find('Modalbox');
                    var cmpBack = component.find('Modalbackdrop');
                    $A.util.removeClass(cmpBack, 'slds-backdrop--open');
                    $A.util.removeClass(cmpTarget, 'slds-fade-in-open');
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
        }
    },
    chageViewToUpload: function (component, event, helper) {

        var action = component.get("c.getTags");
        action.setParams({ docHid: component.get("v.Document.Id") });

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (component.isValid() && state == 'SUCCESS') {
                var resultArray = response.getReturnValue();
                var options2 = [];
                if (resultArray != null) {
                    var res = resultArray;
                    console.log(res);
                    for (var i = 0; i < res.length; i++) {
                        var tName = res[i].Tag__r.Name;
                        if (res[i].Tag__r.ParentTag__c != null) {
                            tName = res[i].Tag__r.ParentTag__r.Name + ':' + tName;

                            if (res[i].Tag__r.ParentTag__r.ParentTag__c != null) {
                                tName = res[i].Tag__r.ParentTag__r.ParentTag__r.Name + ':' + tName;
                            }
                        }

                        options2.push({ value: res[i].Id, label: tName });
                    }
                }
                component.set("v.defaultOptions", options2);

            } else {
                console.log('Failed with state: ' + state);
            }
        });
        $A.enqueueAction(action);

        component.set("v.uploadView", 'uploadView');
    },
    chageViewToEditTags: function (component, event, helper) {
        component.set("v.uploadView", 'tagEditView');
    },
    chageViewToTags: function (component, event, helper) {
        component.set("v.uploadView", 'tagView');
    },
    handleRemove: function (component, event) {
        console.log(event.getSource().get('v.name'));

        var action = component.get("c.removeDocHelperTagAssoc");

        action.setParams({ dhTagAssocid: event.getSource().get('v.name') });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (component.isValid() && state == 'SUCCESS') {
                var pills = component.get('v.defaultOptions');

                for (var i = 0; i < pills.length; i++) {
                    if (event.getSource().get('v.name') === pills[i].value) {
                        pills.splice(i, 1);
                        break;
                    }
                }

                component.set('v.defaultOptions', pills);
            }
        });
        $A.enqueueAction(action);

    },

    addNewTag: function (component, event, helper) {
        var newTagVal = component.get("v.NewTagValue");
        if (newTagVal != '') {
            console.log(newTagVal);

            var opt = [];
            opt = component.get("v.defaultOptions");
            var opt2 = [];
            opt2 = component.get("v.listOptions");
            var isDupl = false;

            for (var i = 0; i < opt2.length; i++) {
                if (opt2[i].value == newTagVal) {
                    isDupl = true;
                }
            }

            if (!opt.includes(newTagVal)) {
                opt.push(newTagVal);
            }

            if (!opt2.includes(newTagVal)) {
                opt2.push({ value: newTagVal, label: newTagVal });
            }

            if (isDupl) {
                newTagVal = '';
            }
            var action = component.get("c.setTags");
            action.setParams({ docHid: component.get("v.Document.Id"), tags: opt, newTag: newTagVal });
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (component.isValid() && state == 'SUCCESS') {

                    component.set("v.defaultOptions", opt);
                    component.set("v.listOptions", opt2);
                    component.set("v.NewTagValue", '');
                }
            });
            $A.enqueueAction(action);

        }
    },

    closeModal: function (component, event, helper) {

        var action = component.get("c.DeleteRec");
        action.setParams({ recId: component.get("v.Document.Id") });
        action.setCallback(this, function (response) {
            component.set("v.Document.Id", '');
        });
        $A.enqueueAction(action);

        var cmpTarget = component.find('Modalbox');
        var cmpBack = component.find('Modalbackdrop');
        $A.util.removeClass(cmpBack, 'slds-backdrop--open');
        $A.util.removeClass(cmpTarget, 'slds-fade-in-open');
    },
    openmodal: function (component, event, helper) {


        component.set("v.defaultOptions", null);
        component.set("v.ReviewItemFiles", null);
        var action = component.get("c.createNewRec");
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.Document.Id", response.getReturnValue());

                var cmpTarget = component.find('Modalbox');
                var cmpBack = component.find('Modalbackdrop');
                $A.util.addClass(cmpTarget, 'slds-fade-in-open');
                $A.util.addClass(cmpBack, 'slds-backdrop--open');
            }
        });
        $A.enqueueAction(action);
    },
    closeModel: function (component, event, helper) {
        component.set("v.isOpen", false);
    }

})