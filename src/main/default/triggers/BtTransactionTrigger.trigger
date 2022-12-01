trigger BtTransactionTrigger on bt_stripe__Transaction__c (after insert, after update) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            BtTransactionTriggerHandler.createAforzaTransaction(Trigger.new);
        }
        when AFTER_UPDATE {
            BtTransactionTriggerHandler.updateInvoiceAndAforzaTransactionWhenCompleted(Trigger.new, Trigger.oldMap);
        }
    }
}