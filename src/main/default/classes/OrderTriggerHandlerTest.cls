/**
 * Created by magdalena.stanciu on 14.09.2022.
 */

@IsTest
private with sharing class OrderTriggerHandlerTest {
    @IsTest
    private static void validateOrderCreationOrCompletion_ProspectAccountNewOrder() {
        // create attribute for New DP attribute flow automation
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Prospect', LastOrderDate__c = null)
        );

        // create order
        Test.startTest();
        try {
            TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id));
            Assert.isTrue(false, 'Expecting error to be thrown.');
        } catch (Exception ex) {
            String expectedErrorMessage = Label.OrderCreationActivationIsNotAllowedForCurrentAccountStatus;
            Assert.isTrue(ex.getMessage().contains(expectedErrorMessage), 'Expecting error to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void validateOrderCreationOrCompletion_ActiveProspectAccountNewTelesalesOrder() {
        // create attribute for New DP attribute flow automation
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Active Prospect', LastOrderDate__c = null)
        );

        // create order & check that validation is not fired
        Test.startTest();
        try {
            TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id));
            Assert.isTrue(true, 'Expecting error to don\'t be thrown.');
        } catch (Exception ex) {
            Assert.isTrue(false, 'Expecting error to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void validateOrderCreationOrCompletion_ActiveProspectAccountNewDraftFieldDirectOrder() {
        // create attribute for New DP attribute flow automation
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Active Prospect', LastOrderDate__c = null)
        );

        // create order & check that validation is not fired
        Test.startTest();
        try {
            TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID, AccountId = dpAccount.Id));
            Assert.isTrue(true, 'Expecting error to don\'t be thrown.');
        } catch (Exception ex) {
            Assert.isTrue(false, 'Expecting error to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void validateOrderCreationOrCompletion_DpAccountWithNotEnoughAvailableCredit() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id, UnitPrice = 100)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                LastOrderDate__c = null, aforza__Credit_Amount__c = 100, aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = dpAccount.Id, TeamMemberRole = 'TAM')
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_EDI_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id, IsApproved__c = false
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        // create invoice
        TdfSObjectFactory.insertSObject(
            new aforza__Invoice__c(
                aforza__Reference__c = '10', aforza__Account__c = dpAccount.Id, aforza__Order__c = newOrder.Id,
                aforza__Status__c = 'Outstanding', aforza__Amount_Due__c = 300
            )
        );

        Test.startTest();
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            Assert.isTrue(false, 'Expecting error to don\'t be thrown.');
        } catch (Exception e) {
            String expectedErrorMessage = Label.OrderActivationPreventedAccNotEnoughCredit;
            Assert.isTrue(e.getMessage().contains(expectedErrorMessage), 'Expecting error to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void validateOrderCreationOrCompletion_DpAccountOnHoldAndTelesales() {
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
                LastOrderDate__c = null, CreditStatus__c = 'On Hold', aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id, IsApproved__c = false, PreAuthCaptured__c = false
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        Test.startTest();
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            Assert.isTrue(false, 'Expecting error to don\'t be thrown.');
        } catch (Exception e) {
            String expectedErrorMessage = Label.OrderActivationPreventedDueToAccountOnHold;
            Assert.isTrue(e.getMessage().contains(expectedErrorMessage), 'Expecting error to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void validateOrderCreationOrCompletion_CustomerAccountWithNotEnoughAvailableCredit() {
        // create product & add it to standard PB
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id, UnitPrice = 100)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID, AccountStatus__c = 'Open',
                LastOrderDate__c = null, aforza__Credit_Amount__c = 100, aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = dpAccount.Id, TeamMemberRole = 'TAM')
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_EDI_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id, IsApproved__c = false
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        // create invoice
        TdfSObjectFactory.insertSObject(
            new aforza__Invoice__c(
                aforza__Reference__c = '10', aforza__Account__c = dpAccount.Id, aforza__Order__c = newOrder.Id,
                aforza__Status__c = 'Outstanding', aforza__Amount_Due__c = 300
            )
        );

        Test.startTest();
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            Assert.isTrue(false, 'Expecting error to don\'t be thrown.');
        } catch (Exception e) {
            String expectedErrorMessage = Label.OrderActivationPreventedAccNotEnoughCredit;
            Assert.isTrue(e.getMessage().contains(expectedErrorMessage), 'Expecting error to be thrown.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void validateOrderCreationOrCompletion_CustomerAccountOnHoldAndTelesales() {
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
                RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID, AccountStatus__c = 'Open',
                LastOrderDate__c = null, CreditStatus__c = 'On Hold', aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id,
                Status = 'Draft', Pricebook2Id = newPricebook.Id, IsApproved__c = false
            )
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
        );

        Test.startTest();
        try {
            newOrder.Status = 'Activated';
            update newOrder;
            Assert.isTrue(false, 'Expecting error to don\'t be thrown.');
        } catch (Exception e) {
            String expectedErrorMessage = Label.OrderActivationPreventedDueToAccountOnHold;
            Assert.isTrue(e.getMessage().contains(expectedErrorMessage), 'Expecting error to be thrown.');
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
        TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID, AccountId = dpAccount.Id));
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
            SELECT Id, AccountStatus__c, LastOrderDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        // check results
        Assert.areEqual('Traders', updatedDPAccount.AccountStatus__c, 'Expecting a different account status.');
        Assert.isNull(updatedDPAccount.LastOrderDate__c, 'Expecting a different last order date.');
    }

    @IsTest
    private static void testUpdateLastOrderDateAndStatusOnParentAccount_TradersAccountNewDraftFDOrderIsCompleted() {
        // create attribute for New DP attribute flow automation
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

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
            SELECT Id, AccountStatus__c, LastOrderDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        // check results
        Assert.areEqual('Traders', updatedDPAccount.AccountStatus__c, 'Expecting a different account status.');
        Assert.areEqual(newOrder.EffectiveDate, updatedDPAccount.LastOrderDate__c, 'Expecting a different last order date.');
    }

    @IsTest
    private static void testUpdateLastOrderDateAndStatusOnParentAccount_AtRiskAccountDraftTelesalesOrderIsCompleted() {
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
            SELECT Id, AccountStatus__c, LastOrderDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        // check results
        Assert.areEqual('Traders', updatedDPAccount.AccountStatus__c, 'Expecting a different account status.');
        Assert.areEqual(newOrder.EffectiveDate, updatedDPAccount.LastOrderDate__c, 'Expecting a different last order date.');
    }

    @IsTest
    private static void testCloneCompletedOrder() {
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
        Assert.areEqual(newOrder.Id, clonedOrder.aforza__Original_Order__c, 'Expected a different original order Id.');
        Assert.areEqual('Draft', clonedOrder.Status, 'Expected a different order status for the clone.');

        List<OrderItem> clonedOrderItems = [
            SELECT Id, OrderId, Product2Id
            FROM OrderItem
            WHERE OrderId = :clonedOrder.Id
        ];
        Assert.areEqual(1, clonedOrderItems.size(), 'Expected one order item for the cloned order');
    }

    @IsTest
    private static void testCloneCompletedOrder_NoCloneCreated() {
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
        Assert.areEqual(0, clonedOrder.size(), 'Expected no clone orders to be created');
    }

    @IsTest
    private static void testCreateInvoice_ValidOrderRecordType() {
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
            SELECT Id
            FROM aforza__Invoice_Line_Item__c
            WHERE aforza__Invoice__c IN :invoices
        ];

        Assert.areEqual(1, invoices.size(), 'Expected invoice to be created');
        Assert.areEqual(1, invoiceLineItems.size(), 'Expected invoice line items to be created');
    }

    @IsTest
    private static void testCreateInvoice_InvalidOrderRecordType() {
        // create attribute for New DP attribute flow automation
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

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

        Assert.areEqual(0, invoices.size(), 'Expected no invoice to be created');
        Assert.areEqual(0, invoiceLineItems.size(), 'Expected no invoice line items to be created');
    }

    @IsTest
    private static void testCreateInvoice_OrderWithPayment() {
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

        Assert.areEqual(1, invoices.size(), 'Expected invoice to be created');
        Assert.areEqual(1, invoiceLineItems.size(), 'Expected invoice line items to be created');

        // retrieve payment and validate result
        List<aforza__Payment_Transaction__c> transactions = [
            SELECT Id, aforza__Invoice__c
            FROM aforza__Payment_Transaction__c
            WHERE Id = :newPayment.Id
        ];
        Assert.areEqual(invoices[0].Id, transactions[0].aforza__Invoice__c, 'Expecting transaction to be linked to invoice');
    }

    @IsTest
    private static void testCreateInvoice_ExistingInvoice() {
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
            SELECT Id
            FROM aforza__Invoice__c
            WHERE aforza__Order__c = :newOrder.Id
        ];
        List<aforza__Invoice_Line_Item__c> invoiceLineItems = [
            SELECT Id
            FROM aforza__Invoice_Line_Item__c
            WHERE aforza__Invoice__c IN :invoices
        ];

        Assert.areEqual(1, invoices.size(), 'Expected existing invoice to be updated');
        Assert.areEqual(1, invoiceLineItems.size(), 'Expected invoice line items to be created');
    }

    @IsTest
    private static void testPopulateDefaultInventory() {
        aforza__Inventory__c inventory = new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID, Name = 'Wednesbury', InventoryCode__c = 'W');
        insert inventory;

        Test.startTest();
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, Depot__c = 'C'));
        Test.stopTest();

        Order order = [SELECT Id, Depot__c, aforza__Inventory__c FROM Order WHERE Id = :newOrder.Id];

        Assert.areEqual('C', order.Depot__c);
        Assert.areEqual(inventory.Id, order.aforza__Inventory__c);
    }

    @IsTest
    private static void testPopulateDefaultInventory_setToNull() {
        aforza__Inventory__c inventory = new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID, Name = 'Moston', InventoryCode__c = 'M');
        insert inventory;

        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, Depot__c = 'M'));

        Test.startTest();
        newOrder.Depot__c = null;
        update newOrder;
        Test.stopTest();

        Order order = [SELECT Id, Depot__c, aforza__Inventory__c FROM Order WHERE Id = :newOrder.Id];

        Assert.isNull(order.Depot__c);
        Assert.isNull(order.aforza__Inventory__c);
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

        Assert.isTrue(loadUpdated.CreateRoute__c);
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

        Assert.isFalse(loadUpdated.CreateRoute__c);
    }

    @IsTest
    private static void testRemoveOrdersFromLoad() {
        // prepare orders and assign them to load
        Load__c load = (Load__c) TdfSObjectFactory.insertSObject(new Load__c());
        Account acc1 = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        List<Order> orders = (List<Order>) TdfSObjectFactory.insertSObjects(new Order(AccountId = acc1.Id, RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID,
            Load__c = load.Id, Status = 'Ready To Load'), 5);

        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(AccountId = acc.Id, RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID,
            Load__c = load.Id, Status = 'Ready To Load'));
        orders.add(order);

        for (Integer i = 0; i < orders.size(); i++) {
            orders[i].Status = 'Pending Delivery';
        }

        update orders;

        // check that all data are created as expected
        Assert.areNotEqual(acc1.Id, acc.Id);
        List<aforza__Route_Location__c> routeLocations = [SELECT Id FROM aforza__Route_Location__c];
        Assert.areEqual(2, routeLocations.size());

        List<aforza__Visit__c> visits = [SELECT Id FROM aforza__Visit__c];
        Assert.areEqual(2, visits.size());

        List<Task> tasks = [SELECT Id FROM Task];
        Assert.areEqual(6, tasks.size());

        Test.startTest();
        orders[0].Status = 'Unplanned';
        orders[0].Replanned__c = true;
        orders[0].Load__c = null;
        orders[5].Status = 'Unplanned';
        orders[5].Replanned__c = true;
        orders[5].Load__c = null;
        update orders;
        Test.stopTest();

        List<aforza__Route_Location__c> routeLocationAcc1 = [SELECT Id FROM aforza__Route_Location__c WHERE aforza__Account__c = :acc1.Id];
        Assert.areEqual(1, routeLocationAcc1.size(), 'There should still be route location for this account.');

        List<aforza__Visit__c> visitAcc1 = [SELECT Id FROM aforza__Visit__c WHERE aforza__Account__c = :acc1.Id];
        Assert.areEqual(1, visitAcc1.size(), 'There should still be visit for this account.');

        List<Task> tasksAcc1 = [SELECT Id FROM Task WHERE aforza__Order__r.AccountId = :acc1.Id];
        Assert.areEqual(4, tasksAcc1.size(), 'There should be one less task, as one order was removed');

        List<aforza__Route__c> routeAcc = [SELECT Id FROM aforza__Route__c WHERE LoadId__c = :load.Id];
        Assert.areEqual(1, routeAcc.size(), 'There should be Route, as not all orders were removed');

        List<Load__c> loadAcc = [SELECT Id FROM Load__c WHERE Id = :load.Id];
        Assert.areEqual(1, loadAcc.size(), 'There should be load, as not all orders were removed');

        List<aforza__Route_Location__c> routeLocationAcc = [SELECT Id FROM aforza__Route_Location__c WHERE aforza__Account__c = :acc.Id];
        Assert.areEqual(0, routeLocationAcc.size(), 'There should not be any route location as order was removed.');

        List<aforza__Visit__c> visitAcc = [SELECT Id FROM aforza__Visit__c WHERE aforza__Account__c = :acc.Id];
        Assert.areEqual(0, visitAcc.size(), 'There should not be any visit as order was removed.');

        List<Task> tasksAcc = [SELECT Id FROM Task WHERE aforza__Order__r.AccountId = :acc.Id];
        Assert.areEqual(0, tasksAcc.size(), 'There should ot be any task left for this account, as order was removed');
    }

    @IsTest
    private static void testRemoveOrdersFromLoad_TwoOrdersRemoved() {
        // prepare orders and assign them to load
        Load__c load = (Load__c) TdfSObjectFactory.insertSObject(new Load__c());
        Account acc1 = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        List<Order> orders = (List<Order>) TdfSObjectFactory.insertSObjects(new Order(AccountId = acc1.Id, RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID,
            Load__c = load.Id, Status = 'Ready To Load'), 2);

        for (Integer i = 0; i < orders.size(); i++) {
            orders[i].Status = 'Pending Delivery';
        }

        update orders;

        // check that all data are created as expected
        List<aforza__Route_Location__c> routeLocations = [SELECT Id FROM aforza__Route_Location__c];
        Assert.areEqual(1, routeLocations.size());

        List<aforza__Visit__c> visits = [SELECT Id FROM aforza__Visit__c];
        Assert.areEqual(1, visits.size());

        List<Task> tasks = [SELECT Id FROM Task];
        Assert.areEqual(2, tasks.size());

        List<aforza__Route__c> route = [SELECT Id FROM aforza__Route__c WHERE LoadId__c = :load.Id];
        Assert.areEqual(1, route.size());

        Test.startTest();
        orders[0].Status = 'Unplanned';
        orders[0].Replanned__c = true;
        orders[0].Load__c = null;
        orders[1].Status = 'Unplanned';
        orders[1].Replanned__c = true;
        orders[1].Load__c = null;
        update orders;
        Test.stopTest();

        List<aforza__Route_Location__c> routeLocationAcc = [SELECT Id FROM aforza__Route_Location__c WHERE aforza__Account__c = :acc1.Id];
        Assert.areEqual(0, routeLocationAcc.size(), 'There should not be any route location as order was removed.');

        List<aforza__Visit__c> visitAcc = [SELECT Id FROM aforza__Visit__c WHERE aforza__Account__c = :acc1.Id];
        Assert.areEqual(0, visitAcc.size(), 'There should not be any visit as order was removed.');

        List<Task> tasksAcc = [SELECT Id FROM Task WHERE aforza__Order__r.AccountId = :acc1.Id];
        Assert.areEqual(0, tasksAcc.size(), 'There should ot be any task left for this account, as order was removed');

        List<aforza__Route__c> routeAcc = [SELECT Id FROM aforza__Route__c WHERE LoadId__c = :load.Id];
        Assert.areEqual(0, routeAcc.size(), 'There should not be Route anymore, as all orders were removed');

        List<Load__c> loadAcc = [SELECT Id FROM Load__c WHERE Id = :load.Id];
        Assert.areEqual(0, loadAcc.size(), 'There should not be load anymore, as all orders were removed');
    }
}