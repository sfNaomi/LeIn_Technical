/**
 * Created by magdalena.stanciu on 23.11.2022.
 */

trigger OrderItemTrigger on OrderItem (before insert, before update, after insert, after update, after delete) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            OrderItemTriggerHandler.calculateVatOnOrderItemLevel(Trigger.new, null);
        }
        when BEFORE_UPDATE {
            OrderItemTriggerHandler.calculateVatOnOrderItemLevel(Trigger.new, Trigger.oldMap);
        }
        when AFTER_INSERT {
            OrderItemTriggerHandler.calculateVatOnOrderLevel(Trigger.newMap, Trigger.oldMap);
        }
        when AFTER_UPDATE {
            OrderItemTriggerHandler.calculateVatOnOrderLevel(Trigger.newMap, Trigger.oldMap);
        }
        when AFTER_DELETE {
            OrderItemTriggerHandler.calculateVatOnOrderLevel(Trigger.newMap, Trigger.oldMap);
        }
    }
}