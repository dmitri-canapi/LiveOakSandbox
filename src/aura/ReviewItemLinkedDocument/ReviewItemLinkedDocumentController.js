({
	doInit : function(cmp, evt, hlp) {
		//alert(cmp.get('v.recordId'));
		 console.log('Init');
		cmp.set('v.columns', [
            {label: 'Title', fieldName: 'Title', type: 'text'},
            {label: 'Tags', fieldName: 'Tag', type: 'text'},
            {label: 'Notes', fieldName: 'Notes', type: 'text'},
             {label: 'Remove', type: 'button', initialWidth: 135, typeAttributes: { label: 'Delete', name: 'Remove', iconName: 'utility:delete', title: 'Click to View Details'}}
        ]);
        hlp.doInit(cmp);
	},
    
    AddDocument  : function(cmp, evt, hlp) {
        hlp.addDocument(cmp,hlp);
    },
    
    remove : function(cmp, evt, hlp) {
        hlp.remove(cmp,evt);
    },
})