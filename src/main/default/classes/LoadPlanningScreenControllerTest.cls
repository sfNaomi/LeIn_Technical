/**
 * Created by svatopluk.sejkora on 19.10.2022.
 */

@IsTest
private class LoadPlanningScreenControllerTest {
    @IsTest
    private static void testFetchOrdersForLoad() {
        // prepare orders and assign them to load
        Load__c load = (Load__c) TdfSObjectFactory.insertSObject(new Load__c());
        TdfSObjectFactory.insertSObjects(new Order(RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID,
                Load__c = load.Id, Status = 'Pending Delivery'), 5);

        String fieldsToGet = 'DeliveryDate__c,Load__r.Name';

        Test.startTest();
        List<Order> fetchedOrders = LoadPlanningScreenController.fetchOrdersForLoad(fieldsToGet, load.Id);
        Test.stopTest();

        System.assertEquals(5, fetchedOrders.size());
        for (Order order : fetchedOrders) {
            System.assert(order.DeliveryDate__c <> null);
            System.assert(String.isNotEmpty(order.Load__r.Name));
        }
    }

    @IsTest
    private static void testFetchLoadData() {
        Vehicle__c vehicle = (Vehicle__c) TdfSObjectFactory.insertSObject(new Vehicle__c());
        Load__c load = (Load__c) TdfSObjectFactory.insertSObject(new Load__c(Driver__c = UserInfo.getUserId(), Vehicle__c = vehicle.Id, DeliveryDate__c = System.today().addDays(2)));

        Test.startTest();
        Load__c fetchedLoad = LoadPlanningScreenController.fetchLoadData(load.Id);
        Test.stopTest();

        System.assertEquals(vehicle.Id, fetchedLoad.Vehicle__c);
        System.assertEquals(System.today().addDays(2), fetchedLoad.DeliveryDate__c);
        System.assertEquals(UserInfo.getUserId(), fetchedLoad.Driver__c);
    }
}