@IsTest
private class InsecureOrderCloningServiceTest {
	@IsTest
    private static void testCloneOrder() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(
            new Product2(Name = 'Test Product', ProductCode = 'SKU1')
        );
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
                LastOrderDate__c = null, aforza__Default_Price_Book__c = newPricebook.Id
            )
        );
        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_EDI_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        Test.startTest();
        newOrder.Status = new List<String>(OrderService.COMPLETED_ORDER_STATUSES).get(0);
        update newOrder;
        Test.stopTest();

        Order clonedOrder = [SELECT Id, Clone__c, aforza__Original_Order__c, Status FROM Order WHERE Clone__c = TRUE];
        System.assertEquals(newOrder.Id, clonedOrder.aforza__Original_Order__c, 'Expected a different original order Id.');
        System.assertEquals('Draft', clonedOrder.Status, 'Expected a different order status for the clone.');

        List<OrderItem> clonedOrderItems = [
            SELECT Id, OrderId, Product2Id
            FROM OrderItem
            WHERE OrderId = :clonedOrder.Id
        ];
        System.assertEquals(1, clonedOrderItems.size(), 'Expected one order item for the cloned order');
    }
}