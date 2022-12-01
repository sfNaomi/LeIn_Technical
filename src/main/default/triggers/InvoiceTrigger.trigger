/**
 * Created by svatopluk.sejkora on 16.11.2022.
 */
trigger InvoiceTrigger on aforza__Invoice__c (after insert, before update, after update ) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            InvoiceTriggerHandler.createTransactions(Trigger.newMap);
        }
        when BEFORE_UPDATE {
            InvoiceTriggerHandler.updateFailedInvoices(Trigger.new, trigger.oldMap);
        }
        when AFTER_UPDATE {
            InvoiceTriggerHandler.evaluateAndSendEmailToCustomer(Trigger.new);
            InvoiceTriggerHandler.updatePaymentTransactionsForInvoices(Trigger.new, trigger.oldMap);
        }
    }
}