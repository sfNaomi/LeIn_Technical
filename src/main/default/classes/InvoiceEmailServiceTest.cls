/**
 * Created by svatopluk.sejkora on 22.11.2022.
 */

@IsTest
private with sharing class InvoiceEmailServiceTest {
    @IsTest
    private static void testEvaluateInvoiceIfToCreatePdfAndSend_MissingInvoiceEmail() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Invoice_Email_Address__c = null)
        );
        Contact contact = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = acc.Id));
        acc.aforza__Primary_Contact__c = contact.Id;
        update acc;

        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(AccountId = acc.Id, PreAuthCaptured__c = false,
            RecordTypeId = RecordTypes.ORDER_EDI_ID, PaymentMethod__c = 'Direct Debit'));

        aforza__Invoice__c invoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(
            new aforza__Invoice__c(aforza__Account__c = acc.Id, aforza__Order__c = newOrder.Id, InvoiceType__c = 'Credit Note')
        );

        // get invoices with data:
        List<aforza__Invoice__c> invoicesWithData = InvoiceEmailService.getInvoicesWithRequiredParameters(
            new Set<Id>{invoice.Id}
        );

        //testing logic to determine if to send or not
        Test.startTest();
        Map<Id, String> evaluatedInvoices = InvoiceEmailService.evaluateInvoiceIfToSendInvoice(invoicesWithData);
        Test.stopTest();

        Assert.isTrue(evaluatedInvoices.size() == 0);
    }

    @IsTest
    private static void testEvaluateInvoiceIfToCreatePdfAndSend_MissingPrimaryContact() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Invoice_Email_Address__c = 'test@test.com')
        );

        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(AccountId = acc.Id, PreAuthCaptured__c = false,
            RecordTypeId = RecordTypes.ORDER_EDI_ID, PaymentMethod__c = 'Direct Debit'));

        aforza__Invoice__c invoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(
            new aforza__Invoice__c(aforza__Account__c = acc.Id, aforza__Order__c = newOrder.Id, InvoiceType__c = 'Credit Note')
        );

        // get invoices with data:
        List<aforza__Invoice__c> invoicesWithData = InvoiceEmailService.getInvoicesWithRequiredParameters(
            new Set<Id>{invoice.Id}
        );

        //testing logic to determine if to send or not
        Test.startTest();
        Map<Id, String> evaluatedInvoices = InvoiceEmailService.evaluateInvoiceIfToSendInvoice(invoicesWithData);
        Test.stopTest();

        Assert.isTrue(evaluatedInvoices.size() == 0);
    }

    @IsTest
    private static void testEvaluateInvoiceIfToCreatePdfAndSend_CreditNote() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Contact contact = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = acc.Id));

        acc.aforza__Primary_Contact__c = contact.Id;
        update acc;

        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(AccountId = acc.Id, PreAuthCaptured__c = false,
                RecordTypeId = RecordTypes.ORDER_EDI_ID, PaymentMethod__c = 'Direct Debit'));

        aforza__Invoice__c newInvoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(
            new aforza__Invoice__c(aforza__Account__c = acc.Id, aforza__Order__c = newOrder.Id, InvoiceType__c = 'Credit Note')
        );

        // get invoices with data:
        List<aforza__Invoice__c> invoicesWithData = InvoiceEmailService.getInvoicesWithRequiredParameters(
            new Set<Id>{newInvoice.Id}
        );

        //testing logic to determine if to send or not
        Test.startTest();
        Map<Id, String> evaluatedInvoices = InvoiceEmailService.evaluateInvoiceIfToSendInvoice(invoicesWithData);
        Test.stopTest();

        Assert.isTrue(evaluatedInvoices.size() == 1);
        Assert.isTrue(evaluatedInvoices.containsKey(newInvoice.Id));
        Assert.areEqual(evaluatedInvoices.get(newInvoice.Id), InvoiceEmailService.CREDIT_NOTE_EMAIL_NAME);
    }

    @IsTest
    private static void testEvaluateInvoiceIfToCreatePdfAndSend_InvoiceDD() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Contact contact = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = acc.Id));
        acc.aforza__Primary_Contact__c = contact.Id;
        update acc;

        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(AccountId = acc.Id, PreAuthCaptured__c = false, RecordTypeId = RecordTypes.ORDER_EDI_ID, PaymentMethod__c = 'Direct Debit'));

        aforza__Invoice__c invoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(new aforza__Invoice__c(aforza__Account__c = acc.Id, aforza__Order__c = order.Id));

        // get invoices with data:
        List<aforza__Invoice__c> invoicesWithData = InvoiceEmailService.getInvoicesWithRequiredParameters(new Set<Id>{
            invoice.Id
        });

        //testing logic to determine if to send or not
        Test.startTest();
        Map<Id, String> evaluatedInvoices = InvoiceEmailService.evaluateInvoiceIfToSendInvoice(invoicesWithData);
        Test.stopTest();

        Assert.isTrue(evaluatedInvoices.size() == 1);
        Assert.isTrue(evaluatedInvoices.containsKey(invoice.Id));
        Assert.areEqual(evaluatedInvoices.get(invoice.Id), InvoiceEmailService.INVOICE_EMAIL_NO_PAYMENT_NAME);
    }

    @IsTest
    private static void testEvaluateInvoiceIfToCreatePdfAndSend_InvoiceCardPayment() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Contact contact = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = acc.Id));
        acc.aforza__Primary_Contact__c = contact.Id;
        update acc;

        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(AccountId = acc.Id, PreAuthCaptured__c = false, RecordTypeId = RecordTypes.ORDER_EDI_ID, PaymentMethod__c = 'Card Payment'));

        aforza__Invoice__c invoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(new aforza__Invoice__c(aforza__Account__c = acc.Id, aforza__Order__c = order.Id, PaymentLink__c = 'link.com'));

        // get invoices with data:
        List<aforza__Invoice__c> invoicesWithData = InvoiceEmailService.getInvoicesWithRequiredParameters(new Set<Id>{
            invoice.Id
        });

        //testing logic to determine if to send or not
        Test.startTest();
        Map<Id, String> evaluatedInvoices = InvoiceEmailService.evaluateInvoiceIfToSendInvoice(invoicesWithData);
        Test.stopTest();

        Assert.isTrue(evaluatedInvoices.size() == 1);
        Assert.isTrue(evaluatedInvoices.containsKey(invoice.Id));
        Assert.areEqual(evaluatedInvoices.get(invoice.Id), InvoiceEmailService.INVOICE_EMAIL_WITH_PAYMENT_NAME);
    }

    @IsTest
    private static void testEvaluateInvoiceIfToCreatePdfAndSend_InvoiceCardPaymentNoLink() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Contact contact = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = acc.Id));
        acc.aforza__Primary_Contact__c = contact.Id;
        update acc;

        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(AccountId = acc.Id, PreAuthCaptured__c = false, RecordTypeId = RecordTypes.ORDER_EDI_ID, PaymentMethod__c = 'Card Payment'));

        aforza__Invoice__c invoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(new aforza__Invoice__c(aforza__Account__c = acc.Id, aforza__Order__c = order.Id));

        // get invoices with data:
        List<aforza__Invoice__c> invoicesWithData = InvoiceEmailService.getInvoicesWithRequiredParameters(new Set<Id>{
            invoice.Id
        });

        //testing logic to determine if to send or not
        Test.startTest();
        Map<Id, String> evaluatedInvoices = InvoiceEmailService.evaluateInvoiceIfToSendInvoice(invoicesWithData);
        Test.stopTest();

        Assert.isTrue(evaluatedInvoices.size() == 0);
    }

    @IsTest
    private static void testEvaluateInvoiceIfToCreatePdfAndSend_InvoiceCardPaymentPreAuth() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Contact contact = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = acc.Id));
        acc.aforza__Primary_Contact__c = contact.Id;
        update acc;

        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(AccountId = acc.Id, PreAuthCaptured__c = true, RecordTypeId = RecordTypes.ORDER_EDI_ID, PaymentMethod__c = 'Card Payment'));

        aforza__Invoice__c invoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(new aforza__Invoice__c(aforza__Account__c = acc.Id, aforza__Order__c = order.Id));

        // get invoices with data:
        List<aforza__Invoice__c> invoicesWithData = InvoiceEmailService.getInvoicesWithRequiredParameters(new Set<Id>{
            invoice.Id
        });

        //testing logic to determine if to send or not
        Test.startTest();
        Map<Id, String> evaluatedInvoices = InvoiceEmailService.evaluateInvoiceIfToSendInvoice(invoicesWithData);
        Test.stopTest();

        Assert.isTrue(evaluatedInvoices.size() == 1);
        Assert.isTrue(evaluatedInvoices.containsKey(invoice.Id));
        Assert.areEqual(evaluatedInvoices.get(invoice.Id), InvoiceEmailService.INVOICE_EMAIL_NO_PAYMENT_NAME);
    }

    @IsTest
    private static void testSendInvoiceToCustomers() {
        // create product
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());

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
                Pricebook2Id = newPricebook.Id,
                PaymentMethod__c = 'Card Payment'
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(
                OrderId = newOrder.Id,
                Product2Id = newProduct.Id,
                PricebookEntryId = newPricebookEntry.Id
            )
        );

        InvoiceSettings__c settings = new InvoiceSettings__c(CreatePaymentWhenInvoiceIsCreated__c = true);
        insert settings;

        Test.startTest();
        InvoiceService.createInvoicesFromOrders(new Set<Id>{newOrder.Id});
        Test.stopTest();

        // check that there is activity created
        // there will be two tasks
        List<Task> relatedActivities = [SELECT Id FROM Task];
        Assert.areEqual(1, relatedActivities.size());
    }

    @IsTest
    private static void testSendInvoiceToCustomers_NoSendAbleType() {
        // create product
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());

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
                Pricebook2Id = newPricebook.Id,
                PaymentMethod__c = 'Cash'
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(
                OrderId = newOrder.Id,
                Product2Id = newProduct.Id,
                PricebookEntryId = newPricebookEntry.Id
            )
        );

        InvoiceSettings__c settings = new InvoiceSettings__c(CreatePaymentWhenInvoiceIsCreated__c = true);
        insert settings;

        Test.startTest();
        InvoiceService.createInvoicesFromOrders(new Set<Id>{
            newOrder.Id
        });
        Test.stopTest();

        // check that there is no activity created
        List<Task> relatedActivities = [SELECT Id FROM Task];
        Assert.areEqual(0, relatedActivities.size());
    }
}