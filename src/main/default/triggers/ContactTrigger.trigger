trigger ContactTrigger on Contact (after update) {
    switch on Trigger.operationType {
        when AFTER_UPDATE {
            // copy contact details (phone & email) from contact to all accounts
            // (where the updated contact was set as primary)
            ContactTriggerHandler.copyContactDetailsToRelatedAccounts(Trigger.new, Trigger.old);
        }
    }
}