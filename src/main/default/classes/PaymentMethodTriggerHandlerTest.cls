/**
 * Created by eddy.ferreira on 14.11.2022.
 */
@IsTest
private with sharing class PaymentMethodTriggerHandlerTest {
    @TestSetup
    private static void recalculatePermSetGroups() {
        PermissionSetGroup adminPermSetGroup = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'Administrator'][0];

        Test.calculatePermissionSetGroup(new Id[]{
            adminPermSetGroup.Id
        });
    }

    @IsTest
    private static void testAssignPrimaryPaymentMethodToParentAccount_onInsert() {
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID
            )
        );

        Test.startTest();
        //new Payment Method
        TdfSObjectFactory.insertSObject(new aforza__Payment_Method__c(
            RecordTypeId = RecordTypes.PAYMENT_METHOD_CASH_ID,
            aforza__Account__c = dpAccount.Id,
            aforza__Primary__c = true
        ));
        Test.stopTest();

        Account dpAccountInserted = [SELECT Id, PrimaryPaymentMethod__c FROM Account WHERE Id = :dpAccount.Id];

        Assert.areEqual('Cash', dpAccountInserted.PrimaryPaymentMethod__c);
    }

    @IsTest
    private static void testAssignPrimaryPaymentMethodToParentAccount_onUpdate() {
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID
            )
        );

        TdfSObjectFactory.insertSObject(new aforza__Payment_Method__c(
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

        Account dpAccountUpdated = [SELECT Id, PrimaryPaymentMethod__c FROM Account WHERE Id = :dpAccount.Id];

        Assert.areEqual('Cheque', dpAccountUpdated.PrimaryPaymentMethod__c);
    }

    @IsTest
    private static void testAssignPrimaryPaymentMethodToParentAccount_onInsertNotPrimaryMethod() {
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryPaymentMethod__c = 'Direct Debit'
            )
        );

        Test.startTest();
        //new Payment Method
        TdfSObjectFactory.insertSObject(new aforza__Payment_Method__c(
            RecordTypeId = RecordTypes.PAYMENT_METHOD_CASH_ID,
            aforza__Account__c = dpAccount.Id,
            aforza__Primary__c = false
        ));
        Test.stopTest();

        Account dpAccountInserted = [SELECT Id, PrimaryPaymentMethod__c FROM Account WHERE Id = :dpAccount.Id];

        Assert.areEqual('Direct Debit', dpAccountInserted.PrimaryPaymentMethod__c);
    }

    @IsTest
    private static void testAssignPrimaryPaymentMethodToParentAccount_onUpdateNotPrimaryMethod() {
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
        TdfSObjectFactory.insertSObject(new aforza__Payment_Method__c(
            RecordTypeId = RecordTypes.PAYMENT_METHOD_CHEQUE_ID,
            aforza__Account__c = dpAccount.Id,
            aforza__Primary__c = false
        ));

        Test.startTest();
        //update Payment Method
        paymentMethodBacsPrimary.aforza__Primary__c = false;
        update paymentMethodBacsPrimary;
        Test.stopTest();

        Account dpAccountUpdated = [SELECT Id, PrimaryPaymentMethod__c FROM Account WHERE Id = :dpAccount.Id];

        Assert.areEqual('Bacs', dpAccountUpdated.PrimaryPaymentMethod__c);
    }
}