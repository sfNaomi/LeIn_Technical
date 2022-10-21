/**
 * Created by eddy.ferreira on 13.09.2022.
 */

public with sharing class PaymentTransactionTriggerHandler {
      
    public static void setParentOrderAndAccountStatusesOnPaymentTransactionCreationOrUpdate (List<aforza__Payment_Transaction__c> newPayments, Map<Id,aforza__Payment_Transaction__c> oldPayments){
        Set<Id> relatedOrderIds = new Set<Id>();
		Set<Id> relatedAccountIds = new Set<Id>();
        
        for (aforza__Payment_Transaction__c payment : newPayments) {
            relatedOrderIds.add(payment.OrderNumber__c);
            relatedAccountIds.add(payment.aforza__Account__c);
        }
        
        Map<Id, Order> parentOrders = new Map<Id, Order>([SELECT Id, Status FROM Order WHERE Id IN :relatedOrderIds]);
		Map<Id, Account> parentAccounts = new Map<Id, Account>([SELECT Id, CreditStatus__c FROM Account WHERE Id IN :relatedAccountIds]);
        
        for (aforza__Payment_Transaction__c payment: newPayments){
            aforza__Payment_Transaction__c oldPayment = oldPayments?.get(payment.Id);
            Order parentOrder = parentOrders.get(payment.OrderNumber__c);
            Account parentAccount = parentAccounts.get(payment.aforza__Account__c);
            if(	
                (oldPayment == null && payment.aforza__Status__c == 'Pre-Authorization' && 
                parentOrder.Status != 'Activated' && 
                parentAccount.CreditStatus__c != 'Good') ||
                (oldPayment != null && payment.aforza__Status__c != oldPayment.aforza__Status__c && 
                payment.aforza__Status__c == 'Pre-Authorization' && 
                parentOrder.Status != 'Activated' && 
                parentAccount.CreditStatus__c != 'Good')
                ){
                    parentOrder.Status = 'Activated';
                    parentAccount.CreditStatus__c = 'Good';
            }   
        }
        
		if (!parentAccounts.isEmpty()) {
            update parentAccounts.values();
        }
        if (!parentOrders.isEmpty()) {
            update parentOrders.values();
        }    
    }
}