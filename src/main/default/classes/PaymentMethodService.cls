/**
 * Created by eddy.ferreira on 18.11.2022.
 */

public with sharing class PaymentMethodService {

    public static Map<Id,Account> getPaymentMethodParentAccounts(Set<Id> newPaymentMethodParentAccountIds){
       Map<Id,Account> parentAccounts = new Map<Id,Account>([SELECT Id, Name, PrimaryPaymentMethod__c 
                                                              FROM Account 
                                                              WHERE Id IN :newPaymentMethodParentAccountIds]);
       return parentAccounts;
    }   
	
    public static void setPrimaryPaymentMethodOnAccount(List<aforza__Payment_Method__c> paymentMethods, Map<Id,Account> parentAccounts){
       List<Account> accountsToUpdate = new List<Account>(); 
       for (aforza__Payment_Method__c newPaymentMethod : paymentMethods){
              Account parentAccount = parentAccounts.get(newPaymentMethod.aforza__Account__c);
              if(parentAccount.PrimaryPaymentMethod__c != 'Direct Debit'){
                     if (newPaymentMethod.RecordTypeId == RecordTypes.PAYMENT_METHOD_CASH_ID) {
                            parentAccount.PrimaryPaymentMethod__c = 'Cash';
                     }
                     if (newPaymentMethod.RecordTypeId == RecordTypes.PAYMENT_METHOD_CREDIT_CARD_ID) {
                            parentAccount.PrimaryPaymentMethod__c = 'Card Payment';
                     }
                     if (newPaymentMethod.RecordTypeId == RecordTypes.PAYMENT_METHOD_DIRECT_CARD_ID) {
                            parentAccount.PrimaryPaymentMethod__c = 'Direct Debit';
                     }
                     if (newPaymentMethod.RecordTypeId == RecordTypes.PAYMENT_METHOD_BANK_ACCOUNT_ID) {
                            parentAccount.PrimaryPaymentMethod__c = 'Bacs';
                     }
                     if (newPaymentMethod.RecordTypeId == RecordTypes.PAYMENT_METHOD_CHEQUE_ID) {
                            parentAccount.PrimaryPaymentMethod__c = 'Cheque';
                     }
                     accountsToUpdate.add(parentAccount);    
              } 
       }
       update accountsToUpdate;
    }
}