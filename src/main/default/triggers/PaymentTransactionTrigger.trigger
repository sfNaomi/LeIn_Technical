/**
 * Created by eddy.ferreira on 04.10.2022.
 */
trigger PaymentTransactionTrigger on aforza__Payment_Transaction__c (after insert, after update) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            PaymentTransactionTriggerHandler.setParentOrderAndAccountStatusesOnPaymentTransactionCreationOrUpdate(Trigger.new, Trigger.oldMap);
        }
        when AFTER_UPDATE {
            PaymentTransactionTriggerHandler.setParentOrderAndAccountStatusesOnPaymentTransactionCreationOrUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}