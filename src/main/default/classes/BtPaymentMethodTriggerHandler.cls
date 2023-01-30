/**
 * Created by eddy.ferreira on 09.11.2022.
 */

public with sharing class BtPaymentMethodTriggerHandler {

    /**
     * @description method to create an aforza payment Method if Account field is populated on BT Payment Method. As
     * account is required field on Aforza Payment Method
     *
     * @param newBtPaymentMethods new or updated List<bt_stripe__Payment_Method__c>
     * @param oldPaymentMethods old payments
     *
     * @author Eddy Ferreira
     * @date 2022-11-11
     */
    public static void createAforzaPaymentMethodFromBlackthornPaymentMethod(List<bt_stripe__Payment_Method__c> newBtPaymentMethods, Map<Id, bt_stripe__Payment_Method__c> oldPaymentMethods) {
        List<aforza__Payment_Method__c> aforzaPaymentMethodsToCreate = new List<aforza__Payment_Method__c>();
        for (bt_stripe__Payment_Method__c newBtPaymentMethod : newBtPaymentMethods) {
            if (newBtPaymentMethod.bt_stripe__Account__c != null && (oldPaymentMethods == null || oldPaymentMethods.get(newBtPaymentMethod.Id).bt_stripe__Account__c == null)) {
                aforzaPaymentMethodsToCreate.add(mapNewAforzaPaymentMethodRecordFields(newBtPaymentMethod));
            }
        }

        insert aforzaPaymentMethodsToCreate;
    }

    private static aforza__Payment_Method__c mapNewAforzaPaymentMethodRecordFields(bt_stripe__Payment_Method__c btPaymentMethod) {
        aforza__Payment_Method__c newAforzaPaymentMethod = new aforza__Payment_Method__c();
        newAforzaPaymentMethod.RecordTypeId = RecordTypes.PAYMENT_METHOD_CREDIT_CARD_ID;
        newAforzaPaymentMethod.aforza__Account__c = btPaymentMethod.bt_stripe__Account__c;
        newAforzaPaymentMethod.BtPaymentMethod__c = btPaymentMethod.Id;
        newAforzaPaymentMethod.aforza__Active__c = true;
        newAforzaPaymentMethod.aforza__Primary__c = true;
        newAforzaPaymentMethod.aforza__Payment_Card_Type__c = btPaymentMethod.bt_stripe__Brand__c;
        newAforzaPaymentMethod.aforza__Payment_Card_Holder_Name__c = btPaymentMethod.bt_stripe__Card_Holder_Name__c;
        newAforzaPaymentMethod.aforza__Payment_Card_Expiration_Month__c = btPaymentMethod.bt_stripe__Card_Expiration_Month__c;
        newAforzaPaymentMethod.aforza__Payment_Card_Expiration_Year__c = btPaymentMethod.bt_stripe__Card_Expiration_Year__c;

        return newAforzaPaymentMethod;
    }
}