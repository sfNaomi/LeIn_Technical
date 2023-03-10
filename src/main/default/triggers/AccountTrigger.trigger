/**
 * Created by magdalena.stanciu on 03.09.2022.
 */

trigger AccountTrigger on Account(before insert, before update, after update, after insert, before delete, after delete, after undelete) {
    dlrs.RollupService.triggerHandler();
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            AccountTriggerHandler.copyContactDetailsFromPrimaryContact(Trigger.new, null);
            AccountTriggerHandler.assignDefaultPriceBook(Trigger.new);
            AccountTriggerHandler.pullInfoOnDPFromRelatedCustomer(Trigger.new, null);
            AccountTriggerHandler.populateDefaultInventory(Trigger.new, null);
            AccountTriggerHandler.calculateAvailableCustomerCredit(Trigger.new, null);
        }
        when BEFORE_UPDATE {
            AccountTriggerHandler.copyContactDetailsFromPrimaryContact(Trigger.new, Trigger.old);
            AccountTriggerHandler.pullInfoOnDPFromRelatedCustomer(Trigger.new, Trigger.oldMap);
            AccountTriggerHandler.populateDefaultInventory(Trigger.new, Trigger.oldMap);
            AccountTriggerHandler.calculateAvailableCustomerCredit(Trigger.new, Trigger.oldMap);
        }
        when AFTER_INSERT {
            AccountTriggerHandler.manageFocusProducts(Trigger.newMap);
            AccountTriggerHandler.addPerfectScoreProducts(Trigger.new, Trigger.oldMap);
            AccountTriggerHandler.createDefaultPaymentMethodForEnglandAndScotland(Trigger.new, Trigger.oldMap);
            AforzaLabsSegmentToolAccountHandler.afterInsert(Trigger.newMap);
        }
        when AFTER_UPDATE {
            AccountTriggerHandler.manageReoccurrenceRecord(Trigger.new, Trigger.oldMap);
            AccountTriggerHandler.manageAccountTeamMembership(Trigger.new, Trigger.oldMap);
            AccountTriggerHandler.pushInfoFromCustomerToRelatedDPs(Trigger.new, Trigger.oldMap);
            AccountTriggerHandler.addPerfectScoreProducts(Trigger.new, Trigger.oldMap);
            AforzaLabsSegmentToolAccountHandler.afterUpdate(Trigger.New, Trigger.Old);
        }
        when BEFORE_DELETE {
            AforzaLabsSegmentToolAccountHandler.beforeDelete(Trigger.oldMap);
        }
    }
}