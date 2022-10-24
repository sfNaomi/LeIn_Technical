/**
 * Created by magdalena.stanciu on 03.09.2022.
 */

trigger AccountTrigger on Account(before insert, before update, after update, after insert) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            AccountTriggerHandler.copyContactDetailsFromPrimaryContact(Trigger.new, null);
            AccountTriggerHandler.assignDefaultPriceBook(Trigger.new);
            AccountTriggerHandler.pullInfoOnDPFromRelatedCustomer(Trigger.new, null);
            AccountTriggerHandler.populateDefaultInventory(Trigger.new, null);
        }
        when BEFORE_UPDATE {
            AccountTriggerHandler.copyContactDetailsFromPrimaryContact(Trigger.new, Trigger.old);
            AccountTriggerHandler.pullInfoOnDPFromRelatedCustomer(Trigger.new, Trigger.oldMap);
            AccountTriggerHandler.populateDefaultInventory(Trigger.new, Trigger.oldMap);
        }
        when AFTER_INSERT {
            AccountTriggerHandler.manageFocusProducts(Trigger.newMap);
        }
        when AFTER_UPDATE {
            AccountTriggerHandler.manageReoccurrenceRecord(Trigger.new, Trigger.oldMap);
            AccountTriggerHandler.manageAccountTeamMembership(Trigger.new, Trigger.oldMap);
            AccountTriggerHandler.pushInfoFromCustomerToRelatedDPs(Trigger.new, Trigger.oldMap);
        }
    }
}