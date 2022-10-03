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
}
