/**
 * Created by eddy.ferreira on 09.11.2022.
 */

public with sharing class PaymentMethodTriggerHandler {
      
    public static void assignPrimaryPaymentMethodToParentAccount (List<aforza__Payment_Method__c> newPaymentMethods, Map<Id,aforza__Payment_Method__c> oldPaymentMethods){
        
        Set<Id> newPaymentMethodParentAccountIds = new Set<Id>();
        List<aforza__Payment_Method__c> paymentMethods = new List<aforza__Payment_Method__c>();
        
        for (aforza__Payment_Method__c newPaymentMethod : newPaymentMethods){
            aforza__Payment_Method__c oldPaymentMethod = oldPaymentMethods?.get(newPaymentMethod.Id);
            if (
                (
                (oldPaymentMethod == null && newPaymentMethod != null) ||
                (oldPaymentMethod != null && oldPaymentMethod.aforza__Primary__c != newPaymentMethod.aforza__Primary__c)
            	) &&
                (newPaymentMethod.aforza__Active__c == true && newPaymentMethod.aforza__Primary__c == true)
               )
                {
                    newPaymentMethodParentAccountIds.add(newPaymentMethod.aforza__Account__c);
                    paymentMethods.add(newPaymentMethod);
                }
        }

        PaymentMethodService.setPrimaryPaymentMethodOnAccount(paymentMethods, PaymentMethodService.getPaymentMethodParentAccounts(newPaymentMethodParentAccountIds));	
    }
}