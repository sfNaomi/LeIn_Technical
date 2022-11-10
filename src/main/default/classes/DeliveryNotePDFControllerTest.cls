@IsTest
private with sharing class DeliveryNotePDFControllerTest {
    @IsTest
    private static void testDeliveryNotePDFController() {
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
        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id)
        );

        Test.startTest();
        PageReference testPage = Page.DeliveryNotePDF;
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('id', newOrder.Id);
        DeliveryNotePDFController.attachPDF(newOrder.Id);
        DeliveryNotePDFController testPdfController = new DeliveryNotePDFController();
        Test.stopTest();

        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :newOrder.Id];
        System.assert(!docLinks.isEmpty());
    }

    @IsTest
    private static void testDeliveryNotePDFControllerBulk() {
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

        Order newOrder1 = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
        );
        Order newOrder2 = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
        );
        Order newOrder3 = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
        );

        OrderItem newOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder1.Id)
        );
        OrderItem newOrderItem2 = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder2.Id)
        );
        OrderItem newOrderItem3 = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder3.Id)
        );

        String orderIds = newOrder1.Id + ',' + newOrder2.Id + ',' + newOrder3.Id;
        Test.startTest();
        PageReference testPage = Page.DeliveryNotePDF;
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('id', orderIds);
        DeliveryNotePDFController.attachPDF(newOrder1.Id);
        DeliveryNotePDFController.attachPDF(newOrder2.Id);
        DeliveryNotePDFController.attachPDF(newOrder3.Id);
        DeliveryNotePDFController testPdfController = new DeliveryNotePDFController();
        Test.stopTest();

        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :orderIds.split(',')];
        System.assert(docLinks.size() == 3);
    }
}