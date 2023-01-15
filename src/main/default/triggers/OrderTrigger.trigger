trigger OrderTrigger on Order (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    dlrs.RollupService.triggerHandler(Order.SObjectType);
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            OrderTriggerHandler.populateLocalId(Trigger.new);
            OrderTriggerHandler.validateOrderCreationOrCompletion(Trigger.new, null);
            OrderTriggerHandler.populateDefaultInventory(Trigger.new, null);
        }
        when BEFORE_UPDATE {
            OrderTriggerHandler.validateOrderCreationOrCompletion(Trigger.new, Trigger.oldMap);
            OrderTriggerHandler.validateUpdateOfLockedOrders(Trigger.new, Trigger.oldMap);
            OrderTriggerHandler.populateDefaultInventory(Trigger.new, Trigger.oldMap);
        }
        when AFTER_INSERT {
            OrderTriggerHandler.updateLastOrderDateAndStatusOnParentAccount(Trigger.new, Trigger.oldMap);
        }
        when AFTER_UPDATE {
            OrderTriggerHandler.updateLastOrderDateAndStatusOnParentAccount(Trigger.new, Trigger.oldMap);
            OrderTriggerHandler.cloneCompletedOrder(Trigger.new, Trigger.oldMap);
            OrderTriggerHandler.createPaymentTransaction(Trigger.new, Trigger.oldMap);
            OrderTriggerHandler.createInvoice(Trigger.new, Trigger.oldMap);
            OrderTriggerHandler.populateLoadWhenAllLInkedOrdersShareStatus(Trigger.new, Trigger.oldMap);
            OrderTriggerHandler.validateAndSendDeliveryNoteEmail(Trigger.new, Trigger.oldMap);
            OrderTriggerHandler.removeOrdersFromLoad(Trigger.newMap, Trigger.oldMap);
            OrderTriggerHandler.handleOrdersCancellation(Trigger.new, Trigger.oldMap);
            new OrderRelationshipRuleValidation(Trigger.newMap);
        }
    }
}