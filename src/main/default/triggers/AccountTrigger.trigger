/**
 * Created by magdalena.stanciu on 03.09.2022.
 */

trigger AccountTrigger on Account(before insert, before update, after update, after insert) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            // copy contact details (phone & email) from primary contacts to accounts
            AccountTriggerHandler.copyContactDetailsFromPrimaryContact(Trigger.new, null);
            AccountTriggerHandler.assignDefaultPriceBook(Trigger.new);
            AccountTriggerHandler.updatePORequiredStartingWithDPs(Trigger.new, Trigger.oldMap);
        }
        when BEFORE_UPDATE {
            // copy contact details (phone & email) from primary contacts to accounts
            AccountTriggerHandler.copyContactDetailsFromPrimaryContact(Trigger.new, Trigger.old);
            AccountTriggerHandler.updatePORequiredStartingWithDPs(Trigger.new, Trigger.oldMap);
        }
        when AFTER_INSERT {
            AccountTriggerHandler.manageReoccurrenceRecord(Trigger.new, Trigger.oldMap);
        }
        when AFTER_UPDATE {
            AccountTriggerHandler.manageReoccurrenceRecord(Trigger.new, Trigger.oldMap);
            AccountTriggerHandler.determineIfAccountTeamMembersMustBeRemoved(Trigger.new, Trigger.oldMap);
            AccountTriggerHandler.updatePORequiredStartingWithCustomerAccs(Trigger.new, Trigger.oldMap);
        }
    }
}
