/**
 * Created by magdalena.stanciu on 14.09.2022.
 */

@IsTest
private with sharing class OrderTriggerHandlerTest {
    @IsTest
    private static void testValidateOrderCreation_ProspectAccountNewOrder() {
        // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                AccountStatus__c = 'Prospect',
                LastOrderDate__c = null
            )
        );

        // create order
        Test.startTest();
        try {
            Order newOrder = (Order) TdfSObjectFactory.insertSObject(
                new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id)
            );
        } catch (Exception ex) {
            // check that validation is fired
            String expectedErrorMessage = Label.OrderCreationActivationIsNotAllowedForCurrentAccountStatus;
            System.assertEquals(true, ex.getMessage().contains(expectedErrorMessage), 'Expecting error to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidateOrderCreation_ActiveProspectAccountNewTelesalesOrder() {
        // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                AccountStatus__c = 'Active Prospect',
                LastOrderDate__c = null
            )
        );

        // create order
        Test.startTest();
        try {
            Order newOrder = (Order) TdfSObjectFactory.insertSObject(
                new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id)
            );
        } catch (Exception ex) {
            // check that validation is fired
            String expectedErrorMessage = Label.OrderCreationActivationIsNotAllowedForCurrentAccountStatus;
            System.assertEquals(true, ex.getMessage().contains(expectedErrorMessage), 'Expecting error to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidateOrderCreation_ActiveProspectAccountNewDraftFieldDirectOrder() {
        // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                AccountStatus__c = 'Active Prospect',
                LastOrderDate__c = null
            )
        );

        // create order and complete it
        Test.startTest();
        try {
            Order newOrder = (Order) TdfSObjectFactory.insertSObject(
                new Order(RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID, AccountId = dpAccount.Id)
            );
        } catch (Exception ex) {
            // check that validation is not fired
            System.assertEquals(null, ex.getMessage(), 'No error expected.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testUpdateLastOrderDateAndStatusOnParentAccount_TradersAccountNewDraftFDOrderIsCreated() {
        // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                AccountStatus__c = 'Traders',
                LastOrderDate__c = null
            )
        );

        // create and complete order
        Test.startTest();
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID, AccountId = dpAccount.Id)
        );
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
            SELECT Id, AccountStatus__c, LastOrderdate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        // check results
        System.assertEquals('Traders', updatedDPAccount.AccountStatus__c, 'Expecting a different account status.');
        System.assertEquals(null, updatedDPAccount.LastOrderDate__c, 'Expecting a different last order date.');
    }

    @IsTest
    private static void testUpdateLastOrderDateAndStatusOnParentAccount_TradersAccountNewDraftFDOrderIsCompleted() {
        // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                AccountStatus__c = 'Traders',
                LastOrderDate__c = null
            )
        );

        // create product
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product'));

        // create order, add products and complete it
        Test.startTest();
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID, AccountId = dpAccount.Id)
        );

        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id)
        );

        newOrder.Status = new List<String>(OrderService.COMPLETED_ORDER_STATUSES).get(0);
        update newOrder;
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
            SELECT Id, AccountStatus__c, LastOrderdate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        // check results
        System.assertEquals('Traders', updatedDPAccount.AccountStatus__c, 'Expecting a different account status.');
        System.assertEquals(
            newOrder.EffectiveDate,
            updatedDPAccount.LastOrderDate__c,
            'Expecting a different last order date.'
        );
    }

    @IsTest
    private static void testUpdateLastOrderDateAndStatusOnParentAccount_AtRiskAccountDraftTelesalesOrderIsCompleted() {
        // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                AccountStatus__c = 'At Risk',
                LastOrderDate__c = null
            )
        );

        // create product
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product'));

        // create order, add products and complete it
        Test.startTest();
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id)
        );

        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id)
        );

        newOrder.Status = new List<String>(OrderService.COMPLETED_ORDER_STATUSES).get(0);
        update newOrder;
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
            SELECT Id, AccountStatus__c, LastOrderdate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        // check results
        System.assertEquals('Traders', updatedDPAccount.AccountStatus__c, 'Expecting a different account status.');
        System.assertEquals(
            newOrder.EffectiveDate,
            updatedDPAccount.LastOrderDate__c,
            'Expecting a different last order date.'
        );
    }

    @IsTest
    private static void testCloneCompletedOrder() {
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_EDI_ID, AccountId = dpAccount.Id, Status = 'Draft')
        );
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product'));
        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id)
        );

        Test.startTest();
        newOrder.Status = new List<String>(OrderService.COMPLETED_ORDER_STATUSES).get(0);
        update newOrder;
        Test.stopTest();

        Order clonedOrder = [SELECT Id, Clone__c, aforza__Original_Order__c, Status FROM Order WHERE Clone__c = TRUE];
        System.assertEquals(
            newOrder.Id,
            clonedOrder.aforza__Original_Order__c,
            'Expected a different original order Id.'
        );
        System.assertEquals('Draft', clonedOrder.Status, 'Expected a different order status for the clone.');

        List<OrderItem> clonedOrderItems = [
            SELECT Id, OrderId, Product2Id
            FROM OrderItem
            WHERE OrderId = :clonedOrder.Id
        ];
        System.assertEquals(1, clonedOrderItems.size(), 'Expected one order item for the cloned order');
    }

    @IsTest
    private static void testCloneCompletedOrder_NoCloneCreated() {
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_EDI_ID, AccountId = dpAccount.Id, Status = 'Draft')
        );
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product'));
        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id)
        );

        Test.startTest();
        newOrder.Status = 'Awaiting Approval';
        update newOrder;
        Test.stopTest();

        List<Order> clonedOrder = [SELECT Id, Clone__c, aforza__Original_Order__c, Status FROM Order WHERE Clone__c = TRUE];
        System.assertEquals(0, clonedOrder.size(), 'Expected no clone orders to be created');
    }

    @IsTest
    private static void testCreateInvoice_ValidOrderRecordType() {
        // create dp acccount
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );

        // create related order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
        );

        // create product and order product
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product'));
        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id)
        );

        // mark order as receipted
        Test.startTest();
        newOrder.Status = 'Receipted';
        update newOrder;
        Test.stopTest();

        // retrieve invoice and invoice line items, validate results
        List<aforza__Invoice__c> invoices = [SELECT Id FROM aforza__Invoice__c WHERE aforza__Order__c = :newOrder.Id];
        List<aforza__Invoice_Line_Item__c> invoiceLineItems = [SELECT Id FROM aforza__Invoice_Line_Item__c WHERE aforza__Invoice__c IN :invoices];
        System.assertEquals(1, invoices.size(), 'Expected invoice to be created');
        System.assertEquals(1, invoiceLineItems.size(), 'Expected invoice line items to be created');
    }

    @IsTest
    private static void testCreateInvoice_InvalidOrderRecordType() {
        // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );

        // create related order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
                new Order(RecordTypeId = RecordTypes.ORDER_VAN_SALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
        );

        // create product and order product
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product'));
        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
                new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id)
        );

        // mark order as receipted
        Test.startTest();
        newOrder.Status = 'Receipted';
        update newOrder;
        Test.stopTest();

        // retrieve invoice and invoice line items, validate results
        List<aforza__Invoice__c> invoices = [SELECT Id FROM aforza__Invoice__c WHERE aforza__Order__c = :newOrder.Id];
        List<aforza__Invoice_Line_Item__c> invoiceLineItems = [SELECT Id FROM aforza__Invoice_Line_Item__c WHERE aforza__Invoice__c IN :invoices];
        System.assertEquals(0, invoices.size(), 'Expected no invoice to be created');
        System.assertEquals(0, invoiceLineItems.size(), 'Expected no invoice line items to be created');
    }

    @IsTest
    private static void testCreateInvoice_OrderWithPayment() {
        // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );

        // create related order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
                new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
        );

        // create product and order product
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product'));
        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
                new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id)
        );

        // create Payment
        aforza__Payment_Transaction__c newPayment = (aforza__Payment_Transaction__c) TdfSObjectFactory.insertSObject(
                new aforza__Payment_Transaction__c(aforza__Account__c = dpAccount.Id, OrderNumber__c = newOrder.Id)
        );

        // mark order as receipted
        Test.startTest();
        newOrder.Status = 'Receipted';
        update newOrder;
        Test.stopTest();

        // retrieve invoice and invoice line items, validate results
        List<aforza__Invoice__c> invoices = [SELECT Id FROM aforza__Invoice__c WHERE aforza__Order__c = :newOrder.Id];
        List<aforza__Invoice_Line_Item__c> invoiceLineItems = [SELECT Id FROM aforza__Invoice_Line_Item__c WHERE aforza__Invoice__c IN :invoices];
        System.assertEquals(1, invoices.size(), 'Expected invoice to be created');
        System.assertEquals(1, invoiceLineItems.size(), 'Expected invoice line items to be created');

        // retrive payment and validate result
        List<aforza__Payment_Transaction__c> transactions = [SELECT Id, aforza__Invoice__c FROM aforza__Payment_Transaction__c WHERE Id = :newPayment.Id];
        System.assertEquals(invoices[0].Id, transactions[0].aforza__Invoice__c, 'Expecting transaction to be linked to the created invoice');
    }

    @IsTest
    private static void testCreateInvoice_ExistingInvoice() {
        // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );

        // create related order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
                new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
        );

        // create product and order product
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product'));
        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
                new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id)
        );

        // create Invoice
        aforza__Invoice__c newInvoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(
                new aforza__Invoice__c(aforza__Account__c = dpAccount.Id, aforza__Order__c = newOrder.Id)
        );

        // mark order as receipted
        Test.startTest();
        newOrder.Status = 'Receipted';
        update newOrder;
        Test.stopTest();

        // retrieve invoice and invoice line items, validate results
        List<aforza__Invoice__c> invoices = [SELECT Id FROM aforza__Invoice__c WHERE aforza__Order__c = :newOrder.Id];
        List<aforza__Invoice_Line_Item__c> invoiceLineItems = [SELECT Id FROM aforza__Invoice_Line_Item__c WHERE aforza__Invoice__c IN :invoices];
        System.assertEquals(1, invoices.size(), 'Expected existing invoice to be updated');
        System.assertEquals(1, invoiceLineItems.size(), 'Expected invoice line items to be created');
    }
}
