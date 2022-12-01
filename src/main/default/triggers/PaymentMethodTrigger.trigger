/**
 * Created by eddy.ferreira on 14.11.2022.
 */
trigger PaymentMethodTrigger on aforza__Payment_Method__c (after insert, after update) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            PaymentMethodTriggerHandler.assignPrimaryPaymentMethodToParentAccount(Trigger.new, Trigger.oldMap);
        }
        when AFTER_UPDATE {
            PaymentMethodTriggerHandler.assignPrimaryPaymentMethodToParentAccount(Trigger.new, Trigger.oldMap);
        }
    }
}