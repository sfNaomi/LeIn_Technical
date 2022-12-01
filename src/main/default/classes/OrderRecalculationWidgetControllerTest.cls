/**
 * Created by magdalena.stanciu on 23.11.2022.
 */
@IsTest
private with sharing class OrderRecalculationWidgetControllerTest {
    @IsTest
    private static void testToPositiveAmount_NullInitialValue() {
        Decimal initialValue = null;

        Test.startTest();
        Decimal returnedValue = OrderRecalculationWidgetController.toPositiveAmount(initialValue);
        Test.stopTest();

        Assert.areEqual(null, returnedValue);
    }

    @IsTest
    private static void testToPositiveAmount_NegativeInitialValue() {
        Decimal initialValue = -1;

        Test.startTest();
        Decimal returnedValue = OrderRecalculationWidgetController.toPositiveAmount(initialValue);
        Test.stopTest();

        Assert.areEqual(1, returnedValue);
    }

    @IsTest
    private static void testToPositiveAmount_PositiveInitialValue() {
        Decimal initialValue = 1;

        Test.startTest();
        Decimal returnedValue = OrderRecalculationWidgetController.toPositiveAmount(initialValue);
        Test.stopTest();

        Assert.areEqual(1, returnedValue);
    }

    @IsTest
    private static void testToNegativeAmount_NullInitialValue() {
        Decimal initialValue = null;

        Test.startTest();
        Decimal returnedValue = OrderRecalculationWidgetController.toNegativeAmount(initialValue);
        Test.stopTest();

        Assert.areEqual(null, returnedValue);
    }

    @IsTest
    private static void testToNegativeAmount_NegativeInitialValue() {
        Decimal initialValue = -1;

        Test.startTest();
        Decimal returnedValue = OrderRecalculationWidgetController.toNegativeAmount(initialValue);
        Test.stopTest();

        Assert.areEqual(-1, returnedValue);
    }

    @IsTest
    private static void testToNegativeAmount_PositiveInitialValue() {
        Decimal initialValue = 1;

        Test.startTest();
        Decimal returnedValue = OrderRecalculationWidgetController.toNegativeAmount(initialValue);
        Test.stopTest();

        Assert.areEqual(-1, returnedValue);
    }

    @IsTest
    private static void testProductReturnRefund_PositiveProductTaxNegativeDiscountPromotion() {
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));
        OrderItem newProductOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, aforza__Type__c = 'Product', Quantity = 10, UnitPrice = 10, aforza__Tax__c = 1)
        );
        OrderItem newPromotionOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, aforza__Type__c = 'Promotion', Quantity = 1, UnitPrice = -10)
        );
        OrderItem newTaxOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, aforza__Type__c = 'Tax', Quantity = 1, UnitPrice = 1)
        );
        OrderItem newDiscountOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, aforza__Type__c = 'Discount', Quantity = 1, UnitPrice = -10)
        );

        Map<Id, OrderItem> insertedOrderItems = new Map<Id, OrderItem>([
            SELECT Id, UnitPrice, Quantity, aforza__Tax_Percent__c, aforza__Type__c, aforza__Tax__c
            FROM OrderItem
            WHERE OrderId = :newOrder.Id
        ]);

        Test.startTest();
        OrderRecalculationWidgetController.productReturnRefund(insertedOrderItems);
        Test.stopTest();

        Assert.isTrue(insertedOrderItems.get(newProductOrderItem.Id).aforza__Tax__c < 0);
        Assert.isTrue(insertedOrderItems.get(newProductOrderItem.Id).UnitPrice < 0);
        Assert.isTrue(insertedOrderItems.get(newTaxOrderItem.Id).aforza__Tax__c == null);
        Assert.isTrue(insertedOrderItems.get(newTaxOrderItem.Id).UnitPrice < 0);
        Assert.isTrue(insertedOrderItems.get(newPromotionOrderItem.Id).UnitPrice > 0);
        Assert.isTrue(insertedOrderItems.get(newPromotionOrderItem.Id).aforza__Tax__c == null);
        Assert.isTrue(insertedOrderItems.get(newDiscountOrderItem.Id).UnitPrice > 0);
        Assert.isTrue(insertedOrderItems.get(newDiscountOrderItem.Id).aforza__Tax__c == null);
    }

    @IsTest
    private static void testProductReturnRefund_NegativeProductTaxPositiveDiscountPromotion() {
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));
        OrderItem newProductOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, aforza__Type__c = 'Product', Quantity = 10, UnitPrice = -10, aforza__Tax__c = -1)
        );
        OrderItem newPromotionOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, aforza__Type__c = 'Promotion', Quantity = 1, UnitPrice = 10, aforza__Tax__c = 0)
        );
        OrderItem newTaxOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, aforza__Type__c = 'Tax', Quantity = 1, UnitPrice = -1, aforza__Tax__c = 0)
        );
        OrderItem newDiscountOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, aforza__Type__c = 'Discount', Quantity = 1, UnitPrice = 10, aforza__Tax__c = 0)
        );

        Map<Id, OrderItem> insertedOrderItems = new Map<Id, OrderItem>([
            SELECT Id, UnitPrice, Quantity, aforza__Tax_Percent__c, aforza__Type__c, aforza__Tax__c
            FROM OrderItem
            WHERE OrderId = :newOrder.Id
        ]);

        Test.startTest();
        OrderRecalculationWidgetController.productReturnRefund(insertedOrderItems);
        Test.stopTest();

        Assert.isTrue(insertedOrderItems.get(newProductOrderItem.Id).aforza__Tax__c < 0);
        Assert.isTrue(insertedOrderItems.get(newProductOrderItem.Id).UnitPrice < 0);
        Assert.isTrue(insertedOrderItems.get(newTaxOrderItem.Id).aforza__Tax__c == 0);
        Assert.isTrue(insertedOrderItems.get(newTaxOrderItem.Id).UnitPrice < 0);
        Assert.isTrue(insertedOrderItems.get(newPromotionOrderItem.Id).UnitPrice > 0);
        Assert.isTrue(insertedOrderItems.get(newPromotionOrderItem.Id).aforza__Tax__c == 0);
        Assert.isTrue(insertedOrderItems.get(newDiscountOrderItem.Id).UnitPrice > 0);
        Assert.isTrue(insertedOrderItems.get(newDiscountOrderItem.Id).aforza__Tax__c == 0);
    }

    @IsTest
    private static void testZeroOutAmountVat() {
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));
        OrderItem newProductOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Quantity = 10, UnitPrice = 10, aforza__Tax__c = 1)
        );

        Map<Id, OrderItem> insertedOrderItems = new Map<Id, OrderItem>([
            SELECT Id, UnitPrice, Quantity, aforza__Tax_Percent__c, aforza__Type__c
            FROM OrderItem
            WHERE OrderId = :newOrder.Id
        ]);

        Test.startTest();
        OrderRecalculationWidgetController.zeroOutAmountVat(insertedOrderItems);
        Test.stopTest();

        Assert.isTrue(insertedOrderItems.get(newProductOrderItem.Id).aforza__Tax__c == 0);
        Assert.isTrue(insertedOrderItems.get(newProductOrderItem.Id).UnitPrice == 0);
    }

    @IsTest
    private static void testGetOrderLineItemsToUpdate() {
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Quantity = 10, UnitPrice = 10, aforza__Tax__c = 1)
        );
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Quantity = 10, UnitPrice = 10, aforza__Tax__c = 1)
        );

        Test.startTest();
        Map<Id, OrderItem> orderItems = OrderRecalculationWidgetController.getOrderLineItemsToUpdate(newOrder.Id);
        Test.stopTest();

        Assert.areEqual(2, orderItems.size());
    }

    @IsTest
    private static void testPerformRecalculation_InvalidOption() {
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Quantity = 10, UnitPrice = 10, aforza__Tax__c = 1)
        );

        try {
            OrderRecalculationWidgetController.performRecalculation(newOrder.Id, 'TEST');
            Assert.isTrue(false, 'Expecting exception to be thrown');
        } catch (Exception e) {
            Assert.isTrue(true, 'Expecting exception to be thrown');
        }
    }

    @IsTest
    private static void testPerformRecalculation_ZeroOutAmountVat() {
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Quantity = 10, UnitPrice = 10, aforza__Tax__c = 1)
        );

        try {
            OrderRecalculationWidgetController.performRecalculation(newOrder.Id, 'ZERO_OUT_AMOUNT_VAT');
            Assert.isTrue(true, 'Expecting no exception to be thrown');
        } catch (Exception e) {
            Assert.isTrue(false, 'Expecting no exception to be thrown');
        }
    }

    @IsTest
    private static void testPerformRecalculation_ProductReturnRefund() {
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));
        TdfSObjectFactory.insertSObject(
            new OrderItem(OrderId = newOrder.Id, Quantity = 10, UnitPrice = 10, aforza__Tax__c = 1)
        );

        try {
            OrderRecalculationWidgetController.performRecalculation(newOrder.Id, 'PRODUCT_RETURN_REFUND');
            Assert.isTrue(true, 'Expecting no exception to be thrown');
        } catch (Exception e) {
            Assert.isTrue(false, 'Expecting no exception to be thrown');
        }
    }
}