/**
 * Created by eddy.ferreira on 06.10.2022.
 */
@isTest
private with sharing class PaymentTransactionTriggerHandlerTest {
    @isTest
    private static void testUpdateParentOrderAndAccountCreditStatuses_onCreation(){
        Account parentAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                CreditStatus__c = 'On Hold'
            )
        );
        Order parentOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                AccountId = parentAccount.Id,
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID,
                Status = 'Draft'
            )
        );
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product'));
        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
                new OrderItem(OrderId = parentOrder.Id, Product2Id = newProduct.Id)
        );

        Test.startTest();
			aforza__Payment_Transaction__c newPaymentTransaction = new aforza__Payment_Transaction__c(aforza__account__c = parentAccount.Id, aforza__amount__c = 100, aforza__Status__c = 'Pre-Authorization', OrderNumber__c=parentOrder.Id);
       		insert newPaymentTransaction;
        Test.stopTest();
        Order updatedParentOrder = [
            SELECT Id, Status
            FROM Order
            WHERE Id = :parentOrder.Id
        ];
        
        Account updatedParentAccount = [
            SELECT Id, CreditStatus__c
            FROM Account
            WHERE Id = :parentAccount.Id
        ];
   
        System.assertEquals('Activated', updatedParentOrder.Status, 'Expecting a different order status.');
        System.assertEquals('Good', updatedParentAccount.CreditStatus__c, 'Expecting a different account credit status.');
    }
	@isTest
    private static void testUpdateParentOrderAndAccountCreditStatuses_onUpdate(){
        Account parentAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                CreditStatus__c = 'On Hold'
            )
        );
        Order parentOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                AccountId = parentAccount.Id,
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID,
                Status = 'Draft'
            )
        );
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product'));
        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
                new OrderItem(OrderId = parentOrder.Id, Product2Id = newProduct.Id)
        );

        aforza__Payment_Transaction__c newPaymentTransaction = new aforza__Payment_Transaction__c(aforza__account__c = parentAccount.Id, aforza__amount__c = 100, aforza__Status__c = 'Applied', OrderNumber__c=parentOrder.Id);
        insert newPaymentTransaction;
        
        Test.startTest();
        newPaymentTransaction.aforza__Status__c = 'Pre-Authorization';
        update newPaymentTransaction;
        Test.stopTest();
        
        Order updatedParentOrder = [
            SELECT Id, Status
            FROM Order
            WHERE Id = :parentOrder.Id
        ];
        
        Account updatedParentAccount = [
            SELECT Id, CreditStatus__c
            FROM Account
            WHERE Id = :parentAccount.Id
        ];

        System.assertEquals('Activated', updatedParentOrder.Status, 'Expecting a different order status.');
        System.assertEquals('Good', updatedParentAccount.CreditStatus__c, 'Expecting a different account credit status.');
    }
}