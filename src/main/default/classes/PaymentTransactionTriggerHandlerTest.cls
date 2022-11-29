/**
 * Created by eddy.ferreira on 06.10.2022.
 */
@isTest
private with sharing class PaymentTransactionTriggerHandlerTest {
    @isTest
    private static void testUpdateParentOrderAndAccountCreditStatuses_onCreation(){
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                aforza__Default_Price_Book__c = newPricebook.Id, CreditStatus__c = 'On Hold'
            )
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        Test.startTest();
        TdfSObjectFactory.insertSObject(
            new aforza__Payment_Transaction__c(
                aforza__Account__c = dpAccount.Id, aforza__amount__c = 100,
                aforza__Status__c = 'Pre-Authorization', OrderNumber__c = newOrder.Id
            )
        );
        Test.stopTest();

        Order updatedOrder = [
            SELECT Id, Status
            FROM Order
            WHERE Id = :newOrder.Id
        ];
        
        Account updatedDpAccount = [
            SELECT Id, CreditStatus__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];
   
        Assert.areEqual('Unplanned', updatedOrder.Status, 'Expecting a different order status.');
        Assert.areEqual('Good', updatedDpAccount.CreditStatus__c, 'Expecting a different account credit status.');
    }

	@isTest
    private static void testUpdateParentOrderAndAccountCreditStatuses_onUpdate(){
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                aforza__Default_Price_Book__c = newPricebook.Id, CreditStatus__c = 'On Hold'
            )
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        // create payment transaction
        aforza__Payment_Transaction__c newPaymentTransaction = (aforza__Payment_Transaction__c) TdfSObjectFactory.insertSObject(
            new aforza__Payment_Transaction__c(
                aforza__Account__c = dpAccount.Id, aforza__amount__c = 100,
                aforza__Status__c = 'Applied', OrderNumber__c = newOrder.Id
            )
        );
        
        Test.startTest();
        newPaymentTransaction.aforza__Status__c = 'Pre-Authorization';
        update newPaymentTransaction;
        Test.stopTest();
        
        Order updatedParentOrder = [
            SELECT Id, Status
            FROM Order
            WHERE Id = :newOrder.Id
        ];
        
        Account updatedParentAccount = [
            SELECT Id, CreditStatus__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Assert.areEqual('Unplanned', updatedParentOrder.Status, 'Expecting a different order status.');
        Assert.areEqual('Good', updatedParentAccount.CreditStatus__c, 'Expecting a different account credit status.');
    }
}