trigger ContactTrigger on Contact (before insert, after insert, before update, after update) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            // validation: only one contact can be marked as primary for an existing account
            ContactTriggerHandler.validateUniquePrimaryContactForParentAccount(Trigger.new);
        }
        when AFTER_INSERT {
            // automation: update primary contact on parent account
            ContactTriggerHandler.updatePrimaryContactOnParentAccount(Trigger.new);
        }
        when BEFORE_UPDATE {
            // validation: only one contact can be marked as primary for an existing account
            ContactTriggerHandler.validateUniquePrimaryContactForParentAccount(Trigger.new, Trigger.old);
        }
        when AFTER_UPDATE {
            // automation: update primary contact on parent account
            ContactTriggerHandler.updatePrimaryContactOnParentAccount(Trigger.new, Trigger.old);
        }
    }
}