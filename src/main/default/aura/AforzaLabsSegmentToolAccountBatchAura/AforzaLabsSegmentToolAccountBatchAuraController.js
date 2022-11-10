({
    doInit: function(cmp) {
       var action = cmp.get("c.runBatch");
       action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
            }else if (state === "ERROR") {
            }
        });
        $A.enqueueAction(action);
      
       var dismissActionPanel = $A.get("e.force:closeQuickAction");
       dismissActionPanel.fire();
    }
})