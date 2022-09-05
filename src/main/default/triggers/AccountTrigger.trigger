/**
 * Created by magdalena.stanciu on 03.09.2022.
 */

trigger AccountTrigger on Account (before insert, before update) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            // copy contact details (phone & email) from primary contacts to accounts
            AccountTriggerHandler.copyContactDetailsFromPrimaryContact(Trigger.new);
        }
        when BEFORE_UPDATE {
            // copy contact details (phone & email) from primary contacts to accounts
            AccountTriggerHandler.copyContactDetailsFromPrimaryContact(Trigger.new, Trigger.old);
        }
    }
}