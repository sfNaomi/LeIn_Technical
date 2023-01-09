@IsTest
private with sharing class DeliveryNotePDFControllerTest {
    @IsTest
    private static void testDeliveryNotePDFController() {
        // create products
        Product2 newProduct1 = (Product2) TdfSObjectFactory.insertSObject(
            new Product2(Name = 'Test Product 1', aforza__Weight__c = 1.5)
        );
        Product2 newProduct2 = (Product2) TdfSObjectFactory.insertSObject(
            new Product2(Name = 'Test Product 2', aforza__Weight__c = 1.5)
        );
        // add new products to standard PB
        PricebookEntry product1PricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct1.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );
        PricebookEntry product2PricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct2.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );
        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                AccountStatus__c = 'Traders',
                InvoiceType__c = 'Email',
                DeliveryNoteEmail__c = 'test@test.com'
            )
        );
        Contact newContact = (Contact) TdfSObjectFactory.insertSObject(
            new Contact(AccountId = dpAccount.Id, Email = 'test@test.com')
        );
        dpAccount.aforza__Primary_Contact__c = newContact.Id;
        update dpAccount;

        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
        );
        TdfSObjectFactory.insertSObject(new OrderItem(
            OrderId = newOrder.Id,
            Product2Id = newProduct1.Id,
            Quantity = 10,
            PricebookEntryId = product1PricebookEntry.Id
        ));
        TdfSObjectFactory.insertSObject(new OrderItem(
            OrderId = newOrder.Id,
            Product2Id = newProduct1.Id,
            Quantity = 2,
            PricebookEntryId = product1PricebookEntry.Id
        ));
        TdfSObjectFactory.insertSObject(new OrderItem(
            OrderId = newOrder.Id,
            Product2Id = newProduct2.Id,
            Quantity = 5,
            PricebookEntryId = product2PricebookEntry.Id
        ));

        Test.startTest();
        PageReference testPage = Page.DeliveryNotePDF;
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('p', newOrder.Id);
        DeliveryNotePDFController ctrl = new DeliveryNotePDFController();
        Test.stopTest();

        Assert.areEqual(1, ctrl.mapIdOrder.size());
        Assert.areEqual(2, ctrl.mapOrderIdlstOrderItem.get(newOrder.Id).size());
        Assert.areEqual(12, ctrl.mapOrderIdlstOrderItem.get(newOrder.Id)[0].Quantity);
        Assert.areEqual(5, ctrl.mapOrderIdlstOrderItem.get(newOrder.Id)[1].Quantity);
    }
}