/**
 * @description       :
 * @author            : Ciuca Bianca BearingPoint GmbH
 * @group             :
 * @last modified on  : 10-07-2022
 * @last modified by  : Ciuca Bianca, BearingPoint GmbH
 **/

@IsTest
private with sharing class InvoiceServiceTest {
    @IsTest
    private static void testCreateInvoicesFromOrders_NoDocumentGenerated() {
        // create product
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(
            new Product2(Name = 'Test Product', ProductCode = 'SKU1')
        );

        // add new product to standard PB
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add products to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                AccountStatus__c = 'Traders',
                aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID,
                AccountId = dpAccount.Id,
                Status = 'Draft',
                Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        Test.startTest();
        InvoiceService.createInvoicesFromOrders(new Set<Id>{
            newOrder.Id
        });
        Test.stopTest();

        // retrieve invoice and invoice line items, validate results
        List<aforza__Invoice__c> invoices = [SELECT Id FROM aforza__Invoice__c WHERE aforza__Order__c = :newOrder.Id];
        Assert.areEqual(1, invoices.size());

        List<aforza__Invoice_Line_Item__c> invoiceLineItems = [
            SELECT Id
            FROM aforza__Invoice_Line_Item__c
            WHERE aforza__Invoice__c IN :invoices
        ];
        Assert.areEqual(1, invoiceLineItems.size());

        List<ContentDocumentLink> relatedFiles = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :invoices[0].Id];
        Assert.areEqual(0, relatedFiles.size());

        List<Task> relatedActivities = [SELECT Id FROM Task WHERE WhatId = :invoices[0].Id];
        Assert.areEqual(0, relatedActivities.size());
    }

    @IsTest
    private static void testCreateInvoicesFromOrders_DocumentGenerated() {
        // create product
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(
            new Product2(Name = 'Test Product', ProductCode = 'SKU1')
        );

        // add new product to standard PB
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add products to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                AccountStatus__c = 'Traders',
                InvoiceType__c = 'Email',
                aforza__Invoice_Email_Address__c = 'test@test.com',
                aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        Contact newContact = (Contact) TdfSObjectFactory.insertSObject(
            new Contact(AccountId = dpAccount.Id, Email = 'test@test.com')
        );
        dpAccount.aforza__Primary_Contact__c = newContact.Id;
        update dpAccount;

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID,
                AccountId = dpAccount.Id,
                Status = 'Draft',
                Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(
                OrderId = newOrder.Id,
                Product2Id = newProduct.Id,
                PricebookEntryId = newPricebookEntry.Id
            )
        );

        Test.startTest();
        InvoiceService.createInvoicesFromOrders(new Set<Id>{
            newOrder.Id
        });
        Test.stopTest();

        // retrieve invoice and invoice line items, validate results
        List<aforza__Invoice__c> invoices = [SELECT Id FROM aforza__Invoice__c WHERE aforza__Order__c = :newOrder.Id];
        Assert.areEqual(1, invoices.size());

        List<aforza__Invoice_Line_Item__c> invoiceLineItems = [
            SELECT Id
            FROM aforza__Invoice_Line_Item__c
            WHERE aforza__Invoice__c IN :invoices
        ];
        Assert.areEqual(1, invoiceLineItems.size());

        List<ContentDocumentLink> relatedFiles = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :invoices[0].Id];
        Assert.areEqual(1, relatedFiles.size());

        List<Task> relatedActivities = [SELECT Id FROM Task WHERE WhatId = :invoices[0].Id];
        Assert.areEqual(1, relatedActivities.size());
    }

    @IsTest
    private static void testGetPaymentTransactions() {
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );

        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
        );

        TdfSObjectFactory.insertSObject(
            new aforza__Payment_Transaction__c(aforza__Account__c = dpAccount.Id, OrderNumber__c = newOrder.Id)
        );

        // retrieve payment and validate result
        List<aforza__Payment_Transaction__c> transactions = InvoiceService.getPaymentTransactions(new Set<Id>{
            newOrder.Id
        });
        Assert.areEqual(1, transactions.size());
    }

    @IsTest
    private static void testGenerateInvoiceFromOrder() {
        // create product
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(
            new Product2(Name = 'Test Product', ProductCode = 'SKU1')
        );

        // add new product to standard PB
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add products to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                AccountStatus__c = 'Traders',
                aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID,
                AccountId = dpAccount.Id,
                Status = 'Draft',
                Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(
                OrderId = newOrder.Id,
                Product2Id = newProduct.Id,
                PricebookEntryId = newPricebookEntry.Id
            )
        );

        aforza__Invoice__c newInvoice = new aforza__Invoice__c();

        Test.startTest();
        InvoiceService.generateInvoiceFromOrder(newInvoice, newOrder);
        Test.stopTest();

        Assert.areEqual(newOrder.Id, newInvoice.aforza__Order__c);
    }

    @IsTest
    private static void testGetOrders() {
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );

        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
        );

        Test.startTest();
        List<Order> orders = InvoiceService.getOrders(new Set<Id>{
            newOrder.Id
        });
        Test.stopTest();

        Assert.areEqual(1, orders.size());
    }

    @IsTest
    private static void testGetInvoices() {
        // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );

        // create related order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
        );

        // create Invoice
        TdfSObjectFactory.insertSObject(
            new aforza__Invoice__c(aforza__Account__c = dpAccount.Id, aforza__Order__c = newOrder.Id)
        );

        Test.startTest();
        List<aforza__Invoice__c> invoices = InvoiceService.getInvoices(new Set<Id>{
            newOrder.Id
        });
        Test.stopTest();

        Assert.areEqual(1, invoices.size());
    }

    @IsTest
    private static void testComputeInvoiceIssuedDate_NullInitialIssuedDate() {
        Date initialIssuedDate = null;

        Test.startTest();
        Date finalIssuedDate = InvoiceService.computeInvoiceIssuedDate(initialIssuedDate);
        Test.stopTest();

        Assert.areEqual(finalIssuedDate, System.today());
    }

    @IsTest
    private static void testComputeInvoiceIssuedDate_NotNullInitialIssuedDate() {
        Date initialIssuedDate = Date.newInstance(2000, 1, 1);

        Test.startTest();
        Date finalIssuedDate = InvoiceService.computeInvoiceIssuedDate(initialIssuedDate);
        Test.stopTest();

        Assert.areEqual(initialIssuedDate, finalIssuedDate);
    }

    @IsTest
    private static void testComputeInvoiceStatus_DirectDebitAccount() {
        String paymentMethod = 'Direct Debit';

        String initialInvoiceStatus = null;
        String expectedInvoiceStatus = 'Paid in Full';

        Test.startTest();
        String actualInvoiceStatus = InvoiceService.computeInvoiceStatus(paymentMethod, initialInvoiceStatus);
        Test.stopTest();

        Assert.areEqual(expectedInvoiceStatus, actualInvoiceStatus);
    }

    @IsTest
    private static void testComputeInvoiceStatus_NonDirectDebitAccount() {
        String paymentMethod = 'Direct Debit';

        String initialInvoiceStatus = null;
        String expectedInvoiceStatus = 'Paid in Full';

        Test.startTest();
        String actualInvoiceStatus = InvoiceService.computeInvoiceStatus(paymentMethod, initialInvoiceStatus);
        Test.stopTest();

        Assert.areEqual(expectedInvoiceStatus, actualInvoiceStatus);
    }

    @IsTest
    private static void testCalculateInvoiceDueDate_STDPaymentTerm() {
        String paymentTerms = 'STD';

        Date invoiceIssuedDate = Date.newInstance(2022, 10, 5);
        Date expectedDueDate = Date.newInstance(2022, 12, 30);

        Test.startTest();
        Date actualIssuedDate = InvoiceService.calculateInvoiceDueDate(paymentTerms, invoiceIssuedDate);
        Test.stopTest();

        Assert.areEqual(expectedDueDate, actualIssuedDate);
    }

    @IsTest
    private static void testCalculateInvoiceDueDate_TMAPaymentTerm() {
        String paymentTerms = 'TMA';

        Date invoiceIssuedDate = Date.newInstance(2022, 10, 5);
        Date expectedDueDate = Date.newInstance(2022, 12, 31);

        Test.startTest();
        Date actualIssuedDate = InvoiceService.calculateInvoiceDueDate(paymentTerms, invoiceIssuedDate);
        Test.stopTest();

        Assert.areEqual(expectedDueDate, actualIssuedDate);
    }

    @IsTest
    private static void testCalculateInvoiceDueDate_TWAPaymentTerm() {
        String paymentTerms = 'TWA';

        Date invoiceIssuedDate = Date.newInstance(2022, 10, 5);
        Date expectedDueDate = Date.newInstance(2022, 12, 15);

        Test.startTest();
        Date actualIssuedDate = InvoiceService.calculateInvoiceDueDate(paymentTerms, invoiceIssuedDate);
        Test.stopTest();

        Assert.areEqual(expectedDueDate, actualIssuedDate);
    }

    @IsTest
    private static void testCalculateInvoiceDueDate_50DPaymentTerm() {
        String paymentTerms = '50D';

        Date invoiceIssuedDate = Date.newInstance(2022, 10, 5);
        Date expectedDueDate = Date.newInstance(2022, 11, 24);

        Test.startTest();
        Date actualIssuedDate = InvoiceService.calculateInvoiceDueDate(paymentTerms, invoiceIssuedDate);
        Test.stopTest();

        Assert.areEqual(expectedDueDate, actualIssuedDate);
    }

    @IsTest
    private static void testCalculateInvoiceDueDate_21DPaymentTerm() {
        String paymentTerms = '21D';

        Date invoiceIssuedDate = Date.newInstance(2022, 10, 5);
        Date expectedDueDate = Date.newInstance(2022, 10, 26);

        Test.startTest();
        Date actualIssuedDate = InvoiceService.calculateInvoiceDueDate(paymentTerms, invoiceIssuedDate);
        Test.stopTest();

        Assert.areEqual(expectedDueDate, actualIssuedDate);
    }

    @IsTest
    private static void testCreateInvoicesFromOrders_CheckPaymentsLinks() {
        // create product
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(
            new Product2(Name = 'Test Product', ProductCode = 'SKU1')
        );

        // add new product to standard PB
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add products to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        Contact newContact = (Contact) TdfSObjectFactory.insertSObject(
            new Contact(AccountId = dpAccount.Id, Email = 'test@test.com')
        );
        dpAccount.aforza__Primary_Contact__c = newContact.Id;
        update dpAccount;

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID,
                AccountId = dpAccount.Id,
                Status = 'Draft',
                Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(
                OrderId = newOrder.Id,
                Product2Id = newProduct.Id,
                PricebookEntryId = newPricebookEntry.Id
            )
        );

        //insert BT payment
        TdfSObjectFactory.insertSObject(new bt_stripe__Transaction__c(bt_stripe__Related_Account__c = dpAccount.Id,
            RecordTypeId = RecordTypes.BT_TRANSACTION_CHARGE_ID, Order__c = newOrder.Id));

        Test.startTest();
        InvoiceService.createInvoicesFromOrders(new Set<Id>{
            newOrder.Id
        });
        Test.stopTest();

        // get invoice
        aforza__Invoice__c invoice = [SELECT Id, Gross__c FROM aforza__Invoice__c WHERE aforza__Order__c = :newOrder.Id];

        // check that payments are linked (Aforza payment is created when BT is created
        List<bt_stripe__Transaction__c> btTransactions = [SELECT Id, Invoice__c, bt_stripe__Amount_To_Capture__c FROM bt_stripe__Transaction__c WHERE Order__c = :newOrder.Id];
        Assert.isTrue(btTransactions.size() == 1, 'There should be single Payment');
        Assert.areEqual(invoice.Id, btTransactions[0].Invoice__c);
        Assert.areEqual(invoice.Gross__c, btTransactions[0].bt_stripe__Amount_To_Capture__c);

        List<aforza__Payment_Transaction__c> paymentTransactions = [SELECT Id, aforza__Invoice__c, aforza__Amount__c FROM aforza__Payment_Transaction__c];
        Assert.isTrue(paymentTransactions.size() == 1, 'There should be single Payment');
        Assert.areEqual(invoice.Id, paymentTransactions[0].aforza__Invoice__c);
        Assert.areEqual(invoice.Gross__c, paymentTransactions[0].aforza__Amount__c);
    }

    @IsTest
    private static void testComputeInvoiceStatus_CreditCardAccount() {
        String paymentMethod = 'Credit Card';

        String initialInvoiceStatus = null;
        String expectedInvoiceStatus = 'Pending Payment';

        Test.startTest();
        String actualInvoiceStatus = InvoiceService.computeInvoiceStatus(paymentMethod, initialInvoiceStatus);
        Test.stopTest();

        Assert.areEqual(expectedInvoiceStatus, actualInvoiceStatus);
    }
}