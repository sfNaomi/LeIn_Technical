/**
 * Created by svatopluk.sejkora on 19.10.2022.
 */
@IsTest
private with sharing class LoadPlanningAssignmentControllerTest {

    @IsTest
    private static void testFetchVehicleLoadWeight() {
        Decimal loadWeight = 340;
        Vehicle__c vehicle = (Vehicle__c) TdfSObjectFactory.insertSObject(new Vehicle__c(LoadCapacityWeight__c = loadWeight));

        Test.startTest();
        Decimal loadWeightSelected = LoadPlanningAssignmentController.fetchVehicleLoadWeight(vehicle.Id);
        Test.stopTest();

        System.assertEquals(loadWeight, loadWeightSelected);
    }

    @IsTest
    private static void testFetchVehicleLoadWeight_NoVehicle() {
        String vehicleId = 'asd';

        Test.startTest();
        Decimal loadWeightSelected = LoadPlanningAssignmentController.fetchVehicleLoadWeight(vehicleId);
        Test.stopTest();

        System.assertEquals(0, loadWeightSelected);
    }

    @IsTest
    private static void testUpsertLoad() {
        Load__c load = new Load__c();

        Test.startTest();
        Load__c createdLoad = LoadPlanningAssignmentController.upsertLoad(load);
        Test.stopTest();

        System.assert(String.isNotEmpty(createdLoad.Name));
    }

    @IsTest
    private static void testUpsertLoad_Update() {
        Date loadDate = System.today();
        Load__c load = (Load__c) TdfSObjectFactory.insertSObject(new Load__c(DeliveryDate__c = loadDate));
        Date newLoadDate = loadDate.addDays(4);
        load.DeliveryDate__c = newLoadDate;

        Test.startTest();
        Load__c createdLoad = LoadPlanningAssignmentController.upsertLoad(load);
        Test.stopTest();

        System.assertEquals(newLoadDate, createdLoad.DeliveryDate__c);
    }

    @IsTest
    private static void testUpdateOrdersWithLoadIdAndNewStatus() {
        List<Order> orders = (List<Order>) TdfSObjectFactory.insertSObjects(new Order(RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID), 5);
        Load__c load = (Load__c) TdfSObjectFactory.insertSObject(new Load__c());
        String newStatus = 'Unplanned';
        List<String> orderIds = new List<String>();

        // get list of orderIds as strings
        for (Order order : orders) {
            orderIds.add(order.Id);
        }

        Test.startTest();
        LoadPlanningAssignmentController.updateOrdersWithLoadIdAndNewStatus(orderIds, newStatus, load.Id);
        Test.stopTest();

        for (Order order : [SELECT Id, Status, Load__c FROM Order]) {
            System.assertEquals(newStatus, order.Status);
            System.assertEquals(load.Id, order.Load__c);
        }
    }

    @IsTest
    private static void testProcessDeselectedOrders() {
        // prepare orders and assign them to load
        Load__c load = (Load__c) TdfSObjectFactory.insertSObject(new Load__c());
        List<Order> orders = (List<Order>) TdfSObjectFactory.insertSObjects(new Order(RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID,
                Load__c = load.Id, Status = 'Pending Delivery'), 5);

        // deselect first two orders
        Test.startTest();
        LoadPlanningAssignmentController.processDeselectedOrders(new List<Order>{
                orders[0], orders[1]
        });
        Test.stopTest();

        List<Order> deselectedOrders = [SELECT Id, Status, Load__c, Replanned__c FROM Order WHERE Id = :orders[0].Id OR Id = :orders[1].Id];

        System.assert(deselectedOrders.size() == 2);
        System.assertEquals(null, deselectedOrders[0].Load__c);
        System.assertEquals('Unplanned', deselectedOrders[0].Status);
        System.assertEquals(true, deselectedOrders[0].Replanned__c);
        System.assertEquals(null, deselectedOrders[1].Load__c);
        System.assertEquals('Unplanned', deselectedOrders[1].Status);
        System.assertEquals(true, deselectedOrders[1].Replanned__c);

        List<Order> notTouchedOrders = [SELECT Id, Status, Load__c FROM Order WHERE Id = :orders[2].Id OR Id = :orders[3].Id OR Id = :orders[4].Id];
        System.assert(notTouchedOrders.size() == 3);
        for (Order order : notTouchedOrders) {
            System.assert(String.isNotEmpty(order.Load__c));
            System.assert(order.Status == 'Pending Delivery');
        }
    }
}