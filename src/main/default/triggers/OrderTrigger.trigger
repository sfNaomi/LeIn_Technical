/**
 * Created by magdalena.stanciu on 13.09.2022.
 */

trigger OrderTrigger on Order(before insert, before update, after insert, after update) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            OrderTriggerHandler.validateOrderCreation(Trigger.new, null);
        }
        when BEFORE_UPDATE {
            OrderTriggerHandler.validateOrderCreation(Trigger.new, Trigger.oldMap);
        }
        when AFTER_INSERT {
            OrderTriggerHandler.updateLastOrderDateAndStatusOnParentAccount(Trigger.new, Trigger.oldMap);
        }
        when AFTER_UPDATE {
            OrderTriggerHandler.updateLastOrderDateAndStatusOnParentAccount(Trigger.new, Trigger.oldMap);
            OrderTriggerHandler.cloneCompletedOrder(Trigger.new, Trigger.oldMap);
        }
    }
}
