/**
 * Created by svatopluk.sejkora on 15.11.2022.
 */

@IsTest
private class BtTransactionTriggerHandlerTest {

    @IsTest
    private static void testFetchPaymentMethodsForAccounts() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        aforza__Payment_Method__c paymentMethod = (aforza__Payment_Method__c)
            TdfSObjectFactory.insertSObject(new aforza__Payment_Method__c(RecordTypeId = RecordTypes.PAYMENT_METHOD_CREDIT_CARD_ID,
                aforza__Account__c = acc.Id));

        Test.startTest();
        Map<Id, Id> accountIdToPaymentMethodId = BtTransactionTriggerHandler.fetchPaymentMethodsForAccounts(new Set<Id>{
            acc.Id
        });
        Test.stopTest();

        Assert.areEqual(1, accountIdToPaymentMethodId.size());
        Assert.isTrue(accountIdToPaymentMethodId.containsKey(acc.Id));
        Assert.areEqual(paymentMethod.Id, accountIdToPaymentMethodId.get(acc.Id));
    }

    @IsTest
    private static void testMapBlackthornTransactionToAforzaTransaction() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        TdfSObjectFactory.insertSObject(new aforza__Payment_Method__c(RecordTypeId = RecordTypes.PAYMENT_METHOD_CREDIT_CARD_ID,
            aforza__Account__c = acc.Id));
        bt_stripe__Transaction__c blackthornTransaction = (bt_stripe__Transaction__c)
            TdfSObjectFactory.createSObject(new bt_stripe__Transaction__c(bt_stripe__Related_Account__c = acc.Id, RecordTypeId = RecordTypes.BT_TRANSACTION_CHARGE_ID));

        Map<Id, Id> accountIdToPaymentMethodId = BtTransactionTriggerHandler.fetchPaymentMethodsForAccounts(new Set<Id>{
            acc.Id
        });

        Test.startTest();
        aforza__Payment_Transaction__c paymentTransaction = BtTransactionTriggerHandler.mapBlackthornTransactionToAforzaTransaction(blackthornTransaction, accountIdToPaymentMethodId);
        Test.stopTest();

        Assert.areEqual(accountIdToPaymentMethodId.get(acc.Id), paymentTransaction.aforza__Payment_Method__c);
        Assert.areEqual(blackthornTransaction.bt_stripe__Amount__c, paymentTransaction.aforza__Amount__c);
        Assert.areEqual('Pre-Authorization', paymentTransaction.aforza__Status__c);
        Assert.areEqual(blackthornTransaction.Order__c, paymentTransaction.OrderNumber__c);
        Assert.areEqual(blackthornTransaction.bt_stripe__Related_Account__c, paymentTransaction.aforza__Account__c);
        Assert.areEqual('Credit Card', paymentTransaction.aforza__Method__c);
        Assert.areEqual('Customer Payment', paymentTransaction.aforza__Type__c);
        Assert.areEqual(blackthornTransaction.bt_stripe__Processed_Date__c.date(), paymentTransaction.aforza__Date__c);
        Assert.areEqual(blackthornTransaction.Id, paymentTransaction.BtTransaction__c);
    }

    @IsTest
    private static void testMapBlackthornTransactionToAforzaTransaction_NoPaymentMethod() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        bt_stripe__Transaction__c blackthornTransaction = (bt_stripe__Transaction__c)
            TdfSObjectFactory.createSObject(new bt_stripe__Transaction__c(bt_stripe__Related_Account__c = acc.Id, RecordTypeId = RecordTypes.BT_TRANSACTION_CHARGE_ID));

        Map<Id, Id> accountIdToPaymentMethodId = BtTransactionTriggerHandler.fetchPaymentMethodsForAccounts(new Set<Id>{
            acc.Id
        });

        Test.startTest();
        aforza__Payment_Transaction__c paymentTransaction = BtTransactionTriggerHandler.mapBlackthornTransactionToAforzaTransaction(blackthornTransaction, accountIdToPaymentMethodId);
        Test.stopTest();

        Assert.areEqual(null, paymentTransaction.aforza__Payment_Method__c);
    }

    @IsTest
    private static void testCreateAforzaTransaction() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        TdfSObjectFactory.insertSObject(new aforza__Payment_Method__c(RecordTypeId = RecordTypes.PAYMENT_METHOD_CREDIT_CARD_ID,
            aforza__Account__c = acc.Id));

        bt_stripe__Transaction__c blackthornTransaction = (bt_stripe__Transaction__c)
            TdfSObjectFactory.createSObject(new bt_stripe__Transaction__c(bt_stripe__Related_Account__c = acc.Id, RecordTypeId = RecordTypes.BT_TRANSACTION_CHARGE_ID));

        Test.startTest();
        insert blackthornTransaction;
        Test.stopTest();

        // get aforza transaction
        List<aforza__Payment_Transaction__c> createdPaymentTransaction = [SELECT Id FROM aforza__Payment_Transaction__c];
        Assert.isTrue(createdPaymentTransaction.size() == 1);

        // get updated orders
        List<Order> updatedOrders = [SELECT Id, PreAuthCaptured__c FROM Order];
        Assert.isTrue(updatedOrders.size() == 1);
        Assert.isTrue(updatedOrders[0].PreAuthCaptured__c);
    }

    @IsTest
    private static void testPreparePaymentsForUpdate() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        TdfSObjectFactory.insertSObject(new aforza__Payment_Method__c(RecordTypeId = RecordTypes.PAYMENT_METHOD_CREDIT_CARD_ID,
            aforza__Account__c = acc.Id));

        aforza__Invoice__c invoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(new aforza__Invoice__c(aforza__Account__c = acc.Id));

        bt_stripe__Transaction__c blackthornTransaction = (bt_stripe__Transaction__c)
            TdfSObjectFactory.createSObject(new bt_stripe__Transaction__c(bt_stripe__Related_Account__c = acc.Id, RecordTypeId = RecordTypes.BT_TRANSACTION_CHARGE_ID, Invoice__c = invoice.Id));
        insert blackthornTransaction;


        Test.startTest();
        blackthornTransaction.bt_stripe__Payment_Status__c = 'Paid';
        blackthornTransaction.bt_stripe__Transaction_Status__c = 'Completed';
        update blackthornTransaction;
        Test.stopTest();

        List<aforza__Invoice__c> updatedInvoices = [SELECT Id, aforza__Status__c FROM aforza__Invoice__c];
        Assert.isTrue(updatedInvoices.size() == 1);
        Assert.areEqual('Paid in Full', updatedInvoices[0].aforza__Status__c);

        List<aforza__Payment_Transaction__c> updatedPaymentTransactions = [SELECT Id, aforza__Status__c FROM aforza__Payment_Transaction__c];
        Assert.isTrue(updatedPaymentTransactions.size() == 1);
        Assert.areEqual('Applied', updatedPaymentTransactions[0].aforza__Status__c);
    }
}