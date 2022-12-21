/**
 * Created by magdalena.stanciu on 23.11.2022.
 */

@IsTest
private with sharing class OrderItemTriggerHandlerTest {
    @IsTest
    private static void testCalculateVatOnOrderItemLevel_InsertOrderItemNullTaxPercent() {
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId, aforza__Tax_Percent__c = null)
        );

        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));

        Test.startTest();
        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id, OrderId = newOrder.Id, Quantity = 10, UnitPrice = 10, aforza__Tax__c = 1)
        );
        Test.stopTest();

        OrderItem insertedOrderItem = [
            SELECT Id, aforza__Tax__c
            FROM OrderItem
            WHERE Id = :newOrderItem.Id
        ];

        Assert.areEqual(0, insertedOrderItem.aforza__Tax__c);
    }

    @IsTest
    private static void testCalculateVatOnOrderItemLevel_InsertOrderNotNullTaxPercent() {
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));

        Test.startTest();
        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Quantity = 12, UnitPrice = 10.43, aforza__Tax__c = 12)
        );
        Test.stopTest();

        OrderItem insertedOrderItem = [
            SELECT Id, aforza__Tax__c, aforza__Tax_Percent__c
            FROM OrderItem
            WHERE Id = :newOrderItem.Id
        ];

        Decimal expectedVat = newOrderItem.Quantity * newOrderItem.UnitPrice * insertedOrderItem.aforza__Tax_Percent__c / 100;
        Decimal expectedVatRounded = expectedVat.setScale(2, RoundingMode.HALF_UP);
        Assert.areEqual(expectedVatRounded, insertedOrderItem.aforza__Tax__c);
    }

    @IsTest
    private static void testCalculateVatOnOrderItemLevel_UpdateOrderItemQuantity() {
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));
        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Quantity = 10, UnitPrice = 10.45, aforza__Tax__c = 23)
        );

        OrderItem insertedOrderItem = [
            SELECT Id, Quantity, UnitPrice, aforza__Tax_Percent__c, aforza__Tax__c
            FROM OrderItem
            WHERE Id = :newOrderItem.Id
        ];

        Decimal expectedVat = newOrderItem.Quantity * newOrderItem.UnitPrice * insertedOrderItem.aforza__Tax_Percent__c / 100;
        Decimal expectedVatRounded = expectedVat.setScale(2, RoundingMode.HALF_UP);
        Assert.areEqual(expectedVatRounded, insertedOrderItem.aforza__Tax__c);

        Test.startTest();
        insertedOrderItem.Quantity = 20;
        update insertedOrderItem;
        Test.stopTest();

        OrderItem updatedOrderItem = [
            SELECT Id, aforza__Tax__c
            FROM OrderItem
            WHERE Id = :insertedOrderItem.Id
        ];

        expectedVat = insertedOrderItem.Quantity * insertedOrderItem.UnitPrice * insertedOrderItem.aforza__Tax_Percent__c / 100;
        Assert.areEqual(expectedVat, updatedOrderItem.aforza__Tax__c);
    }

    @IsTest
    private static void testCalculateVatOnOrderItemLevel_UpdateOrderItemUnitPrice() {
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));
        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Quantity = 10, UnitPrice = 10.45, aforza__Tax__c = 9)
        );

        OrderItem insertedOrderItem = [
            SELECT Id, Quantity, UnitPrice, aforza__Tax_Percent__c, aforza__Tax__c
            FROM OrderItem
            WHERE Id = :newOrderItem.Id
        ];

        Decimal expectedVat = newOrderItem.Quantity * newOrderItem.UnitPrice * insertedOrderItem.aforza__Tax_Percent__c / 100;
        Decimal expectedVatRounded = expectedVat.setScale(2, RoundingMode.HALF_UP);
        Assert.areEqual(expectedVatRounded, insertedOrderItem.aforza__Tax__c);

        Test.startTest();
        insertedOrderItem.UnitPrice = 20;
        update insertedOrderItem;
        Test.stopTest();

        OrderItem updatedOrderItem = [
            SELECT Id, aforza__Tax__c
            FROM OrderItem
            WHERE Id = :insertedOrderItem.Id
        ];

        expectedVat = insertedOrderItem.Quantity * insertedOrderItem.UnitPrice * insertedOrderItem.aforza__Tax_Percent__c / 100;
        Assert.areEqual(expectedVat, updatedOrderItem.aforza__Tax__c);
    }

    @IsTest
    private static void testCalculateVatOnOrderItemLevel_InsertNonProductOrderItem() {
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));

        Test.startTest();
        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Quantity = 10, UnitPrice = 10, aforza__Tax__c = null, aforza__Type__c = 'Discount')
        );
        Test.stopTest();

        OrderItem insertedOrderItem = [
            SELECT Id, aforza__Tax__c
            FROM OrderItem
            WHERE Id = :newOrderItem.Id
        ];

        Assert.areEqual(null, insertedOrderItem.aforza__Tax__c);
    }

    @IsTest
    private static void testCalculateVatOnOrderLevel_InsertOrderItems() {
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));
        OrderItem newTaxOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, aforza__Type__c = 'Tax', Quantity = 1, UnitPrice = -1, aforza__Tax__c = 0)
        );

        Test.startTest();
        OrderItem newProductOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Quantity = 10, UnitPrice = 10, aforza__Tax__c = 1)
        );
        OrderItem newProductOrderItem2 = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Quantity = 10, UnitPrice = 10, aforza__Tax__c = 1)
        );
        Test.stopTest();

        Map<Id, OrderItem> insertedOrderItems = new Map<Id, OrderItem>([
            SELECT Id, UnitPrice, Quantity, aforza__Tax_Percent__c, aforza__Type__c, aforza__Tax__c
            FROM OrderItem
            WHERE OrderId = :newOrder.Id
        ]);

        Decimal expectedVat1 = insertedOrderItems.get(newProductOrderItem1.Id).Quantity * insertedOrderItems.get(newProductOrderItem1.Id).UnitPrice * insertedOrderItems.get(newProductOrderItem1.Id).aforza__Tax_Percent__c / 100;
        Decimal expectedVat2 = insertedOrderItems.get(newProductOrderItem2.Id).Quantity * insertedOrderItems.get(newProductOrderItem2.Id).UnitPrice * insertedOrderItems.get(newProductOrderItem2.Id).aforza__Tax_Percent__c / 100;
        Decimal totalVat = expectedVat1 + expectedVat2;
		
        Assert.areEqual(totalVat, insertedOrderItems.get(newTaxOrderItem.Id).UnitPrice);
    }

    @IsTest
    private static void testCalculateVatOnOrderLevel_UpdateOrderItems() {
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));
        OrderItem newTaxOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, aforza__Type__c = 'Tax', Quantity = 1, UnitPrice = 0)
        );
        OrderItem newProductOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Quantity = 10, UnitPrice = 10)
        );
        OrderItem newProductOrderItem2 = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Quantity = 10, UnitPrice = 10)
        );

        Map<Id, OrderItem> insertedOrderItems = new Map<Id, OrderItem>([
            SELECT Id, UnitPrice, Quantity, aforza__Tax_Percent__c, aforza__Type__c, aforza__Tax__c
            FROM OrderItem
            WHERE OrderId = :newOrder.Id
        ]);

        // check calculations before update
        Decimal expectedVat1 = insertedOrderItems.get(newProductOrderItem1.Id).Quantity * insertedOrderItems.get(newProductOrderItem1.Id).UnitPrice * insertedOrderItems.get(newProductOrderItem1.Id).aforza__Tax_Percent__c / 100;
        Decimal expectedVat2 = insertedOrderItems.get(newProductOrderItem2.Id).Quantity * insertedOrderItems.get(newProductOrderItem2.Id).UnitPrice * insertedOrderItems.get(newProductOrderItem2.Id).aforza__Tax_Percent__c / 100;
        Decimal totalVat = expectedVat1 + expectedVat2;

        Assert.areEqual(totalVat, insertedOrderItems.get(newTaxOrderItem.Id).UnitPrice);

        Test.startTest();
        newProductOrderItem1.Quantity = 10;
        newProductOrderItem2.UnitPrice = 20;
        update new List<OrderItem>{newProductOrderItem1, newProductOrderItem2};
        Test.stopTest();

        Map<Id, OrderItem> updatedOrderItems = new Map<Id, OrderItem>([
            SELECT Id, UnitPrice, Quantity, aforza__Tax_Percent__c, aforza__Type__c, aforza__Tax__c
            FROM OrderItem
            WHERE OrderId = :newOrder.Id
        ]);

        System.debug(updatedOrderItems.get(newProductOrderItem1.Id));
        System.debug(updatedOrderItems.get(newProductOrderItem2.Id));

        expectedVat1 = updatedOrderItems.get(newProductOrderItem1.Id).Quantity * updatedOrderItems.get(newProductOrderItem1.Id).UnitPrice * updatedOrderItems.get(newProductOrderItem1.Id).aforza__Tax_Percent__c / 100;
        expectedVat2 = updatedOrderItems.get(newProductOrderItem2.Id).Quantity * updatedOrderItems.get(newProductOrderItem2.Id).UnitPrice * updatedOrderItems.get(newProductOrderItem2.Id).aforza__Tax_Percent__c / 100;
        totalVat = expectedVat1 + expectedVat2;

        Assert.areEqual(totalVat, updatedOrderItems.get(newTaxOrderItem.Id).UnitPrice);
    }

    @IsTest
    private static void testCalculateVatOnOrderLevel_DeleteOrderItems() {
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));
        OrderItem newTaxOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, aforza__Type__c = 'Tax', Quantity = 1, UnitPrice = 0)
        );
        OrderItem newProductOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Quantity = 10, UnitPrice = 10, aforza__Tax__c = 0)
        );
        OrderItem newProductOrderItem2 = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Quantity = 10, UnitPrice = 10, aforza__Tax__c = 0)
        );

        Map<Id, OrderItem> insertedOrderItems = new Map<Id, OrderItem>([
            SELECT Id, UnitPrice, Quantity, aforza__Tax_Percent__c, aforza__Type__c, aforza__Tax__c
            FROM OrderItem
            WHERE OrderId = :newOrder.Id
        ]);

        // check calculations before update
        Decimal expectedVat1 = insertedOrderItems.get(newProductOrderItem1.Id).Quantity * insertedOrderItems.get(newProductOrderItem1.Id).UnitPrice * insertedOrderItems.get(newProductOrderItem1.Id).aforza__Tax_Percent__c / 100;
        Decimal expectedVat2 = insertedOrderItems.get(newProductOrderItem2.Id).Quantity * insertedOrderItems.get(newProductOrderItem2.Id).UnitPrice * insertedOrderItems.get(newProductOrderItem2.Id).aforza__Tax_Percent__c / 100;
        Decimal totalVat = expectedVat1 + expectedVat2;

        Assert.areEqual(totalVat, insertedOrderItems.get(newTaxOrderItem.Id).UnitPrice);

        Test.startTest();
        delete newProductOrderItem2;
        Test.stopTest();

        Map<Id, OrderItem> updatedOrderItems = new Map<Id, OrderItem>([
            SELECT Id, UnitPrice, Quantity, aforza__Tax_Percent__c, aforza__Type__c, aforza__Tax__c
            FROM OrderItem
            WHERE OrderId = :newOrder.Id
        ]);

        totalVat = updatedOrderItems.get(newProductOrderItem1.Id).Quantity * updatedOrderItems.get(newProductOrderItem1.Id).UnitPrice * updatedOrderItems.get(newProductOrderItem1.Id).aforza__Tax_Percent__c / 100;
        Assert.areEqual(totalVat, updatedOrderItems.get(newTaxOrderItem.Id).UnitPrice);
    }
    
    @IsTest
    private static void testCalculateVatOnOrderLevel_PreventCloneOrderVatCalculation(){
        
        Test.startTest();
		Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, Clone__c = true));
        OrderItem newTaxOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, aforza__Type__c = 'Tax', Quantity = 1, UnitPrice = 1, aforza__Tax__c = 0)
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Quantity = 10, UnitPrice = 10)
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Quantity = 10, UnitPrice = 10)
        );
        Test.stopTest();
                                                                 
		OrderItem orderItem = [SELECT Id, UnitPrice FROM OrderItem WHERE Id = :newTaxOrderItem.Id];
        
        Assert.areEqual(newTaxOrderItem.UnitPrice, orderItem.UnitPrice);
    }
    
    @IsTest
    private static void testCalculateVatOnOrderLevel_OriginalOrderVatCalculation(){
        
        Test.startTest();
		Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, Clone__c = false));
        OrderItem newTaxOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, aforza__Type__c = 'Tax', Quantity = 1, UnitPrice = 1, aforza__Tax__c = 0)
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Quantity = 10, UnitPrice = 10)
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Quantity = 10, UnitPrice = 10)
        );
        Test.stopTest();
                                                                 
		OrderItem orderItem = [SELECT Id, UnitPrice FROM OrderItem WHERE Id = :newTaxOrderItem.Id];
        
        Assert.areEqual(20, orderItem.UnitPrice);
        
    }
}