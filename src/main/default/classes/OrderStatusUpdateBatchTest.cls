/**
 * Created by svatopluk.sejkora on 23.01.2023.
 */

@IsTest
private class OrderStatusUpdateBatchTest {
    @IsTest
    private static void testOrderStatusUpdateBatch() {
        TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, Status = 'Delivered'));

        Test.startTest();
        OrderStatusUpdateBatch ordersUpdateBatch = new OrderStatusUpdateBatch();
        Database.executeBatch(ordersUpdateBatch);
        Test.stopTest();

        List<Order> updatedOrder = [SELECT Id, Status FROM Order];

        Assert.isTrue(updatedOrder.size() == 1);
        Assert.areEqual('Receipted', updatedOrder[0].Status);
    }

    @IsTest
    private static void testOrderStatusUpdateBatch_someNotToUpdate() {
        TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, Status = 'Delivered'));
        TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_STRAIGHT_TO_JDE_ID, Status = 'Draft'));

        Test.startTest();
        OrderStatusUpdateBatch ordersUpdateBatch = new OrderStatusUpdateBatch();
        Database.executeBatch(ordersUpdateBatch);
        Test.stopTest();

        List<Order> updatedOrders = [SELECT Id, Status, RecordTypeId FROM Order];

        Assert.isTrue(updatedOrders.size() == 2);
        for (Order order : updatedOrders) {
            if (order.RecordTypeId == RecordTypes.ORDER_TELESALES_ID) {
                Assert.areEqual('Receipted', order.Status);
            } else {
                Assert.areEqual('Draft', order.Status);
            }
        }
    }

    @IsTest
    private static void testOrderStatusUpdateBatch_telesalesNoUpdate() {
        TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, Status = 'Draft'));

        Test.startTest();
        OrderStatusUpdateBatch ordersUpdateBatch = new OrderStatusUpdateBatch();
        Database.executeBatch(ordersUpdateBatch);
        Test.stopTest();

        List<Order> updatedOrder = [SELECT Id, Status FROM Order];

        Assert.isTrue(updatedOrder.size() == 1);
        Assert.areEqual('Draft', updatedOrder[0].Status);
    }

    @IsTest
    private static void testOrderStatusUpdateBatch_straightToJde() {
        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_STRAIGHT_TO_JDE_ID, Status = 'Draft'));
        TdfSObjectFactory.insertSObject(new OrderItem(OrderId = order.Id));
        order.Status = 'Activated';
        update order;

        Test.startTest();
        OrderStatusUpdateBatch ordersUpdateBatch = new OrderStatusUpdateBatch();
        Database.executeBatch(ordersUpdateBatch);
        Test.stopTest();

        List<Order> updatedOrder = [SELECT Id, Status FROM Order];

        Assert.isTrue(updatedOrder.size() == 1);
        Assert.areEqual('Receipted', updatedOrder[0].Status);
    }
}