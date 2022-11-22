/**
 * Created by svatopluk.sejkora on 16.11.2022.
 */
trigger InvoiceTrigger on aforza__Invoice__c (after insert, after update ) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            InvoiceTriggerHandler.createTransactions(Trigger.newMap);
        }
        when AFTER_UPDATE {
            InvoiceTriggerHandler.evaluateAndSendEmailToCustomer(Trigger.new);
        }
    }
}