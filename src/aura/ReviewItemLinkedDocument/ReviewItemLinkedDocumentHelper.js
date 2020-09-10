({
    doInit: function (cmp) {
        console.log('@@@@@@@@@@inDoInit');
        var recordId = cmp.get('v.recordId');
        console.log(recordId);
        var action = cmp.get("c.getLinkedDocuments");
        action.setParams({
            recordId: recordId,
            serchCondition: cmp.get('v.serchCondition')
        });

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var resp = response.getReturnValue();

                console.log(resp);
                var documentList = [];
                for (let doc of resp) {
                    var document = { Title: doc.Name__c, Tag: "", Notes: "" };
                    for (let jud of doc.Junctions_Document_ReviewItem__r) {
                        if (jud.Notes__c != undefined) {
                            document.Notes += jud.Notes__c.replace(/<[^>]*>?/gm, '');
                        }
                        document.JunctionsId = jud.Id;
                    }
                    if (doc.TagDocumentAssociations__r)
                        for (let tag of doc.TagDocumentAssociations__r) {
                            document.Tag += tag.Tag__r.Name + "; ";
                        }
                    documentList.push(document);
                }
                console.log(documentList);
                cmp.set('v.data', documentList);
            } else if (state === "ERROR") {
                console.log('ERROR');
                var errors = response.getError();
                console.log(errors);
                console.log(errors[0]);
                this.showErrorToast(component, errors[0].message);
            }
        });
        $A.enqueueAction(action);
    },
    addDocument: function (cmp, hlp) {

        var modalBody;

        $A.createComponent("c:ReviewItemLinkDocument", { recordId: cmp.get('v.recordId') },
            function (content, status) {
                console.log(status);
                if (status === "SUCCESS") {
                    modalBody = content;
                    cmp.find('overlayLib').showCustomModal({
                        header: "Link Documents",
                        body: modalBody,
                        showCloseButton: true,
                        cssClass: "mymodal",
                        closeCallback: function () {
                            console.log('@@@@@@@@@@@@@@@@@@@@@@@');
                            hlp.doInit(cmp);
                        }
                    })
                }

            });
    },
    remove: function (cmp, evt) {
        var action = evt.getParam('action');
        var row = evt.getParam('row');
        var action = cmp.get("c.removeJunctionObjectById");
        action.setParams({ recordId: row.JunctionsId });

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var data = cmp.get('v.data');
                var newData = [];
                for (let d of data) {
                    if (d.JunctionsId != row.JunctionsId) {
                        newData.push(d);
                    }
                }
                cmp.set('v.data', newData);
            } else if (state === "ERROR") {
                console.log('ERROR');
                var errors = response.getError();
                console.log(errors);
                console.log(errors[0]);
                this.showErrorToast(component, errors[0].message);
            }
        });
        $A.enqueueAction(action);
    }

})