/**
 * Created by svatopluk.sejkora on 07.10.2022.
 */

@IsTest
private class LogisticUpdateScreenControllerTest {

    @IsTest
    private static void testFetchNeededPicklistValues() {
        Test.startTest();
        List<LogisticUpdateScreenController.PicklistDto> picklists = LogisticUpdateScreenController.fetchNeededPicklistValues('Order', new List<String>{'Status', 'Depot__c'});
        Test.stopTest();

        System.assert(!picklists.isEmpty(), 'There should be values in the returned list of picklists');
    }

    @IsTest
    private static void testUpdateOrderStatus() {
        String newStatus = 'Picking in Progress';
        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID));

        Test.startTest();
        LogisticUpdateScreenController.updateOrderStatus(new List<String>{order.Id}, newStatus);
        Test.stopTest();

        List<Order> updatedOrder = [ SELECT Id, Status FROM Order];

        System.assertEquals(1, updatedOrder.size());
        System.assertEquals(newStatus, updatedOrder[0].Status);
    }

    @IsTest
    private static void testUpdateOrderStatus_Cancelled() {
        String newStatus = 'Cancelled';
        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID));

        Test.startTest();
        LogisticUpdateScreenController.updateOrderStatus(new List<String>{order.Id}, newStatus);
        Test.stopTest();

        List<Order> updatedOrder = [ SELECT Id, Status, DeliveryFailed__c FROM Order];

        System.assertEquals(1, updatedOrder.size());
        System.assertEquals(newStatus, updatedOrder[0].Status);
        System.assertEquals(true, updatedOrder[0].DeliveryFailed__c);
    }

    @IsTest
    private static void testUpdateOrderStatus_Unplanned() {
        String newStatus = 'Unplanned';
        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID));

        Test.startTest();
        LogisticUpdateScreenController.updateOrderStatus(new List<String>{order.Id}, newStatus);
        Test.stopTest();

        List<Order> updatedOrder = [ SELECT Id, Status, Replanned__c FROM Order];

        System.assertEquals(1, updatedOrder.size());
        System.assertEquals(newStatus, updatedOrder[0].Status);
        System.assertEquals(true, updatedOrder[0].Replanned__c);
    }
}