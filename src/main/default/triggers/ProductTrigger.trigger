/**
 * Created by magdalena.stanciu on 19.09.2022.
 */

trigger ProductTrigger on Product2 (after insert, after update) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            ProductTriggerHandler.manageRelatedDRSProducts(Trigger.new, null);
            ProductTriggerHandler.manageFocusProducts(Trigger.new, Trigger.oldMap);
        }
        when AFTER_UPDATE {
            ProductTriggerHandler.manageRelatedDRSProducts(Trigger.new, Trigger.oldMap);
            ProductTriggerHandler.removeOffSaleProductsFromAssortments(Trigger.new, Trigger.oldMap);
            ProductTriggerHandler.manageFocusProducts(Trigger.new, Trigger.oldMap);
        }
    }
}