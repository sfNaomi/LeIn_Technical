/**
 * Created by magdalena.stanciu on 16.10.2022.
 */
@IsTest
public with sharing class PickSheetGenerationServiceTest {
    private static final String GRID1 = '3C7201MOW';
    private static final String GRID2 = '3C7201MOW';
    private static final String VEHICLE_REGISTRATION_NUMBER = 'AA11 AAA';
    private static final Date DELIVERY_DATE1 = Date.parse('12/10/2022');
    private static final Date DELIVERY_DATE2 = Date.parse('12/12/2022');
    private static final Integer PALLET_SEQUENCE1 = 1;
    private static final String PALLET_DESCRIPTION1 = 'Description 1';
    private static final Integer PALLET_SEQUENCE2 = 2;
    private static final String PALLET_DESCRIPTION2 = 'Description 2';
    private static final String PICK_LOCATION_PROD1 = 'A1';
    private static final String PICK_LOCATION_PROD2 = 'A2';

    @IsTest
    private static void testLoadPlanGeneration_SingleLoadSingleSequence() {
        // create products
        Product2 newProduct1 = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        Product2 newProduct2 = (Product2) TdfSObjectFactory.insertSObject(new Product2());

        // add new products to standard PB
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct1.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct2.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );
        
        // create custom pricebook and add products to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry product1PricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct1.Id, Pricebook2Id = newPricebook.Id)
        );
        PricebookEntry product2PricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct2.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
            aforza__Default_Price_Book__c = newPricebook.Id,
            RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
            PrimaryGridNumber__c = GRID1
        ));

        // create inventory and add products to inventory
        aforza__Inventory__c newInventory = (aforza__Inventory__c) TdfSObjectFactory.insertSObject(
            new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID)
        );
        aforza__Inventory_Product__c newInventoryProduct1 = (aforza__Inventory_Product__c) TdfSObjectFactory.insertSObject(
            new aforza__Inventory_Product__c(
                aforza__Inventory__c = newInventory.Id,
                aforza__Product__c = newProduct1.Id,
                PickingLocation__c = PICK_LOCATION_PROD1
            )
        );
        aforza__Inventory_Product__c newInventoryProduct2 = (aforza__Inventory_Product__c) TdfSObjectFactory.insertSObject(
            new aforza__Inventory_Product__c(
                aforza__Inventory__c = newInventory.Id,
                aforza__Product__c = newProduct2.Id,
                PickingLocation__c = PICK_LOCATION_PROD2
            )
        );

        // create orders and add products to it
        Order newOrder1 = (Order) TdfSObjectFactory.insertSObject(new Order(
            RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
            AccountId = dpAccount.Id,
            Grid__c = GRID1,
            Pricebook2Id = newPricebook.Id,
            aforza__Inventory__c = newInventory.Id
        ));
        OrderItem newOrderItem11 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(
            OrderId = newOrder1.Id,
            Product2Id = newProduct1.Id,
            Quantity = 10,
            PricebookEntryId = product1PricebookEntry.Id
        ));
        OrderItem newOrderItem12 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(
            OrderId = newOrder1.Id,
            Product2Id = newProduct2.Id,
            Quantity = 20,
            PricebookEntryId = product2PricebookEntry.Id
        ));

        Order newOrder2 = (Order) TdfSObjectFactory.insertSObject(new Order(
            RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
            AccountId = dpAccount.Id,
            Grid__c = GRID1,
            Pricebook2Id = newPricebook.Id,
            aforza__Inventory__c = newInventory.Id
        ));
        OrderItem newOrderItem21 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(
            OrderId = newOrder2.Id,
            Product2Id = newProduct1.Id,
            Quantity = 30,
            PricebookEntryId = product1PricebookEntry.Id
        ));
        OrderItem newOrderItem22 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(
            OrderId = newOrder2.Id,
            Product2Id = newProduct2.Id,
            Quantity = 40,
            PricebookEntryId = product2PricebookEntry.Id
        ));

        // create Vehicle
        Vehicle__c newVehicle = (Vehicle__c) TdfSObjectFactory.insertSObject(
            new Vehicle__c(VehicleRegistration__c = VEHICLE_REGISTRATION_NUMBER)
        );

        // create Load
        Load__c newLoad = (Load__c) TdfSObjectFactory.insertSObject(new Load__c(
            DeliveryDate__c = DELIVERY_DATE1, Vehicle__c = newVehicle.Id, Driver__c = UserInfo.getUserId()
        ));

        // add orders to the load
        List<Order> ordersToUpdate = new List<Order>();

        newOrder1.Load__c = newLoad.Id;
        newOrder1.PalletSequence__c = PALLET_SEQUENCE1;
        newOrder1.ShortDescription__c = PALLET_DESCRIPTION1;
        ordersToUpdate.add(newOrder1);

        newOrder2.Load__c = newLoad.Id;
        newOrder2.PalletSequence__c = PALLET_SEQUENCE1;
        newOrder2.ShortDescription__c = PALLET_DESCRIPTION1;
        ordersToUpdate.add(newOrder2);

        update ordersToUpdate;

        Test.startTest();
        PickSheetGenerationService service = new PickSheetGenerationService(new List<String>{newOrder1.Id, newOrder2.Id});
        List<PickSheetGenerationService.LoadPlan> loadPlans = service.getLoadPlans();
        Test.stopTest();

        // Query data to be verified
        Load__c insertedLoad = [
            SELECT Id, Name, Driver__r.Name, DeliveryDate__c, Vehicle__r.VehicleRegistration__c
            FROM Load__c
            WHERE Id = :newLoad.Id
            LIMIT 1
        ];

        // check load details
        Assert.areEqual(1, loadPlans.size());
        Assert.areEqual(insertedLoad.Name, loadPlans[0].load);
        Assert.areEqual(insertedLoad.Vehicle__r.VehicleRegistration__c, loadPlans[0].vehicle);
        Assert.areEqual(insertedLoad.Driver__r.Name, loadPlans[0].driver);
        Assert.areEqual(insertedLoad.DeliveryDate__c, loadPlans[0].deliveryDate);

        // check pallet sequence
        Assert.areEqual(1, loadPlans[0].palletSequences.size());
        Assert.areEqual(PALLET_SEQUENCE1, loadPlans[0].palletSequences[0].sequenceNumber);
        Assert.areEqual(PALLET_DESCRIPTION1, loadPlans[0].palletSequences[0].palletDescription);
        Assert.areEqual(GRID1, loadPlans[0].palletSequences[0].grid);
        Assert.areEqual(1, loadPlans[0].palletSequences[0].numberOfDps);

        Decimal totalCases = newOrderItem11.Quantity + newOrderItem12.Quantity + newOrderItem21.Quantity + newOrderItem22.Quantity;
        Assert.areEqual(totalCases, loadPlans[0].palletSequences[0].totalCases);

        // check pallet sequence items
        Assert.areEqual(2, loadPlans[0].palletSequences[0].palletSequenceItems.size());

        Assert.areEqual(newProduct1.ProductCode, loadPlans[0].palletSequences[0].palletSequenceItems[0].productCode);
        Assert.areEqual(newProduct1.Name, loadPlans[0].palletSequences[0].palletSequenceItems[0].productDescription);
        Assert.areEqual(PICK_LOCATION_PROD1, loadPlans[0].palletSequences[0].palletSequenceItems[0].pickLocation);

        Decimal prod1Quantity = newOrderItem11.Quantity + newOrderItem21.Quantity;
        Assert.areEqual(prod1Quantity, loadPlans[0].palletSequences[0].palletSequenceItems[0].quantity);

        Assert.areEqual(newProduct2.ProductCode, loadPlans[0].palletSequences[0].palletSequenceItems[1].productCode);
        Assert.areEqual(newProduct2.Name, loadPlans[0].palletSequences[0].palletSequenceItems[1].productDescription);
        Assert.areEqual(PICK_LOCATION_PROD2, loadPlans[0].palletSequences[0].palletSequenceItems[1].pickLocation);

        Decimal prod2Quantity = newOrderItem12.Quantity + newOrderItem22.Quantity;
        Assert.areEqual(prod2Quantity, loadPlans[0].palletSequences[0].palletSequenceItems[1].quantity);
    }

    @IsTest
    private static void testLoadPlanGeneration_SingleLoadMultipleSequences() {
        // create products
        Product2 newProduct1 = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        Product2 newProduct2 = (Product2) TdfSObjectFactory.insertSObject(new Product2());

        // add new products to standard PB
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct1.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct2.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );
        
        // create custom pricebook and add products to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry product1PricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct1.Id, Pricebook2Id = newPricebook.Id)
        );
        PricebookEntry product2PricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct2.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
            aforza__Default_Price_Book__c = newPricebook.Id,
            RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
            PrimaryGridNumber__c = GRID1
        ));

        // create inventory and add products to inventory
        aforza__Inventory__c newInventory = (aforza__Inventory__c) TdfSObjectFactory.insertSObject(
            new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID)
        );
        aforza__Inventory_Product__c newInventoryProduct1 = (aforza__Inventory_Product__c) TdfSObjectFactory.insertSObject(
            new aforza__Inventory_Product__c(
                aforza__Inventory__c = newInventory.Id,
                aforza__Product__c = newProduct1.Id,
                PickingLocation__c = PICK_LOCATION_PROD1
            )
        );
        aforza__Inventory_Product__c newInventoryProduct2 = (aforza__Inventory_Product__c) TdfSObjectFactory.insertSObject(
            new aforza__Inventory_Product__c(
                aforza__Inventory__c = newInventory.Id,
                aforza__Product__c = newProduct2.Id,
                PickingLocation__c = PICK_LOCATION_PROD2
            )
        );

        // create orders and add products to it
        Order newOrder1 = (Order) TdfSObjectFactory.insertSObject(new Order(
            RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
            AccountId = dpAccount.Id,
            Grid__c = GRID1,
            Pricebook2Id = newPricebook.Id,
            aforza__Inventory__c = newInventory.Id
        ));
        OrderItem newOrderItem11 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(
            OrderId = newOrder1.Id,
            Product2Id = newProduct1.Id,
            Quantity = 10,
            PricebookEntryId = product1PricebookEntry.Id
        ));
        OrderItem newOrderItem12 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(
            OrderId = newOrder1.Id,
            Product2Id = newProduct2.Id,
            Quantity = 20,
            PricebookEntryId = product2PricebookEntry.Id
        ));

        Order newOrder2 = (Order) TdfSObjectFactory.insertSObject(new Order(
            RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
            AccountId = dpAccount.Id,
            Grid__c = GRID1,
            Pricebook2Id = newPricebook.Id,
            aforza__Inventory__c = newInventory.Id
        ));
        OrderItem newOrderItem21 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(
            OrderId = newOrder2.Id,
            Product2Id = newProduct1.Id,
            Quantity = 30,
            PricebookEntryId = product1PricebookEntry.Id
        ));
        OrderItem newOrderItem22 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(
            OrderId = newOrder2.Id,
            Product2Id = newProduct2.Id,
            Quantity = 40,
            PricebookEntryId = product2PricebookEntry.Id
        ));

        // create Vehicle
        Vehicle__c newVehicle = (Vehicle__c) TdfSObjectFactory.insertSObject(
            new Vehicle__c(VehicleRegistration__c = VEHICLE_REGISTRATION_NUMBER)
        );

        // create Load
        Load__c newLoad = (Load__c) TdfSObjectFactory.insertSObject(
            new Load__c(DeliveryDate__c = DELIVERY_DATE1, Vehicle__c = newVehicle.Id, Driver__c = UserInfo.getUserId())
        );

        // add orders to the load
        List<Order> ordersToUpdate = new List<Order>();

        newOrder1.Load__c = newLoad.Id;
        newOrder1.PalletSequence__c = PALLET_SEQUENCE1;
        newOrder1.ShortDescription__c = PALLET_DESCRIPTION1;
        ordersToUpdate.add(newOrder1);

        newOrder2.Load__c = newLoad.Id;
        newOrder2.PalletSequence__c = PALLET_SEQUENCE2;
        newOrder2.ShortDescription__c = PALLET_DESCRIPTION2;
        ordersToUpdate.add(newOrder2);

        update ordersToUpdate;

        Test.startTest();
        PickSheetGenerationService service = new PickSheetGenerationService(new List<String>{newOrder1.Id, newOrder2.Id});
        List<PickSheetGenerationService.LoadPlan> loadPlans = service.getLoadPlans();
        Test.stopTest();

        // Query data to be verified
        Load__c insertedLoad = [
            SELECT Id, Name, Driver__r.Name, DeliveryDate__c, Vehicle__r.VehicleRegistration__c
            FROM Load__c
            WHERE Id = :newLoad.Id
            LIMIT 1
        ];

        // check load details
        Assert.areEqual(1, loadPlans.size());

        Assert.areEqual(insertedLoad.Name, loadPlans[0].load);
        Assert.areEqual(insertedLoad.Vehicle__r.VehicleRegistration__c, loadPlans[0].vehicle);
        Assert.areEqual(insertedLoad.Driver__r.Name, loadPlans[0].driver);
        Assert.areEqual(insertedLoad.DeliveryDate__c, loadPlans[0].deliveryDate);

        // check pallet sequence
        Assert.areEqual(2, loadPlans[0].palletSequences.size());

        // sequence 1
        Assert.areEqual(PALLET_SEQUENCE1, loadPlans[0].palletSequences[0].sequenceNumber);
        Assert.areEqual(PALLET_DESCRIPTION1, loadPlans[0].palletSequences[0].palletDescription);
        Assert.areEqual(GRID1, loadPlans[0].palletSequences[0].grid);
        Assert.areEqual(1, loadPlans[0].palletSequences[0].numberOfDps);

        Decimal totalCasesSequence1 = newOrderItem11.Quantity + newOrderItem12.Quantity;
        Assert.areEqual(totalCasesSequence1, loadPlans[0].palletSequences[0].totalCases);

        // sequence 2
        Assert.areEqual(PALLET_SEQUENCE2, loadPlans[0].palletSequences[1].sequenceNumber);
        Assert.areEqual(PALLET_DESCRIPTION2, loadPlans[0].palletSequences[1].palletDescription);
        Assert.areEqual(GRID2, loadPlans[0].palletSequences[0].grid);
        Assert.areEqual(1, loadPlans[0].palletSequences[1].numberOfDps);

        Decimal totalCasesSequence2 = newOrderItem21.Quantity + newOrderItem22.Quantity;
        Assert.areEqual(totalCasesSequence2, loadPlans[0].palletSequences[1].totalCases);

        // check pallet sequence items
        Assert.areEqual(2, loadPlans[0].palletSequences[0].palletSequenceItems.size());
        Assert.areEqual(2, loadPlans[0].palletSequences[1].palletSequenceItems.size());

        // sequence 1 - item 1
        Assert.areEqual(newProduct1.ProductCode, loadPlans[0].palletSequences[0].palletSequenceItems[0].productCode);
        Assert.areEqual(newProduct1.Name, loadPlans[0].palletSequences[0].palletSequenceItems[0].productDescription);
        Assert.areEqual(PICK_LOCATION_PROD1, loadPlans[0].palletSequences[0].palletSequenceItems[0].pickLocation);
        Assert.areEqual(newOrderItem11.Quantity, loadPlans[0].palletSequences[0].palletSequenceItems[0].quantity);

        // sequence 1 - item 2
        Assert.areEqual(newProduct2.ProductCode, loadPlans[0].palletSequences[0].palletSequenceItems[1].productCode);
        Assert.areEqual(newProduct2.Name, loadPlans[0].palletSequences[0].palletSequenceItems[1].productDescription);
        Assert.areEqual(PICK_LOCATION_PROD2, loadPlans[0].palletSequences[0].palletSequenceItems[1].pickLocation);
        Assert.areEqual(newOrderItem12.Quantity, loadPlans[0].palletSequences[0].palletSequenceItems[1].quantity);

        // sequence 2 - item 1
        Assert.areEqual(newProduct1.ProductCode, loadPlans[0].palletSequences[1].palletSequenceItems[0].productCode);
        Assert.areEqual(newProduct1.Name, loadPlans[0].palletSequences[1].palletSequenceItems[0].productDescription);
        Assert.areEqual(PICK_LOCATION_PROD1, loadPlans[0].palletSequences[1].palletSequenceItems[0].pickLocation);
        Assert.areEqual(newOrderItem21.Quantity, loadPlans[0].palletSequences[1].palletSequenceItems[0].quantity);

        // sequence 2 - item 2
        Assert.areEqual(newProduct2.ProductCode, loadPlans[0].palletSequences[1].palletSequenceItems[1].productCode);
        Assert.areEqual(newProduct2.Name, loadPlans[0].palletSequences[1].palletSequenceItems[1].productDescription);
        Assert.areEqual(PICK_LOCATION_PROD2, loadPlans[0].palletSequences[1].palletSequenceItems[1].pickLocation);
        Assert.areEqual(newOrderItem22.Quantity, loadPlans[0].palletSequences[1].palletSequenceItems[1].quantity);
    }

    @IsTest
    private static void testLoadPlanGeneration_MultipleLoadsSingleSequences() {
        // create products
        Product2 newProduct1 = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        Product2 newProduct2 = (Product2) TdfSObjectFactory.insertSObject(new Product2());

        // add new products to standard PB
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct1.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct2.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );
        
        // create custom pricebook and add products to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry product1PricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct1.Id, Pricebook2Id = newPricebook.Id)
        );
        PricebookEntry product2PricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct2.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        List<Account> accountsToInsert = new List<Account>();

        Account dpAccount1 = (Account) TdfSObjectFactory.createSObject(new Account(
            aforza__Default_Price_Book__c = newPricebook.Id,
            RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
            PrimaryGridNumber__c = GRID1
        ));
        accountsToInsert.add(dpAccount1);

        Account dpAccount2 = (Account) TdfSObjectFactory.createSObject(new Account(
            aforza__Default_Price_Book__c = newPricebook.Id,
            RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
            PrimaryGridNumber__c = GRID2
        ));
        accountsToInsert.add(dpAccount2);

        insert accountsToInsert;

        // create inventory and add products to inventory
        aforza__Inventory__c newInventory = (aforza__Inventory__c) TdfSObjectFactory.insertSObject(
            new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID)
        );
        TdfSObjectFactory.insertSObject(
            new aforza__Inventory_Product__c(aforza__Inventory__c = newInventory.Id, aforza__Product__c = newProduct1.Id, PickingLocation__c = PICK_LOCATION_PROD1)
        );
        TdfSObjectFactory.insertSObject(
            new aforza__Inventory_Product__c(aforza__Inventory__c = newInventory.Id, aforza__Product__c = newProduct2.Id, PickingLocation__c = PICK_LOCATION_PROD2)
        );

        // create orders and add products to it
        List<Order> ordersToInsert = new List<Order>();

        Order newOrder1 = (Order) TdfSObjectFactory.createSObject(new Order(
            RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
            AccountId = dpAccount1.Id,
            Grid__c = GRID1,
            Pricebook2Id = newPricebook.Id,
            aforza__Inventory__c = newInventory.Id
        ));
        ordersToInsert.add(newOrder1);

        Order newOrder2 = (Order) TdfSObjectFactory.createSObject(new Order(
            RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
            AccountId = dpAccount2.Id,
            Grid__c = GRID2,
            Pricebook2Id = newPricebook.Id,
            aforza__Inventory__c = newInventory.Id
        ));
        ordersToInsert.add(newOrder2);

        insert ordersToInsert;

        List<OrderItem> orderItemsToInsert = new List<OrderItem>();

        OrderItem newOrderItem11 = (OrderItem) TdfSObjectFactory.createSObject(new OrderItem(
            OrderId = newOrder1.Id,
            Product2Id = newProduct1.Id,
            Quantity = 10,
            PricebookEntryId = product1PricebookEntry.Id
        ));
        orderItemsToInsert.add(newOrderItem11);

        OrderItem newOrderItem12 = (OrderItem) TdfSObjectFactory.createSObject(new OrderItem(
            OrderId = newOrder1.Id,
            Product2Id = newProduct2.Id,
            Quantity = 20,
            PricebookEntryId = product2PricebookEntry.Id
        ));
        orderItemsToInsert.add(newOrderItem12);

        OrderItem newOrderItem21 = (OrderItem) TdfSObjectFactory.createSObject(new OrderItem(
            OrderId = newOrder2.Id,
            Product2Id = newProduct1.Id,
            Quantity = 30,
            PricebookEntryId = product1PricebookEntry.Id
        ));
        orderItemsToInsert.add(newOrderItem21);

        OrderItem newOrderItem22 = (OrderItem) TdfSObjectFactory.createSObject(new OrderItem(
            OrderId = newOrder2.Id,
            Product2Id = newProduct2.Id,
            Quantity = 40,
            PricebookEntryId = product2PricebookEntry.Id
        ));
        orderItemsToInsert.add(newOrderItem22);

        insert orderItemsToInsert;

        // create Vehicle
        Vehicle__c newVehicle = (Vehicle__c) TdfSObjectFactory.insertSObject(
            new Vehicle__c(VehicleRegistration__c = VEHICLE_REGISTRATION_NUMBER)
        );

        // create Load
        List<Load__c> loadsToInsert = new List<Load__c>();

        Load__c newLoad1 = (Load__c) TdfSObjectFactory.createSObject(new Load__c(
            DeliveryDate__c = DELIVERY_DATE1, Vehicle__c = newVehicle.Id, Driver__c = UserInfo.getUserId()
        ));
        loadsToInsert.add(newLoad1);

        Load__c newLoad2 = (Load__c) TdfSObjectFactory.createSObject(new Load__c(
            DeliveryDate__c = DELIVERY_DATE2, Vehicle__c = newVehicle.Id, Driver__c = UserInfo.getUserId()
        ));
        loadsToInsert.add(newLoad2);

        insert loadsToInsert;

        // add orders to the load
        List<Order> ordersToUpdate = new List<Order>();

        newOrder1.Load__c = newLoad1.Id;
        newOrder1.PalletSequence__c = PALLET_SEQUENCE1;
        newOrder1.ShortDescription__c = PALLET_DESCRIPTION1;
        ordersToUpdate.add(newOrder1);

        newOrder2.Load__c = newLoad2.Id;
        newOrder2.PalletSequence__c = PALLET_SEQUENCE1;
        newOrder2.ShortDescription__c = PALLET_DESCRIPTION1;
        ordersToUpdate.add(newOrder2);

        update ordersToUpdate;

        Test.startTest();
        PickSheetGenerationService service = new PickSheetGenerationService(new List<String>{newOrder1.Id, newOrder2.Id});
        List<PickSheetGenerationService.LoadPlan> loadPlans = service.getLoadPlans();
        Test.stopTest();

        // Query data to be verified
        Load__c insertedLoad1 = [
            SELECT Id, Name, Driver__r.Name, DeliveryDate__c, Vehicle__r.VehicleRegistration__c
            FROM Load__c
            WHERE Id = :newLoad1.Id
            LIMIT 1
        ];
        Load__c insertedLoad2 = [
            SELECT Id, Name, Driver__r.Name, DeliveryDate__c, Vehicle__r.VehicleRegistration__c
            FROM Load__c
            WHERE Id = :newLoad2.Id
            LIMIT 1
        ];

        // check load details
        Assert.areEqual(2, loadPlans.size());

        // load 1
        Assert.areEqual(insertedLoad1.Name, loadPlans[0].load);
        Assert.areEqual(insertedLoad1.Vehicle__r.VehicleRegistration__c, loadPlans[0].vehicle);
        Assert.areEqual(insertedLoad1.Driver__r.Name, loadPlans[0].driver);
        Assert.areEqual(insertedLoad1.DeliveryDate__c, loadPlans[0].deliveryDate);

        // load 2
        Assert.areEqual(insertedLoad2.Name, loadPlans[1].load);
        Assert.areEqual(insertedLoad2.Vehicle__r.VehicleRegistration__c, loadPlans[1].vehicle);
        Assert.areEqual(insertedLoad2.Driver__r.Name, loadPlans[1].driver);
        Assert.areEqual(insertedLoad2.DeliveryDate__c, loadPlans[1].deliveryDate);

        // check pallet sequence
        Assert.areEqual(1, loadPlans[0].palletSequences.size());
        Assert.areEqual(1, loadPlans[1].palletSequences.size());

        // load 1 - sequence 1
        Assert.areEqual(PALLET_SEQUENCE1, loadPlans[0].palletSequences[0].sequenceNumber);
        Assert.areEqual(PALLET_DESCRIPTION1, loadPlans[0].palletSequences[0].palletDescription);
        Assert.areEqual(GRID1, loadPlans[0].palletSequences[0].grid);
        Assert.areEqual(1, loadPlans[0].palletSequences[0].numberOfDps);

        Decimal totalCasesLoad1Sequence1 = newOrderItem11.Quantity + newOrderItem12.Quantity;
        Assert.areEqual(totalCasesLoad1Sequence1, loadPlans[0].palletSequences[0].totalCases);

        // load 2 - sequence 1
        Assert.areEqual(PALLET_SEQUENCE1, loadPlans[1].palletSequences[0].sequenceNumber);
        Assert.areEqual(PALLET_DESCRIPTION1, loadPlans[1].palletSequences[0].palletDescription);
        Assert.areEqual(GRID2, loadPlans[1].palletSequences[0].grid);
        Assert.areEqual(1, loadPlans[1].palletSequences[0].numberOfDps);

        Decimal totalCasesLoad2Sequence1 = newOrderItem21.Quantity + newOrderItem22.Quantity;
        Assert.areEqual(totalCasesLoad2Sequence1, loadPlans[1].palletSequences[0].totalCases);

        // check pallet sequence items
        Assert.areEqual(2, loadPlans[0].palletSequences[0].palletSequenceItems.size());
        Assert.areEqual(2, loadPlans[1].palletSequences[0].palletSequenceItems.size());

        // load 1 - sequence 1 - item 1
        Assert.areEqual(newProduct1.ProductCode, loadPlans[0].palletSequences[0].palletSequenceItems[0].productCode);
        Assert.areEqual(newProduct1.Name, loadPlans[0].palletSequences[0].palletSequenceItems[0].productDescription);
        Assert.areEqual(PICK_LOCATION_PROD1, loadPlans[0].palletSequences[0].palletSequenceItems[0].pickLocation);
        Assert.areEqual(newOrderItem11.Quantity, loadPlans[0].palletSequences[0].palletSequenceItems[0].quantity);

        // load 1 - sequence 1 - item 2
        Assert.areEqual(newProduct2.ProductCode, loadPlans[0].palletSequences[0].palletSequenceItems[1].productCode);
        Assert.areEqual(newProduct2.Name, loadPlans[0].palletSequences[0].palletSequenceItems[1].productDescription);
        Assert.areEqual(PICK_LOCATION_PROD2, loadPlans[0].palletSequences[0].palletSequenceItems[1].pickLocation);
        Assert.areEqual(newOrderItem12.Quantity, loadPlans[0].palletSequences[0].palletSequenceItems[1].quantity);

        // load 2 - sequence 1 - item 1
        Assert.areEqual(newProduct1.ProductCode, loadPlans[1].palletSequences[0].palletSequenceItems[0].productCode);
        Assert.areEqual(newProduct1.Name, loadPlans[1].palletSequences[0].palletSequenceItems[0].productDescription);
        Assert.areEqual(PICK_LOCATION_PROD1, loadPlans[1].palletSequences[0].palletSequenceItems[0].pickLocation);
        Assert.areEqual(newOrderItem21.Quantity, loadPlans[1].palletSequences[0].palletSequenceItems[0].quantity);

        // load 2 - sequence 1 - item 2
        Assert.areEqual(newProduct2.ProductCode, loadPlans[1].palletSequences[0].palletSequenceItems[1].productCode);
        Assert.areEqual(newProduct2.Name, loadPlans[1].palletSequences[0].palletSequenceItems[1].productDescription);
        Assert.areEqual(PICK_LOCATION_PROD2, loadPlans[1].palletSequences[0].palletSequenceItems[1].pickLocation);
        Assert.areEqual(newOrderItem22.Quantity, loadPlans[1].palletSequences[0].palletSequenceItems[1].quantity);
    }

    @IsTest
    private static void testLoadPlanGeneration_MultipleLoadsMultipleSequences() {
        // create products
        Product2 newProduct1 = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        Product2 newProduct2 = (Product2) TdfSObjectFactory.insertSObject(new Product2());

        // add new products to standard PB
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct1.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct2.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );
        
        // create custom pricebook and add products to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry product1PricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct1.Id, Pricebook2Id = newPricebook.Id)
        );
        PricebookEntry product2PricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct2.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        List<Account> accountsToInsert = new List<Account>();
        Account dpAccount1 = (Account) TdfSObjectFactory.createSObject(new Account(
            aforza__Default_Price_Book__c = newPricebook.Id,
            RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
            PrimaryGridNumber__c = GRID1
        ));
        accountsToInsert.add(dpAccount1);

        Account dpAccount2 = (Account) TdfSObjectFactory.createSObject(new Account(
            aforza__Default_Price_Book__c = newPricebook.Id,
            RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
            PrimaryGridNumber__c = GRID2
        ));
        accountsToInsert.add(dpAccount2);

        insert accountsToInsert;
        
        // create inventory and add products to inventory
        aforza__Inventory__c newInventory = (aforza__Inventory__c) TdfSObjectFactory.insertSObject(
            new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID)
        );
        TdfSObjectFactory.insertSObject(
            new aforza__Inventory_Product__c(aforza__Inventory__c = newInventory.Id, aforza__Product__c = newProduct1.Id, PickingLocation__c = PICK_LOCATION_PROD1)
        );
        TdfSObjectFactory.insertSObject(
            new aforza__Inventory_Product__c(aforza__Inventory__c = newInventory.Id, aforza__Product__c = newProduct2.Id, PickingLocation__c = PICK_LOCATION_PROD2)
        );

        // create orders and add products to it
        List<Order> ordersToInsert = new List<Order>();

        Order newOrder1 = (Order) TdfSObjectFactory.createSObject(new Order(
            RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
            AccountId = dpAccount1.Id,
            Grid__c = GRID1,
            Pricebook2Id = newPricebook.Id,
            aforza__Inventory__c = newInventory.Id
        ));
        ordersToInsert.add(newOrder1);

        Order newOrder2 = (Order) TdfSObjectFactory.createSObject(new Order(
            RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
            AccountId = dpAccount2.Id,
            Grid__c = GRID2,
            Pricebook2Id = newPricebook.Id,
            aforza__Inventory__c = newInventory.Id
        ));
        ordersToInsert.add(newOrder2);

        Order newOrder3 = (Order) TdfSObjectFactory.createSObject(new Order(
            RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
            AccountId = dpAccount1.Id,
            Grid__c = GRID1,
            Pricebook2Id = newPricebook.Id,
            aforza__Inventory__c = newInventory.Id
        ));
        ordersToInsert.add(newOrder3);

        Order newOrder4 = (Order) TdfSObjectFactory.createSObject(new Order(
            RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
            AccountId = dpAccount1.Id,
            Grid__c = GRID2,
            Pricebook2Id = newPricebook.Id,
            aforza__Inventory__c = newInventory.Id
        ));
        ordersToInsert.add(newOrder4);

        insert ordersToInsert;

        List<OrderItem> orderItemsToInsert = new List<OrderItem>();
        OrderItem newOrderItem1 = (OrderItem) TdfSObjectFactory.createSObject(new OrderItem(
                OrderId = newOrder1.Id,
                Product2Id = newProduct1.Id,
                Quantity = 10,
                PricebookEntryId = product1PricebookEntry.Id
        ));
        orderItemsToInsert.add(newOrderItem1);

        OrderItem newOrderItem2 = (OrderItem) TdfSObjectFactory.createSObject(new OrderItem(
                OrderId = newOrder2.Id,
                Product2Id = newProduct2.Id,
                Quantity = 20,
                PricebookEntryId = product2PricebookEntry.Id
        ));
        orderItemsToInsert.add(newOrderItem2);

        OrderItem newOrderItem3 = (OrderItem) TdfSObjectFactory.createSObject(new OrderItem(
                OrderId = newOrder3.Id,
                Product2Id = newProduct1.Id,
                Quantity = 30,
                PricebookEntryId = product1PricebookEntry.Id
        ));
        orderItemsToInsert.add(newOrderItem3);

        OrderItem newOrderItem4 = (OrderItem) TdfSObjectFactory.createSObject(new OrderItem(
            OrderId = newOrder4.Id,
            Product2Id = newProduct2.Id,
            Quantity = 40,
            PricebookEntryId = product2PricebookEntry.Id
        ));
        orderItemsToInsert.add(newOrderItem4);

        insert orderItemsToInsert;

        // create Vehicle
        Vehicle__c newVehicle = (Vehicle__c) TdfSObjectFactory.insertSObject(
            new Vehicle__c(VehicleRegistration__c = VEHICLE_REGISTRATION_NUMBER)
        );

        // create Load
        List<Load__c> loadsToInsert = new List<Load__c>();

        Load__c newLoad1 = (Load__c) TdfSObjectFactory.createSObject(
            new Load__c(DeliveryDate__c = DELIVERY_DATE1, Vehicle__c = newVehicle.Id, Driver__c = UserInfo.getUserId())
        );
        loadsToInsert.add(newLoad1);

        Load__c newLoad2 = (Load__c) TdfSObjectFactory.createSObject(
            new Load__c(DeliveryDate__c = DELIVERY_DATE2, Vehicle__c = newVehicle.Id, Driver__c = UserInfo.getUserId())
        );
        loadsToInsert.add(newLoad2);

        insert loadsToInsert;

        // add orders to the load
        List<Order> ordersToUpdate = new List<Order>();

        newOrder1.Load__c = newLoad1.Id;
        newOrder1.PalletSequence__c = PALLET_SEQUENCE1;
        newOrder1.ShortDescription__c = PALLET_DESCRIPTION1;
        ordersToUpdate.add(newOrder1);

        newOrder2.Load__c = newLoad1.Id;
        newOrder2.PalletSequence__c = PALLET_SEQUENCE2;
        newOrder2.ShortDescription__c = PALLET_DESCRIPTION2;
        ordersToUpdate.add(newOrder2);

        newOrder3.Load__c = newLoad2.Id;
        newOrder3.PalletSequence__c = PALLET_SEQUENCE1;
        newOrder3.ShortDescription__c = PALLET_DESCRIPTION1;
        ordersToUpdate.add(newOrder3);

        newOrder4.Load__c = newLoad2.Id;
        newOrder4.PalletSequence__c = PALLET_SEQUENCE2;
        newOrder4.ShortDescription__c = PALLET_DESCRIPTION2;
        ordersToUpdate.add(newOrder4);

        update ordersToUpdate;

        Test.startTest();
        PickSheetGenerationService service = new PickSheetGenerationService(
            new List<String>{newOrder1.Id, newOrder2.Id, newOrder3.Id, newOrder4.Id}
        );
        List<PickSheetGenerationService.LoadPlan> loadPlans = service.getLoadPlans();
        Test.stopTest();

        // check load details
        Assert.areEqual(2, loadPlans.size());

        // check pallet sequence
        Assert.areEqual(2, loadPlans[0].palletSequences.size());
        Assert.areEqual(2, loadPlans[1].palletSequences.size());

        // load 1 - sequence 1
        Assert.areEqual(PALLET_SEQUENCE1, loadPlans[0].palletSequences[0].sequenceNumber);
        Assert.areEqual(PALLET_DESCRIPTION1, loadPlans[0].palletSequences[0].palletDescription);
        Assert.areEqual(GRID1, loadPlans[0].palletSequences[0].grid);
        Assert.areEqual(1, loadPlans[0].palletSequences[0].numberOfDps);
        Assert.areEqual(newOrderItem1.Quantity, loadPlans[0].palletSequences[0].totalCases);

        // load 1 - sequence 2
        Assert.areEqual(PALLET_SEQUENCE2, loadPlans[0].palletSequences[1].sequenceNumber);
        Assert.areEqual(PALLET_DESCRIPTION2, loadPlans[0].palletSequences[1].palletDescription);
        Assert.areEqual(GRID2, loadPlans[0].palletSequences[1].grid);
        Assert.areEqual(1, loadPlans[0].palletSequences[1].numberOfDps);
        Assert.areEqual(newOrderItem2.Quantity, loadPlans[0].palletSequences[1].totalCases);

        // load 2 - sequence 1
        Assert.areEqual(PALLET_SEQUENCE1, loadPlans[1].palletSequences[0].sequenceNumber);
        Assert.areEqual(PALLET_DESCRIPTION1, loadPlans[1].palletSequences[0].palletDescription);
        Assert.areEqual(GRID1, loadPlans[1].palletSequences[0].grid);
        Assert.areEqual(1, loadPlans[1].palletSequences[0].numberOfDps);
        Assert.areEqual(newOrderItem3.Quantity, loadPlans[1].palletSequences[0].totalCases);

        // load 2 - sequence 2
        Assert.areEqual(PALLET_SEQUENCE2, loadPlans[1].palletSequences[1].sequenceNumber);
        Assert.areEqual(PALLET_DESCRIPTION2, loadPlans[1].palletSequences[1].palletDescription);
        Assert.areEqual(GRID2, loadPlans[1].palletSequences[1].grid);
        Assert.areEqual(1, loadPlans[1].palletSequences[1].numberOfDps);
        Assert.areEqual(newOrderItem4.Quantity, loadPlans[1].palletSequences[1].totalCases);

        // check pallet sequence items
        Assert.areEqual(1, loadPlans[0].palletSequences[0].palletSequenceItems.size());
        Assert.areEqual(1, loadPlans[0].palletSequences[1].palletSequenceItems.size());
        Assert.areEqual(1, loadPlans[1].palletSequences[0].palletSequenceItems.size());
        Assert.areEqual(1, loadPlans[1].palletSequences[1].palletSequenceItems.size());

        // load 1 - sequence 1 - item 1
        Assert.areEqual(newProduct1.ProductCode, loadPlans[0].palletSequences[0].palletSequenceItems[0].productCode);
        Assert.areEqual(newProduct1.Name, loadPlans[0].palletSequences[0].palletSequenceItems[0].productDescription);
        Assert.areEqual(PICK_LOCATION_PROD1, loadPlans[0].palletSequences[0].palletSequenceItems[0].pickLocation);
        Assert.areEqual(newOrderItem1.Quantity, loadPlans[0].palletSequences[0].palletSequenceItems[0].quantity);

        // load 1 - sequence 2 - item 1
        Assert.areEqual(newProduct2.ProductCode, loadPlans[0].palletSequences[1].palletSequenceItems[0].productCode);
        Assert.areEqual(newProduct2.Name, loadPlans[0].palletSequences[1].palletSequenceItems[0].productDescription);
        Assert.areEqual(PICK_LOCATION_PROD2, loadPlans[0].palletSequences[1].palletSequenceItems[0].pickLocation);
        Assert.areEqual(newOrderItem2.Quantity, loadPlans[0].palletSequences[1].palletSequenceItems[0].quantity);

        // load 2 - sequence 1 - item 1
        Assert.areEqual(newProduct1.ProductCode, loadPlans[1].palletSequences[0].palletSequenceItems[0].productCode);
        Assert.areEqual(newProduct1.Name, loadPlans[1].palletSequences[0].palletSequenceItems[0].productDescription);
        Assert.areEqual(PICK_LOCATION_PROD1, loadPlans[1].palletSequences[0].palletSequenceItems[0].pickLocation);
        Assert.areEqual(newOrderItem3.Quantity, loadPlans[1].palletSequences[0].palletSequenceItems[0].quantity);

        // load 2 - sequence 1 - item 2
        Assert.areEqual(newProduct2.ProductCode, loadPlans[1].palletSequences[1].palletSequenceItems[0].productCode);
        Assert.areEqual(newProduct2.Name, loadPlans[1].palletSequences[1].palletSequenceItems[0].productDescription);
        Assert.areEqual(PICK_LOCATION_PROD2, loadPlans[1].palletSequences[1].palletSequenceItems[0].pickLocation);
        Assert.areEqual(newOrderItem4.Quantity, loadPlans[1].palletSequences[1].palletSequenceItems[0].quantity);
    }
}