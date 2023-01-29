/**
 * Created by eddy.ferreira on 09.11.2022.
 */
trigger BtPaymentMethodTrigger on bt_stripe__Payment_Method__c (after insert, after update) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            BtPaymentMethodTriggerHandler.createAforzaPaymentMethodFromBlackthornPaymentMethod(Trigger.new, Trigger.oldMap);
        }
        when AFTER_UPDATE {
            BtPaymentMethodTriggerHandler.createAforzaPaymentMethodFromBlackthornPaymentMethod(Trigger.new, Trigger.oldMap);
        }
    }
}