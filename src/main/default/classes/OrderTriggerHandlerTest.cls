/**
 * Created by magdalena.stanciu on 14.09.2022.
 */

@IsTest
private with sharing class OrderTriggerHandlerTest {

    @TestSetup
    private static void recalculatePermSetGroups() {
        PermissionSetGroup adminPermSetGroup = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'Administrator'][0];

        Test.calculatePermissionSetGroup(new Id[]{
                adminPermSetGroup.Id
        });
    }

    @IsTest
    private static void validateOrderCreationOrCompletion_ProspectAccountNewOrder() {
         // create attribute for New DP attribute flow automation
         TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                AccountStatus__c = 'Prospect', LastOrderDate__c = null
            )
        );

        // create order
        Test.startTest();
        try {
            TdfSObjectFactory.insertSObject(
                new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id)
            );
            System.assert(false);
        } catch (Exception ex) {
            // check that validation is fired
            String expectedErrorMessage = Label.OrderCreationActivationIsNotAllowedForCurrentAccountStatus;
            System.assertEquals(true, ex.getMessage().contains(expectedErrorMessage), 'Expecting error to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void validateOrderCreationOrCompletion_ActiveProspectAccountNewTelesalesOrder() {
        // create attribute for New DP attribute flow automation
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                AccountStatus__c = 'Active Prospect', LastOrderDate__c = null
            )
        );

        // create order & check that validation is not fired
        Test.startTest();
        try {
            TdfSObjectFactory.insertSObject(
                new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id)
            );
            System.assert(true);
        } catch (Exception ex) {
            System.assert(false);
        }
        Test.stopTest();
    }

    @IsTest
    private static void validateOrderCreationOrCompletion_ActiveProspectAccountNewDraftFieldDirectOrder() {
        // create attribute for New DP attribute flow automation
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                AccountStatus__c = 'Active Prospect', LastOrderDate__c = null
            )
        );

        // create order & check that validation is not fired
        Test.startTest();
        try {
            TdfSObjectFactory.insertSObject(
                new Order(RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID, AccountId = dpAccount.Id)
            );
            System.assert(true);
        } catch (Exception ex) {
            System.assert(false);
        }
        Test.stopTest();
    }

    @IsTest
    private static void testUpdateLastOrderDateAndStatusOnParentAccount_TradersAccountNewDraftFDOrderIsCreated() {
        // create attribute for New DP attribute flow automation
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                AccountStatus__c = 'Traders', LastOrderDate__c = null
            )
        );

        // create order
        Test.startTest();
        TdfSObjectFactory.insertSObject(
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
        // create attribute for New DP attribute flow automation
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

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
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        // complete order
        Test.startTest();
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
        System.assertEquals(newOrder.EffectiveDate, updatedDPAccount.LastOrderDate__c, 'Expecting a different last order date.');
    }

    @IsTest
    private static void testUpdateLastOrderDateAndStatusOnParentAccount_AtRiskAccountDraftTelesalesOrderIsCompleted() {
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
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'At Risk',
                LastOrderDate__c = null, aforza__Default_Price_Book__c = newPricebook.Id
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

        // complete order
        Test.startTest();
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
        System.assertEquals(newOrder.EffectiveDate, updatedDPAccount.LastOrderDate__c, 'Expecting a different last order date.');
    }

    @IsTest
    private static void testCloneCompletedOrder() {
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

    @IsTest
    private static void testCloneCompletedOrder_NoCloneCreated() {
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
        newOrder.Status = 'Awaiting Approval';
        update newOrder;
        Test.stopTest();

        List<Order> clonedOrder = [
            SELECT Id, Clone__c, aforza__Original_Order__c, Status
            FROM Order
            WHERE Clone__c = TRUE
        ];
        System.assertEquals(0, clonedOrder.size(), 'Expected no clone orders to be created');
    }

    @IsTest
    private static void testCreateInvoice_ValidOrderRecordType() {
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
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        // mark order as receipted
        Test.startTest();
        newOrder.Status = 'Receipted';
        update newOrder;
        Test.stopTest();

        // retrieve invoice and invoice line items, validate results
        List<aforza__Invoice__c> invoices = [
            SELECT Id
            FROM aforza__Invoice__c
            WHERE aforza__Order__c = :newOrder.Id
        ];
        List<aforza__Invoice_Line_Item__c> invoiceLineItems = [
            SELECT Id FROM aforza__Invoice_Line_Item__c
            WHERE aforza__Invoice__c
            IN :invoices
        ];

        System.assertEquals(1, invoices.size(), 'Expected invoice to be created');
        System.assertEquals(1, invoiceLineItems.size(), 'Expected invoice line items to be created');
    }

    @IsTest
    private static void testCreateInvoice_InvalidOrderRecordType() {
        // create attribute for New DP attribute flow automation
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

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
                RecordTypeId = RecordTypes.ORDER_VAN_SALES_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        // mark order as receipted
        Test.startTest();
        newOrder.Status = 'Receipted';
        update newOrder;
        Test.stopTest();

        // retrieve invoice and invoice line items, validate results
        List<aforza__Invoice__c> invoices = [
            SELECT Id
            FROM aforza__Invoice__c
            WHERE aforza__Order__c = :newOrder.Id
        ];
        List<aforza__Invoice_Line_Item__c> invoiceLineItems = [
            SELECT Id
            FROM aforza__Invoice_Line_Item__c
            WHERE aforza__Invoice__c IN :invoices
        ];

        System.assertEquals(0, invoices.size(), 'Expected no invoice to be created');
        System.assertEquals(0, invoiceLineItems.size(), 'Expected no invoice line items to be created');
    }

    @IsTest
    private static void testCreateInvoice_OrderWithPayment() {
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
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
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
        List<aforza__Invoice__c> invoices = [
            SELECT Id
            FROM aforza__Invoice__c
            WHERE aforza__Order__c = :newOrder.Id
        ];
        List<aforza__Invoice_Line_Item__c> invoiceLineItems = [
            SELECT Id
            FROM aforza__Invoice_Line_Item__c
            WHERE aforza__Invoice__c IN :invoices
        ];

        System.assertEquals(1, invoices.size(), 'Expected invoice to be created');
        System.assertEquals(1, invoiceLineItems.size(), 'Expected invoice line items to be created');

        // retrieve payment and validate result
        List<aforza__Payment_Transaction__c> transactions = [
            SELECT Id, aforza__Invoice__c
            FROM aforza__Payment_Transaction__c
            WHERE Id = :newPayment.Id
        ];
        System.assertEquals(invoices[0].Id, transactions[0].aforza__Invoice__c, 'Expecting transaction to be linked to invoice');
    }

    @IsTest
    private static void testCreateInvoice_ExistingInvoice() {
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
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        // create Invoice
        TdfSObjectFactory.insertSObject(
            new aforza__Invoice__c(aforza__Account__c = dpAccount.Id, aforza__Order__c = newOrder.Id)
        );

        // mark order as receipted
        Test.startTest();
        newOrder.Status = 'Receipted';
        update newOrder;
        Test.stopTest();

        // retrieve invoice and invoice line items, validate results
        List<aforza__Invoice__c> invoices = [
            SELECT Id FROM aforza__Invoice__c
            WHERE aforza__Order__c = :newOrder.Id
        ];
        List<aforza__Invoice_Line_Item__c> invoiceLineItems = [
            SELECT Id FROM aforza__Invoice_Line_Item__c
            WHERE aforza__Invoice__c IN :invoices
        ];

        System.assertEquals(1, invoices.size(), 'Expected existing invoice to be updated');
        System.assertEquals(1, invoiceLineItems.size(), 'Expected invoice line items to be created');
    }

    @IsTest
    private static void testPreventOrderActivation_DPOnHoldAndRTTelesales() {
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
                LastOrderDate__c = null, CreditStatus__c = 'On Hold', aforza__Default_Price_Book__c = newPricebook.Id
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
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            System.assert(false);
        } catch (Exception e) {
            String expectedErrorMessage = Label.OrderActivationPreventedDueToDPOnHold;
            System.assertEquals(true, e.getMessage().contains(expectedErrorMessage), 'Expecting error to be thrown.');
        }
        Test.stopTest();

    }

    @IsTest
    private static void testPreventOrderActivation_DPNegativeCreditAndRTEDI() {
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
                LastOrderDate__c = null, aforza__Credit_Amount__c = 100, aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        AccountTeamMember atm = (AccountTeamMember) TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = dpAccount.Id, TeamMemberRole = 'TAM')
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

        // create invoice
        TdfSObjectFactory.insertSObject(
            new aforza__Invoice__c(
                aforza__Reference__c= '10', aforza__Account__c = dpAccount.Id, aforza__Order__c = newOrder.Id,
                aforza__Status__c ='Outstanding', aforza__Amount_Due__c = 300
            )
        );

        Test.startTest();
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            System.assert(false);
        } catch (Exception e) {
            String expectedErrorMessage = Label.OrderActivationPreventedDueToDPNegativeCredit;
            System.assertEquals(true, e.getMessage().contains(expectedErrorMessage), 'Expecting error to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testPopulateLoadWhenAllLInkedOrdersShareStatus() {
        // prepare orders and assign them to load
        Load__c load = (Load__c) TdfSObjectFactory.insertSObject(new Load__c());
        List<Order> orders = (List<Order>) TdfSObjectFactory.insertSObjects(new Order(RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID,
                Load__c = load.Id, Status = 'Ready To Load'), 5);

        for (Order order : orders) {
            order.Status = 'Pending Delivery';
        }

        Test.startTest();
        update orders;
        Test.stopTest();

        Load__c loadUpdated = [SELECT Id, CreateRoute__c FROM Load__c WHERE Id = :load.Id LIMIT 1][0];

        Assert.areEqual(true, loadUpdated.CreateRoute__c);
    }

    @IsTest
    private static void testPopulateLoadWhenAllLInkedOrdersShareStatus_NotAllChanged() {
        // prepare orders and assign them to load
        Load__c load = (Load__c) TdfSObjectFactory.insertSObject(new Load__c());
        List<Order> orders = (List<Order>) TdfSObjectFactory.insertSObjects(new Order(RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID,
                Load__c = load.Id, Status = 'Ready To Load'), 5);

        for (Integer i = 0; i < 1; i++) {
            orders[i].Status = 'Pending Delivery';
        }

        Test.startTest();
        update orders;
        Test.stopTest();

        Load__c loadUpdated = [SELECT Id, CreateRoute__c FROM Load__c WHERE Id = :load.Id LIMIT 1][0];

        Assert.areEqual(false, loadUpdated.CreateRoute__c);
    }
}

