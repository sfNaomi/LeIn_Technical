/**
 * Created by svatopluk.sejkora on 20.10.2022.
 */

@IsTest
private class LoadTriggerHandlerTest {

    @IsTest
    private static void testGetNeededDepotCodesAndLabels() {
        Test.startTest();
        Map<String, String> labelsWithCode = LoadTriggerHandler.getNeededDepotCodesAndLabels();
        Test.stopTest();

        Assert.isTrue(labelsWithCode.size() > 0);
    }

    @IsTest
    private static void testCheckIfTerritoryExistsCreateNewIfNot() {
        Test.startTest();
        Map<String, Id> territories = LoadTriggerHandler.checkIfTerritoryExistsCreateNewIfNot();
        Test.stopTest();

        Map<String, String> labelsWithCode = LoadTriggerHandler.getNeededDepotCodesAndLabels();

        Assert.areEqual(labelsWithCode.size(), territories.size());
    }

    @IsTest
    private static void testPrepareLoadToOrdersMap() {
        // prepare orders and assign them to load
        Load__c load = (Load__c) TdfSObjectFactory.insertSObject(new Load__c());
        TdfSObjectFactory.insertSObjects(new Order(RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID,
                Load__c = load.Id, Status = 'Pending Delivery'), 5);

        Test.startTest();
        Map<Id, List<Order>> loadToOrders = LoadTriggerHandler.prepareLoadToOrdersMap(new Set<Id>{
                load.Id
        });
        Test.stopTest();

        Assert.areEqual(1, loadToOrders.size());
        Assert.areEqual(5, loadToOrders.get(load.Id).size());
    }

    @IsTest
    private static void testMapDataToLoad() {
        Load__c load = (Load__c) TdfSObjectFactory.insertSObject(new Load__c());
        Test.startTest();
        Load__c loadMemory = LoadTriggerHandler.mapDataToLoad(load.Id);
        Test.stopTest();

        Assert.areEqual(load.Id, loadMemory.Id);
        Assert.areEqual(load.Id, loadMemory.Route__r.LoadId__c);
    }

    @IsTest
    private static void testMapDataToTask() {
        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID));

        Test.startTest();
        Task task = LoadTriggerHandler.mapDataToTask(order);
        Test.stopTest();

        Assert.areEqual(order.Id, task.aforza__Order__c);
        Assert.areEqual('Deliver Order', task.Subject);
        Assert.areEqual('Not Started', task.Status);
        Assert.areEqual('Order', task.aforza__Type__c);
        Assert.areEqual('High', task.Priority);
        Assert.areEqual(1, task.aforza__Sequence__c);
        Assert.areEqual(order.Id, task.WhatId);
    }

    @IsTest
    private static void testMapDataToVisit() {
        Load__c load = (Load__c) TdfSObjectFactory.insertSObject(new Load__c(DeliveryDate__c = System.today()));
        TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID, Load__c = load.Id));

        Order orderWithNeededData = [
                SELECT Id, Load__c, AccountId, Load__r.Driver__c, Load__r.DeliveryDate__c,
                        Load__r.Depot__c, Load__r.Name, Load__r.DriverFullName__c, AccountName__c
                FROM Order
        ][0];

        Test.startTest();
        aforza__Visit__c visit = LoadTriggerHandler.mapDataToVisit(orderWithNeededData);
        Test.stopTest();

        Assert.areEqual(RecordTypes.VISIT_DIRECT_VISIT_ID, visit.RecordTypeId);
        Assert.areEqual('Outlet Visit', visit.aforza__Type__c);
        Assert.areEqual(orderWithNeededData.AccountId, visit.aforza__Account__c);
        Assert.areEqual(orderWithNeededData.Load__r.Driver__c, visit.aforza__Owner__c);
        Assert.areEqual('Not Started', visit.aforza__Status__c);
        Assert.areEqual(System.today(), visit.aforza__Planned_Time__c.date());
        Assert.areEqual(System.today(), visit.aforza__Planned_End_Time__c.date());
    }

    @IsTest
    private static void testMapDataToRouteLocation() {
        Integer count = 1;
        Load__c load = (Load__c) TdfSObjectFactory.insertSObject(new Load__c());
        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID, Load__c = load.Id));

        Test.startTest();
        aforza__Route_Location__c location = LoadTriggerHandler.mapDataToRouteLocation(order, load.Id, count);
        Test.stopTest();

        Assert.areEqual(order.AccountId, location.aforza__Account__c);
        Assert.areEqual(1, location.aforza__Distance_From_Last_Location__c);
        Assert.areEqual(900, location.aforza__Duration_From_Last_Location__c);
        Assert.areEqual(count, location.aforza__Sequence__c);
    }

    @IsTest
    private static void testMapDataToRoute() {
        Load__c load = (Load__c) TdfSObjectFactory.insertSObject(new Load__c());
        TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID, Load__c = load.Id));
        Map<String, Id> territories = LoadTriggerHandler.checkIfTerritoryExistsCreateNewIfNot();
        Order orderWithNeededData = [
                SELECT Id, Load__c, AccountId, Load__r.Driver__c, Load__r.DeliveryDate__c,
                        Load__r.Depot__c, Load__r.Name, Load__r.DriverFullName__c, AccountName__c
                FROM Order
        ][0];

        Test.startTest();
        aforza__Route__c route = LoadTriggerHandler.mapDataToRoute(orderWithNeededData, territories, load.Id);
        Test.stopTest();

        Assert.areEqual(orderWithNeededData.Load__r.Name + ' - ' + orderWithNeededData.Load__r.DriverFullName__c, route.Name);
        Assert.areEqual('Active', route.aforza__Status__c);
        Assert.areEqual(territories.get('M'), route.aforza__Route_Territory__c);
        Assert.areEqual(load.Id, route.LoadId__c);
    }

    @IsTest
    private static void testUpdateDriver() {
        User newDriver = (User) TdfSObjectFactory.insertSObject(new User());

        Test.startTest();
        Load__c load = (Load__c) TdfSObjectFactory.insertSObject(new Load__c(CreateRoute__c = false));
        TdfSObjectFactory.insertSObjects(new Order(RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID,
                Load__c = load.Id, Status = 'Pending Delivery'), 5);

        load.CreateRoute__c = true;
        update load;
        // update values
        load.Driver__c = newDriver.Id;
        update load;
        Test.stopTest();

        aforza__Route__c updatedRoute = [SELECT Id, Name FROM aforza__Route__c][0];

        Assert.isTrue(updatedRoute.Name.contains(newDriver.LastName));
        Assert.isTrue(updatedRoute.Name.contains(newDriver.FirstName));
    }

    @IsTest
    private static void testCreateRouteAndVisitsAndTasks() {
        Load__c load = (Load__c) TdfSObjectFactory.insertSObject(new Load__c(CreateRoute__c = false));
        TdfSObjectFactory.insertSObjects(new Order(RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID,
                Load__c = load.Id, Status = 'Pending Delivery'), 5);

        Test.startTest();
        load.CreateRoute__c = true;
        update load;
        Test.stopTest();

        // check for route
        List<aforza__Route__c> routes = [SELECT Id FROM aforza__Route__c];
        Assert.isTrue(routes.size() == 1, 'There should be 1 route created');

        // check for location
        List<aforza__Route_Location__c> locations = [SELECT Id FROM aforza__Route_Location__c];
        System.debug('locations: ' + locations.size());
        Assert.isTrue(locations.size() == 1, 'There should be 1 location created');

        // check for visits
        List<aforza__Visit__c> visits = [SELECT Id FROM aforza__Visit__c];
        System.debug('visits: ' + visits.size());
        Assert.isTrue(visits.size() == 1, 'There should be 1 visit created');

        // check for tasks
        List<Task> tasks = [SELECT Id FROM Task];
        System.debug('tasks: ' + visits.size());
        Assert.isTrue(tasks.size() == 5, 'There should be 5 tasks created');

    }

    @IsTest
    private static void testPopulateDefaultInventory() {
		aforza__Inventory__c inventory = new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID, Name='Wednesbury', InventoryCode__c = 'W');
        insert inventory;
        
        Test.startTest();
        Load__c newLoad = (Load__c) TdfSObjectFactory.insertSObject(
                new Load__c(Depot__c = 'C')
        );
        Test.stopTest();

        Load__c load = [SELECT Id, Depot__c, SiteNo__c FROM Load__c WHERE Id =:newLoad.Id];
     
        System.assertEquals('C', load.Depot__c);
        System.assertEquals(inventory.Id, load.SiteNo__c);
    }

    @IsTest
    private static void testPopulateDefaultInventory_setToNull() {
		aforza__Inventory__c inventory = new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID, Name='Moston', InventoryCode__c = 'M');
        insert inventory;
        
        Load__c newLoad = (Load__c) TdfSObjectFactory.insertSObject(
                new Load__c(Depot__c = 'M')
        );
        
        Test.startTest();
        newLoad.Depot__c = null;
        update newLoad;
        Test.stopTest();

        Load__c load = [SELECT Id, Depot__c, SiteNo__c FROM Load__c WHERE Id =:newLoad.Id];
       
        System.assertEquals(null, load.Depot__c);
        System.assertEquals(null, load.SiteNo__c);
    }

    @IsTest
    private static void testUpdateDriverAndDeliveryDate() {
        User newDriver = (User) TdfSObjectFactory.insertSObject(new User());

        // having start here already to be able to insert user above.
        Test.startTest();
        Load__c load = (Load__c) TdfSObjectFactory.insertSObject(new Load__c(CreateRoute__c = false));
        TdfSObjectFactory.insertSObjects(new Order(RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID,
            Load__c = load.Id, Status = 'Pending Delivery'), 5);

        load.CreateRoute__c = true;
        update load;

        List<Task> tasks = [SELECT Id, aforza__Visit__r.aforza__Planned_Time__c, aforza__Visit__r.aforza__Planned_End_Time__c, aforza__Visit__r.aforza__Owner__c, OwnerId FROM Task];
        Assert.areEqual(5, tasks.size());
        Assert.areEqual(UserInfo.getUserId(), tasks[0].OwnerId);
        Assert.areEqual(UserInfo.getUserId(), tasks[0].aforza__Visit__r.aforza__Owner__c);


        // update values
        load.Driver__c = newDriver.Id;
        update load;
        Test.stopTest();

        aforza__Route__c updatedRoute = [SELECT Id, Name FROM aforza__Route__c][0];

        Assert.isTrue(updatedRoute.Name.contains(newDriver.LastName));
        Assert.isTrue(updatedRoute.Name.contains(newDriver.FirstName));

        List<Task> updatedTasks = [SELECT Id, aforza__Visit__r.aforza__Planned_Time__c, aforza__Visit__r.aforza__Planned_End_Time__c, aforza__Visit__r.aforza__Owner__c, OwnerId FROM Task];
        Assert.areEqual(5, tasks.size());
        Assert.areEqual(newDriver.Id, updatedTasks[0].OwnerId);
        Assert.areEqual(newDriver.Id, updatedTasks[1].OwnerId);
        Assert.areEqual(newDriver.Id, updatedTasks[2].OwnerId);
        Assert.areEqual(newDriver.Id, updatedTasks[3].OwnerId);
        Assert.areEqual(newDriver.Id, updatedTasks[4].OwnerId);
        Assert.areEqual(newDriver.Id, updatedTasks[0].aforza__Visit__r.aforza__Owner__c);

        List<aforza__Visit__c> visits = [SELECT Id FROM aforza__Visit__c];
        Assert.areEqual(1, visits.size());
    }

    @IsTest
    private static void testUpdateDriverAndDeliveryDate_DeliveryDate() {
        Date deliveryDate = System.today();
        Load__c load = (Load__c) TdfSObjectFactory.insertSObject(new Load__c(CreateRoute__c = false, DeliveryDate__c = deliveryDate));

        TdfSObjectFactory.insertSObjects(new Order(RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID,
            Load__c = load.Id, Status = 'Pending Delivery'), 5);

        load.CreateRoute__c = true;
        update load;

        List<Task> tasks = [SELECT Id, aforza__Visit__r.aforza__Planned_Time__c, aforza__Visit__r.aforza__Planned_End_Time__c, aforza__Visit__r.aforza__Owner__c, OwnerId FROM Task];
        Assert.areEqual(5, tasks.size());
        Assert.areEqual(deliveryDate, tasks[0].aforza__Visit__r.aforza__Planned_Time__c.date());
        Assert.areEqual(deliveryDate, tasks[0].aforza__Visit__r.aforza__Planned_End_Time__c.date());

        Test.startTest();
        // update values
        load.DeliveryDate__c = deliveryDate.addDays(5);
        update load;
        Test.stopTest();

        List<Task> updatedTasks = [SELECT Id, aforza__Visit__r.aforza__Planned_Time__c, aforza__Visit__r.aforza__Planned_End_Time__c, aforza__Visit__r.aforza__Owner__c, OwnerId FROM Task];
        Assert.areEqual(5, tasks.size());
        Assert.areEqual(deliveryDate.addDays(5), updatedTasks[0].aforza__Visit__r.aforza__Planned_Time__c.date());
        Assert.areEqual(deliveryDate.addDays(5), updatedTasks[0].aforza__Visit__r.aforza__Planned_End_Time__c.date());

        List<aforza__Visit__c> visits = [SELECT Id FROM aforza__Visit__c];
        Assert.areEqual(1, visits.size());
    }
    
    @IsTest
    private static void testSetCorrectLoadName_OnInsert() {
        Test.startTest();
        	Load__c newLoad = (Load__c) TdfSObjectFactory.insertSObject(
                    new Load__c(Name='test', 
                                Depot__c = 'M', 
                                DeliveryDate__c = Date.newInstance(2022, 11, 16), 
                                RouteIdentification__c = '10')
        	);
        Test.stopTest();

        Load__c load = [SELECT Id, Name FROM Load__c WHERE Id =:newLoad.Id];
       
        Assert.areEqual('M-10-16/11/22-01', load.Name);
    }
    
    @IsTest
    private static void testSetCorrectLoadName_OnUpdate() {
        Vehicle__c vehicle = (Vehicle__c) TdfSObjectFactory.insertSObject(
                    new Vehicle__c()
        );
        Load__c newLoad1 = (Load__c) TdfSObjectFactory.insertSObject(
                	new Load__c(Vehicle__c = vehicle.Id, 
                                Depot__c = 'M', 
                                DeliveryDate__c = Date.newInstance(2022, 11, 16), 
                                RouteIdentification__c = '10')
        );
        Load__c newLoad2 = (Load__c) TdfSObjectFactory.insertSObject(
            		new Load__c(Vehicle__c = vehicle.Id, 
                                Depot__c = 'S', 
                                DeliveryDate__c = Date.newInstance(2022, 11, 16), 
                                RouteIdentification__c = '10')
        );

        Test.startTest();
        	newLoad2.Depot__c = 'M';
        	update newLoad2;
        Test.stopTest();

        Load__c load = [SELECT Id, Name FROM Load__c WHERE Id =:newLoad2.Id];
       
        Assert.areEqual('M-10-16/11/22-02', load.Name);
    }
    
    @IsTest
    private static void testSetCorrectLoadName_OnInsertOfMultipleLoadsOfSameCharacteristics() {
        Vehicle__c vehicle = (Vehicle__c) TdfSObjectFactory.insertSObject(
                	new Vehicle__c()
        	);
        List<Load__c> loadList = new List<Load__c>();
        for (Integer i = 0; i < 20; i++){
            Load__c newLoad = new Load__c(Vehicle__c = vehicle.Id, 
                                            Depot__c = 'M', 
                                            DeliveryDate__c = Date.newInstance(2022, 11, 16), 
                                            RouteIdentification__c = '10');
            loadList.add(newLoad);
        }

        Test.startTest();
            insert loadList; 
        Test.stopTest();

		List<Load__c> newLoadList = [SELECT Id, Name, Vehicle__c FROM Load__c WHERE Vehicle__c =: vehicle.Id];

        Assert.areEqual('M-10-16/11/22-20', newLoadList[19].Name);
    }

	@IsTest
    private static void testSetCorrectLoadName_OnInsertOfMultipleLoadsOfDiffCharacteristicsWithExisting() {
        Vehicle__c vehicle = (Vehicle__c) TdfSObjectFactory.insertSObject(
                	new Vehicle__c()
        );
        Load__c newLoad1 = (Load__c) TdfSObjectFactory.insertSObject(
                	new Load__c(Vehicle__c = vehicle.Id, 
                                Depot__c = 'M', 
                                DeliveryDate__c = Date.newInstance(2022, 11, 16), 
                                RouteIdentification__c = '10')
        );
        Load__c newLoad2 = (Load__c) TdfSObjectFactory.insertSObject(
            		new Load__c(Vehicle__c = vehicle.Id, 
                                Depot__c = 'S', 
                                DeliveryDate__c = Date.newInstance(2022, 11, 16), 
                                RouteIdentification__c = '11')
        );
        Load__c newLoad3 = (Load__c) TdfSObjectFactory.insertSObject(
            		new Load__c(Vehicle__c = vehicle.Id, 
                                Depot__c = 'W', 
                                DeliveryDate__c = Date.newInstance(2022, 11, 17), 
                                RouteIdentification__c = '12')
        );
        List<Load__c> loadList = new List<Load__c>();
        for(Integer i = 0; i < 12; i++){
            Load__c newLoad = new Load__c(Vehicle__c = vehicle.Id, 
                                        Depot__c = 'D', 
                                        DeliveryDate__c = Date.newInstance(2022, 11, 16), 
                                        RouteIdentification__c = '15');
            loadList.add(newLoad);
        }
		
        Test.startTest();
        	insert loadList; 
        Test.stopTest();
		
        List<Load__c> newLoadListWithoutDagenham = [SELECT Id, Name, Vehicle__c, Depot__c FROM Load__c WHERE Vehicle__c =: vehicle.Id AND Depot__c != 'D'];
        List<Load__c> newLoadListWithDagenham = [SELECT Id, Name, Vehicle__c, Depot__c FROM Load__c WHERE Vehicle__c =: vehicle.Id AND Depot__c = 'D'];
        
        Assert.areEqual('M-10-16/11/22-01', newLoadListWithoutDagenham[0].Name);
        Assert.areEqual('S-11-16/11/22-01', newLoadListWithoutDagenham[1].Name);
        Assert.areEqual('W-12-17/11/22-01', newLoadListWithoutDagenham[2].Name);
        
        for (Integer i = 0; i < newLoadListWithDagenham.size(); i++){
            if (i < 9){
                Assert.areEqual('D-15-16/11/22-0' + String.valueOf(i+1), newLoadListWithDagenham[i].Name);
            } else {
                Assert.areEqual('D-15-16/11/22-' + String.valueOf(i+1), newLoadListWithDagenham[i].Name);
            }
        }
    }
    
    @IsTest
    private static void testSetCorrectLoadName_OnInsertOfMultipleLoadsOfSameCharacteristicsAsExisting() {
        Vehicle__c vehicle = (Vehicle__c) TdfSObjectFactory.insertSObject(
                	new Vehicle__c()
        );
        TdfSObjectFactory.insertSObject(
                	new Load__c(Vehicle__c = vehicle.Id, 
                                Depot__c = 'M', 
                                DeliveryDate__c = Date.newInstance(2022, 11, 16), 
                                RouteIdentification__c = '10')
        );
        List<Load__c> loadList = new List<Load__c>();
        for(Integer i = 0; i < 2; i++){
            Load__c newLoad = new Load__c(Vehicle__c = vehicle.Id, 
                                        Depot__c = 'M', 
                                        DeliveryDate__c = Date.newInstance(2022, 11, 16), 
                                        RouteIdentification__c = '10');
            loadList.add(newLoad);
        }
		
        Test.startTest();
        	insert loadList; 
        Test.stopTest();
		
        List<Load__c> newLoadList = [SELECT Id, Name, Vehicle__c FROM Load__c WHERE Vehicle__c =: vehicle.Id];
        
        Assert.areEqual('M-10-16/11/22-01', newLoadList[0].Name);
        Assert.areEqual('M-10-16/11/22-02', newLoadList[1].Name);
        Assert.areEqual('M-10-16/11/22-03', newLoadList[2].Name);
    }
}