/**
 * Created by svatopluk.sejkora on 16.11.2022.
 */


@IsTest
private with sharing class InvoiceTriggerHandlerTest {

    @IsTest
    private static void testCreateTransactionRecord() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Contact contact = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = acc.Id));
        acc.aforza__Primary_Contact__c = contact.Id;
        update acc;
        TdfSObjectFactory.insertSObject(new aforza__Payment_Method__c(RecordTypeId = RecordTypes.PAYMENT_METHOD_CREDIT_CARD_ID,
            aforza__Account__c = acc.Id));

        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(AccountId = acc.Id, PreAuthCaptured__c = false, RecordTypeId = RecordTypes.ORDER_EDI_ID));

        TdfSObjectFactory.insertSObject(new aforza__Invoice__c(aforza__Account__c = acc.Id, aforza__Order__c = order.Id));

        aforza__Invoice__c invoiceWithData = [
            SELECT Id, aforza__Order__r.PaymentMethod__c, aforza__Order__r.PreAuthCaptured__c,
                aforza__Order__r.RecordType.DeveloperName, Gross__c, aforza__Account__r.aforza__Primary_Contact__c,
                aforza__Account__c, aforza__Order__c, aforza__Order__r.OrderNumber
            FROM aforza__Invoice__c
            LIMIT 1
        ];

        Test.startTest();
        bt_stripe__Transaction__c btTransaction = InvoiceTriggerHandler.createTransactionRecord(invoiceWithData, null);
        Test.stopTest();

        Assert.areEqual(RecordTypes.BT_TRANSACTION_CHARGE_ID, btTransaction.RecordTypeId);
        Assert.areEqual(invoiceWithData.Gross__c, btTransaction.bt_stripe__Amount__c);
        Assert.isTrue(btTransaction.bt_stripe__Description__c.contains('Payment Request for'));
        Assert.areEqual('Normal', btTransaction.bt_stripe__Transaction_Type__c);
        Assert.areEqual('Open', btTransaction.bt_stripe__Transaction_Status__c);
        Assert.areEqual(invoiceWithData.aforza__Account__r.aforza__Primary_Contact__c, btTransaction.bt_stripe__Related_Contact__c);
        Assert.areEqual(invoiceWithData.aforza__Account__c, btTransaction.bt_stripe__Related_Account__c);
        Assert.areEqual(invoiceWithData.aforza__Order__c, btTransaction.Order__c);
        Assert.areEqual(invoiceWithData.Id, btTransaction.Invoice__c);
    }

    @IsTest
    private static void testUpdatePaymentTransactionsForFailedInvoices() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(AccountId = acc.Id, PreAuthCaptured__c = false, RecordTypeId = RecordTypes.ORDER_EDI_ID));
        aforza__Invoice__c invoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(new aforza__Invoice__c(aforza__Account__c = acc.Id, aforza__Order__c = order.Id, aforza__Status__c = 'Approved for Payment'));
        TdfSObjectFactory.insertSObject(new aforza__Payment_Transaction__c(aforza__Invoice__c = invoice.Id, aforza__Status__c = 'Applied'));

        Test.startTest();
        invoice.aforza__Status__c = 'Payment Attempt Unsuccessful';
        update invoice;
        Test.stopTest();

        aforza__Payment_Transaction__c pTransaction = [
            SELECT Id, aforza__Status__c
            FROM aforza__Payment_Transaction__c
            WHERE aforza__Invoice__c = :invoice.Id
            LIMIT 1
        ];
        Assert.areEqual('Rejected', pTransaction.aforza__Status__c);
    }

    @IsTest
    private static void testUpdatePaymentTransactionsForSuccessInvoices() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(AccountId = acc.Id, PreAuthCaptured__c = false, RecordTypeId = RecordTypes.ORDER_EDI_ID));
        aforza__Invoice__c invoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(new aforza__Invoice__c(aforza__Account__c = acc.Id, aforza__Order__c = order.Id, aforza__Status__c = 'Cash in Transit'));
        TdfSObjectFactory.insertSObject(new aforza__Payment_Transaction__c(aforza__Invoice__c = invoice.Id, aforza__Status__c = 'Pending'));

        Test.startTest();
        invoice.aforza__Status__c = 'Paid in Full';
        update invoice;
        Test.stopTest();

        aforza__Payment_Transaction__c pTransaction = [
            SELECT Id, aforza__Status__c
            FROM aforza__Payment_Transaction__c
            WHERE aforza__Invoice__c = :invoice.Id
            LIMIT 1
        ];
        Assert.areEqual('Applied', pTransaction.aforza__Status__c);
    }

    @IsTest
    private static void testCreateTransactions() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Contact contact = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = acc.Id));
        acc.aforza__Primary_Contact__c = contact.Id;
        update acc;
        TdfSObjectFactory.insertSObject(new aforza__Payment_Method__c(RecordTypeId = RecordTypes.PAYMENT_METHOD_CREDIT_CARD_ID,
            aforza__Account__c = acc.Id));

        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(AccountId = acc.Id, PreAuthCaptured__c = false, RecordTypeId = RecordTypes.ORDER_EDI_ID, PaymentMethod__c = 'Card Payment'));

        InvoiceSettings__c settings = new InvoiceSettings__c(CreatePaymentWhenInvoiceIsCreated__c = true);
        insert settings;

        Test.startTest();
        InvoiceService.createInvoicesFromOrders(new Set<Id>{
            order.Id
        });
        Test.stopTest();

        // get invoice created
        aforza__Invoice__c invoice = [SELECT Id FROM aforza__Invoice__c];
        Assert.isTrue(invoice != null);

        // get transaction created
        bt_stripe__Transaction__c btTransaction = [SELECT Id, bt_paylink__PayLink__c, Invoice__c FROM bt_stripe__Transaction__c LIMIT 1];

        Assert.isTrue(btTransaction != null);
        Assert.isTrue(String.isNotEmpty(btTransaction.bt_paylink__PayLink__c));
        Assert.areEqual(invoice.Id, btTransaction.Invoice__c);
    }

    @IsTest
    private static void testCreateTransactions_Commerce() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Contact contact = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = acc.Id));
        acc.aforza__Primary_Contact__c = contact.Id;
        update acc;
        TdfSObjectFactory.insertSObject(new aforza__Payment_Method__c(RecordTypeId = RecordTypes.PAYMENT_METHOD_CREDIT_CARD_ID, aforza__Account__c = acc.Id));

        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(AccountId = acc.Id, PreAuthCaptured__c = false, RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID, PaymentMethod__c = 'Card Payment'));

        InvoiceSettings__c settings = new InvoiceSettings__c(PaymentCommerceOnInvoice__c = true);
        insert settings;

        Test.startTest();
        InvoiceService.createInvoicesFromOrders(new Set<Id>{
            order.Id
        });
        Test.stopTest();

        // get invoice created
        aforza__Invoice__c invoice = [SELECT Id FROM aforza__Invoice__c];
        Assert.isTrue(invoice != null);

        // get transaction created
        bt_stripe__Transaction__c btTransaction = [SELECT Id, bt_paylink__PayLink__c, Invoice__c FROM bt_stripe__Transaction__c LIMIT 1];

        Assert.isTrue(btTransaction != null);
        Assert.isTrue(String.isNotEmpty(btTransaction.bt_paylink__PayLink__c));
        Assert.areEqual(invoice.Id, btTransaction.Invoice__c);
    }

    @IsTest
    private static void testCreateTransactions_CommerceNotAllowed() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PrimaryPaymentMethod__c = 'Card Payment'));
        Contact contact = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = acc.Id));
        acc.aforza__Primary_Contact__c = contact.Id;
        update acc;
        TdfSObjectFactory.insertSObject(new aforza__Payment_Method__c(RecordTypeId = RecordTypes.PAYMENT_METHOD_CREDIT_CARD_ID,
            aforza__Account__c = acc.Id));

        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(AccountId = acc.Id, PreAuthCaptured__c = false, RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID));

        //do not create custom settings

        Test.startTest();
        InvoiceService.createInvoicesFromOrders(new Set<Id>{
            order.Id
        });
        Test.stopTest();

        // get invoice created
        aforza__Invoice__c invoice = [SELECT Id FROM aforza__Invoice__c];
        Assert.isTrue(invoice != null);

        // get transaction created
        List<bt_stripe__Transaction__c> btTransaction = [SELECT Id, bt_paylink__PayLink__c, Invoice__c FROM bt_stripe__Transaction__c];

        Assert.isTrue(btTransaction.size() == 0);
    }

    @IsTest
    private static void testCreateTransactionRecord_Refund() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Contact contact = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = acc.Id));
        acc.aforza__Primary_Contact__c = contact.Id;
        update acc;
        TdfSObjectFactory.insertSObject(new aforza__Payment_Method__c(RecordTypeId = RecordTypes.PAYMENT_METHOD_CREDIT_CARD_ID,
            aforza__Account__c = acc.Id));

        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(AccountId = acc.Id, PreAuthCaptured__c = false,
            RecordTypeId = RecordTypes.ORDER_EDI_ID, PaymentMethod__c = 'Card Payment'));
        TdfSObjectFactory.insertSObject(new Order(AccountId = acc.Id, PreAuthCaptured__c = false,
            RecordTypeId = RecordTypes.ORDER_RETURN_ID, aforza__Original_Order__c = order.Id, PaymentMethod__c = 'Card Payment'));

        InvoiceSettings__c settings = new InvoiceSettings__c(CreatePaymentWhenInvoiceIsCreated__c = true);
        insert settings;

        bt_stripe__Transaction__c originalTransaction = (bt_stripe__Transaction__c) TdfSObjectFactory.insertSObject(
            new bt_stripe__Transaction__c(bt_stripe__Related_Account__c = acc.Id, bt_stripe__Related_Contact__c = contact.Id,
                RecordTypeId = RecordTypes.BT_TRANSACTION_CHARGE_ID));

        TdfSObjectFactory.insertSObject(new aforza__Invoice__c(aforza__Account__c = acc.Id, aforza__Order__c = order.Id));

        aforza__Invoice__c invoiceWithData = [
            SELECT Id, aforza__Order__r.PaymentMethod__c, aforza__Order__r.PreAuthCaptured__c,
                aforza__Order__r.RecordType.DeveloperName, Gross__c, aforza__Account__r.aforza__Primary_Contact__c,
                aforza__Account__c, aforza__Order__c, aforza__Order__r.OrderNumber, PaymentLink__c,
                aforza__Order__r.aforza__Original_Order__r.PaymentMethod__c, aforza__Order__r.aforza__Original_Order__c
            FROM aforza__Invoice__c
            LIMIT 1
        ];

        Test.startTest();
        bt_stripe__Transaction__c btTransaction = InvoiceTriggerHandler.createTransactionRecord(invoiceWithData, originalTransaction);
        Test.stopTest();

        Assert.areEqual(RecordTypes.BT_TRANSACTION_CHARGE_ID, btTransaction.RecordTypeId);
        Assert.areEqual(invoiceWithData.Gross__c, btTransaction.bt_stripe__Amount__c);
        Assert.areEqual('Refund', btTransaction.bt_stripe__Transaction_Type__c);
        Assert.areEqual('Open', btTransaction.bt_stripe__Transaction_Status__c);
        Assert.areEqual(invoiceWithData.Id, btTransaction.Invoice__c);
        Assert.areEqual(invoiceWithData.aforza__Order__r.aforza__Original_Order__c, btTransaction.Order__c);
        Assert.areEqual(originalTransaction.Id, btTransaction.bt_stripe__Parent_Transaction__c);
        Assert.areEqual(originalTransaction.Id, btTransaction.bt_stripe__Parent_Transaction_Id__c);
        Assert.areEqual(originalTransaction.bt_stripe__Payment_Method_Billing_Email__c, btTransaction.bt_stripe__Payment_Method_Billing_Email__c);
        Assert.areEqual(originalTransaction.bt_stripe__Stripe_Customer__c, btTransaction.bt_stripe__Stripe_Customer__c);
        Assert.areEqual(originalTransaction.bt_stripe__Related_Contact__c, btTransaction.bt_stripe__Related_Contact__c);
        Assert.areEqual(originalTransaction.bt_stripe__Related_Account__c, btTransaction.bt_stripe__Related_Account__c);
        Assert.areEqual(originalTransaction.bt_stripe__Payment_Method__c, btTransaction.bt_stripe__Payment_Method__c);
    }

    @IsTest
    private static void testCreateTransactions_Refund() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Contact contact = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = acc.Id));
        acc.aforza__Primary_Contact__c = contact.Id;
        update acc;
        TdfSObjectFactory.insertSObject(new aforza__Payment_Method__c(RecordTypeId = RecordTypes.PAYMENT_METHOD_CREDIT_CARD_ID,
            aforza__Account__c = acc.Id));

        // create products
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(
            new Product2(Name = 'Test Product', aforza__Weight__c = 1.5)
        );

        // add new products to standard PB
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create custom pricebook and add products to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry product1PricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create inventory and add products to inventory
        TdfSObjectFactory.insertSObject(
            new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID)
        );

        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(AccountId = acc.Id, PreAuthCaptured__c = false,
            RecordTypeId = RecordTypes.ORDER_EDI_ID, PaymentMethod__c = 'Card Payment', Pricebook2Id = newPricebook.Id));
        Order refundOrder = (Order) TdfSObjectFactory.insertSObject(new Order(AccountId = acc.Id, PreAuthCaptured__c = false,
            RecordTypeId = RecordTypes.ORDER_RETURN_ID, aforza__Original_Order__c = order.Id, PaymentMethod__c = 'Card Payment',
            Pricebook2Id = newPricebook.Id));

        TdfSObjectFactory.insertSObject(
            new OrderItem(
                OrderId = refundOrder.Id,
                Product2Id = newProduct.Id,
                Quantity = 10,
                UnitPrice = -32,
                PricebookEntryId = product1PricebookEntry.Id
            )
        );

        InvoiceService.createInvoicesFromOrders(new Set<Id>{
            order.Id
        });

        Test.startTest();
        //InvoiceService.createInvoicesFromOrders(new Set<Id>{refundOrder.Id});
        Test.stopTest();

        //TODO once BT can tell us why the marking of the transaction as refund == true is giving null we can fix tests
        /*// get invoice created
        aforza__Invoice__c invoice = [SELECT Id FROM aforza__Invoice__c WHERE aforza__Order__c = :refundOrder.Id];
        Assert.isTrue(invoice != null);

        // get transaction created
        bt_stripe__Transaction__c btTransaction = [SELECT Id, Order__c, Invoice__c FROM bt_stripe__Transaction__c WHERE bt_stripe__Transaction_Type__c = 'Refund'];

        Assert.isTrue(btTransaction != null);
        Assert.areEqual(invoice.Id, btTransaction.Invoice__c);
        Assert.areEqual(refundOrder.Id, btTransaction.Order__c);*/
    }

    @IsTest
    private static void testCreateTransactions_JdeReturn() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Contact contact = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = acc.Id));
        acc.aforza__Primary_Contact__c = contact.Id;
        update acc;
        TdfSObjectFactory.insertSObject(new aforza__Payment_Method__c(RecordTypeId = RecordTypes.PAYMENT_METHOD_CREDIT_CARD_ID, aforza__Account__c = acc.Id));

        // create products
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(
            new Product2(Name = 'Test Product', aforza__Weight__c = 1.5)
        );

        // add new products to standard PB
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create custom pricebook and add products to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry product1PricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create inventory and add products to inventory
        TdfSObjectFactory.insertSObject(
            new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID)
        );

        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(AccountId = acc.Id, PreAuthCaptured__c = false,
            RecordTypeId = RecordTypes.ORDER_EDI_ID, PaymentMethod__c = 'Card Payment', Pricebook2Id = newPricebook.Id));
        // add transaction to the Order
        TdfSObjectFactory.insertSObject(new bt_stripe__Transaction__c(Order__c = order.Id, RecordTypeId = RecordTypes.BT_TRANSACTION_CHARGE_ID));

        Order refundOrder = (Order) TdfSObjectFactory.insertSObject(new Order(AccountId = acc.Id, PreAuthCaptured__c = false,
            RecordTypeId = RecordTypes.ORDER_STRAIGHT_TO_JDE_ID, Type = 'Return Order', aforza__Original_Order__c = order.Id, PaymentMethod__c = 'Card Payment',
            Pricebook2Id = newPricebook.Id));

        TdfSObjectFactory.insertSObject(
            new OrderItem(
                OrderId = refundOrder.Id,
                Product2Id = newProduct.Id,
                Quantity = 10,
                UnitPrice = -32,
                PricebookEntryId = product1PricebookEntry.Id
            )
        );

        Test.startTest();
        //InvoiceService.createInvoicesFromOrders(new Set<Id>{refundOrder.Id});
        Test.stopTest();
        //TODO once BT can tell us why the marking of the transaction as refund == true is giving null we can fix tests
        /*// get invoice created
        aforza__Invoice__c invoice = [SELECT Id FROM aforza__Invoice__c];
        Assert.isTrue(invoice != null);

        // get transaction created
        bt_stripe__Transaction__c btTransaction = [SELECT Id, bt_paylink__PayLink__c, Invoice__c FROM bt_stripe__Transaction__c LIMIT 1];

        Assert.isTrue(btTransaction != null);
        Assert.isTrue(String.isNotEmpty(btTransaction.bt_paylink__PayLink__c));
        Assert.areEqual(invoice.Id, btTransaction.Invoice__c);*/
    }

}