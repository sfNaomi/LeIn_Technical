/**
 * Created by eddy.ferreira on 14.11.2022.
 */
@isTest
private with sharing class PaymentMethodTriggerHandlerTest {
    @isTest
    private static void testAssignPrimaryPaymentMethodToParentAccount_onInsert(){
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID
            )
        );    

        Test.startTest();
        	//new Payment Method
        	aforza__Payment_Method__c paymentMethod = (aforza__Payment_Method__c) TdfSObjectFactory.insertSObject(new aforza__Payment_Method__c(
                								 RecordTypeId = RecordTypes.PAYMENT_METHOD_CASH_ID,
                								 aforza__Account__c = dpAccount.Id,
                								 aforza__Primary__c = true 
            									 )); 
        Test.stopTest();

        Account dpAccountInserted = [SELECT Id, PrimaryPaymentMethod__c FROM Account WHERE Id =: dpAccount.Id];
        
        Assert.areEqual('Cash', dpAccountInserted.PrimaryPaymentMethod__c);
    }
    
    @isTest
    private static void testAssignPrimaryPaymentMethodToParentAccount_onUpdate(){
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID
            )
        );    
		
        aforza__Payment_Method__c paymentMethodCashPrimary = (aforza__Payment_Method__c) TdfSObjectFactory.insertSObject(new aforza__Payment_Method__c(
                								 RecordTypeId = RecordTypes.PAYMENT_METHOD_CASH_ID,
                								 aforza__Account__c = dpAccount.Id,
                								 aforza__Primary__c = true 
            									 )); 
        aforza__Payment_Method__c paymentMethodChequeNotPrimary = (aforza__Payment_Method__c) TdfSObjectFactory.insertSObject(new aforza__Payment_Method__c(
                								 RecordTypeId = RecordTypes.PAYMENT_METHOD_CHEQUE_ID,
                								 aforza__Account__c = dpAccount.Id,
                								 aforza__Primary__c = false 
            									 ));
        
        Test.startTest();
        	//update Payment Method
        	paymentMethodChequeNotPrimary.aforza__Primary__c = true;
        	update paymentMethodChequeNotPrimary;
        Test.stopTest();

        Account dpAccountUpdated = [SELECT Id, PrimaryPaymentMethod__c FROM Account WHERE Id =: dpAccount.Id];
        
        Assert.areEqual('Cheque', dpAccountUpdated.PrimaryPaymentMethod__c);
    }
    
    @isTest
    private static void testAssignPrimaryPaymentMethodToParentAccount_onInsertNotPrimaryMethod(){
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryPaymentMethod__c = 'Direct Debit'
            )
        );    

        Test.startTest();
        	//new Payment Method
        	aforza__Payment_Method__c paymentMethod = (aforza__Payment_Method__c) TdfSObjectFactory.insertSObject(new aforza__Payment_Method__c(
                								 RecordTypeId = RecordTypes.PAYMENT_METHOD_CASH_ID,
                								 aforza__Account__c = dpAccount.Id,
                								 aforza__Primary__c = false 
            									 )); 
        Test.stopTest();

        Account dpAccountInserted = [SELECT Id, PrimaryPaymentMethod__c FROM Account WHERE Id =: dpAccount.Id];
        
        Assert.areEqual('Direct Debit', dpAccountInserted.PrimaryPaymentMethod__c);
    }
    
    @isTest
    private static void testAssignPrimaryPaymentMethodToParentAccount_onUpdateNotPrimaryMethod(){
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID
            )
        );    
		
        aforza__Payment_Method__c paymentMethodBacsPrimary = (aforza__Payment_Method__c) TdfSObjectFactory.insertSObject(new aforza__Payment_Method__c(
                								 RecordTypeId = RecordTypes.PAYMENT_METHOD_BANK_ACCOUNT_ID,
                								 aforza__Account__c = dpAccount.Id,
                								 aforza__Primary__c = true 
            									 )); 
        aforza__Payment_Method__c paymentMethodChequeNotPrimary = (aforza__Payment_Method__c) TdfSObjectFactory.insertSObject(new aforza__Payment_Method__c(
                								 RecordTypeId = RecordTypes.PAYMENT_METHOD_CHEQUE_ID,
                								 aforza__Account__c = dpAccount.Id,
                								 aforza__Primary__c = false 
            									 ));
        
        Test.startTest();
        	//update Payment Method
        	paymentMethodBacsPrimary.aforza__Primary__c = false;
        	update paymentMethodBacsPrimary;
        Test.stopTest();

        Account dpAccountUpdated = [SELECT Id, PrimaryPaymentMethod__c FROM Account WHERE Id =: dpAccount.Id];
        
        Assert.areEqual('Bacs', dpAccountUpdated.PrimaryPaymentMethod__c);
    }
}