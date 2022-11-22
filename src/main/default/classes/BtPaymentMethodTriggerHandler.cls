/**
 * Created by eddy.ferreira on 09.11.2022.
 */

public with sharing class BtPaymentMethodTriggerHandler {
      
    public static void createAforzaPaymentMethodFromBlackthornPaymentMethod (List<bt_stripe__Payment_Method__c> newBtPaymentMethods, Map<Id,bt_stripe__Payment_Method__c> oldBtPaymentMethods){
        Set<Id> newBtPaymentMethodIds = new Set<Id>();
        List<aforza__Payment_Method__c> aforzaPaymentMethodsToCreate = new List<aforza__Payment_Method__c>();
        for (bt_stripe__Payment_Method__c newBtPaymentMethod : newBtPaymentMethods){
            bt_stripe__Payment_Method__c oldBtPaymentMethod = oldBtPaymentMethods?.get(newBtPaymentMethod.Id);
            if (oldBtPaymentMethod == null && newBtPaymentMethod != null) {
                newBtPaymentMethodIds.add(newBtPaymentMethod.Id);
            }
        }

        if (newBtPaymentMethodIds.size() > 0) {
            List<bt_stripe__Payment_Method__c> newBtPaymentMethodsList = [SELECT Id, bt_stripe__Account__c, bt_stripe__Card_Expiration_Month__c,
                                                                            bt_stripe__Card_Expiration_Year__c, bt_stripe__Card_Holder_Name__c, 
                                                                            bt_stripe__Brand__c 
                                                                    FROM bt_stripe__Payment_Method__c
                                                                    WHERE Id IN :newBtPaymentMethodIds];
            
        	for (bt_stripe__Payment_Method__c btPaymentMethod : newBtPaymentMethodsList) {
                aforza__Payment_Method__c newAforzaPaymentMethod = new aforza__Payment_Method__c();
                aforzaPaymentMethodsToCreate.add(mapNewAforzaPaymentMethodRecordFields(newAforzaPaymentMethod, btPaymentMethod));
            }           
        }                                                        
        insert aforzaPaymentMethodsToCreate;
    }

    private static aforza__Payment_Method__c mapNewAforzaPaymentMethodRecordFields(aforza__Payment_Method__c newAforzaPaymentMethod, bt_stripe__Payment_Method__c btPaymentMethod){
            newAforzaPaymentMethod.RecordTypeId=RecordTypes.PAYMENT_METHOD_CREDIT_CARD_ID;
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