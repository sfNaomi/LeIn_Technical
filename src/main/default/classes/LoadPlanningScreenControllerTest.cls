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

    @IsTest
    private static void testFetchVehicle() {
        Profile platformUserProfile = [SELECT Id FROM Profile WHERE Name = 'AG Barr Platform User Driver'];
        UserRole role = [SELECT Id FROM UserRole WHERE DeveloperName = 'Driver'];
        User user = (User) TdfSObjectFactory.insertSObject(new User(ProfileId = platformUserProfile.Id, UserRoleId = role.Id));
        User adminUser = [SELECT Id FROM User WHERE Id =:System.UserInfo.getUserId()];
        User userWithName = [SELECT Id, Name FROM User WHERE Id = :user.Id];

        System.runAs(adminUser) {
            Vehicle__c vehicle = (Vehicle__c) TdfSObjectFactory.insertSObject(new Vehicle__c(Driver__c = user.Id));
            Test.startTest();
            Vehicle__c fetchedVehicle = LoadPlanningScreenController.fetchVehicle(userWithName.Name);
            Test.stopTest();

            Assert.isTrue(fetchedVehicle != null);
            Assert.areEqual(vehicle.Id, fetchedVehicle.Id);
            Assert.areEqual(vehicle.Driver__c, fetchedVehicle.Driver__c);
        }
    }

    @IsTest
    private static void testUpdateOrders() {
        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID));
        List<Object> orderData = new List<Object>{new Order(Id = order.Id, PalletSequence__c = 4)};

        Test.startTest();
        LoadPlanningScreenController.updateOrders(orderData);
        Test.stopTest();

        List<Order> updatedOrder = [SELECT Id, PalletSequence__c FROM Order];
        Assert.areEqual(1, updatedOrder.size(), 'There should be only one order');
        Assert.areEqual(4, updatedOrder[0].PalletSequence__c, 'Expecting Pallet Sequence of 4');
    }
}