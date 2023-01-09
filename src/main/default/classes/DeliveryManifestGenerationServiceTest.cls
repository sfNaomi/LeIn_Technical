/**
 * Created by magdalena.stanciu on 16.10.2022.
 */
@IsTest
private with sharing class DeliveryManifestGenerationServiceTest {
    private static final String GRID1 = '3C7201MOW';
    private static final String GRID2 = '2C7601MOW';
    private static final String VEHICLE_REGISTRATION_NUMBER = 'AA11 AAA';
    private static final Date DELIVERY_DATE1 = Date.parse('12/10/2022');
    private static final Date DELIVERY_DATE2 = Date.parse('12/12/2022');
    private static final Integer PALLET_SEQUENCE1 = 1;
    private static final String PALLET_DESCRIPTION1 = 'Description 1';
    private static final Integer PALLET_SEQUENCE2 = 2;
    private static final String PALLET_DESCRIPTION2 = 'Description 2';
    private static final Decimal VEHICLE_CAPACITY_WEIGHT = 2000.00;
    private static final Integer VEHICLE_CAPACITY_CASES = 1000;
    private static final String FILE_CONTENT = 'File Content';

    @IsTest
    private static void testLoadGeneration_SingleLoadSingleSequence() {
        // create products
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(
            new Product2(Name = 'Test Product', aforza__Weight__c = 1.5)
        );

        // add new products to standard PB
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create custom pricebook and add products to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry product1PricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                aforza__Default_Price_Book__c = newPricebook.Id,
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = GRID1,
                FixedDeliveryInstructions__c = 'Fixed Delivery Instructions',
                PrimaryPaymentMethod__c = 'Cash',
                OpeningTime__c = Time.newInstance(9, 0, 0, 0)
            )
        );

        // create inventory and add products to inventory
        aforza__Inventory__c newInventory = (aforza__Inventory__c) TdfSObjectFactory.insertSObject(
            new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID)
        );

        // create orders and add products to it
        Order newOrder1 = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
                AccountId = dpAccount.Id,
                Grid__c = GRID1,
                Pricebook2Id = newPricebook.Id,
                aforza__Inventory__c = newInventory.Id,
                ShippingCity = 'Test City',
                ShippingStreet = 'Test Street',
                ShippingPostalCode = '054354',
                PaymentMethod__c = 'Cash'
            )
        );
        OrderItem newOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(
                OrderId = newOrder1.Id,
                Product2Id = newProduct.Id,
                Quantity = 10,
                PricebookEntryId = product1PricebookEntry.Id
            )
        );

        Order newOrder2 = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
                AccountId = dpAccount.Id,
                Grid__c = GRID1,
                Pricebook2Id = newPricebook.Id,
                aforza__Inventory__c = newInventory.Id,
                ShippingCity = 'Test City',
                ShippingStreet = 'Test Street',
                ShippingPostalCode = '054354',
                PaymentMethod__c = 'Cash'
            )
        );
        OrderItem newOrderItem2 = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(
                OrderId = newOrder2.Id,
                Product2Id = newProduct.Id,
                Quantity = 30,
                PricebookEntryId = product1PricebookEntry.Id
            )
        );

        // create Vehicle
        Vehicle__c newVehicle = (Vehicle__c) TdfSObjectFactory.insertSObject(
            new Vehicle__c(
                VehicleRegistration__c = VEHICLE_REGISTRATION_NUMBER,
                LoadCapacityWeight__c = VEHICLE_CAPACITY_WEIGHT,
                LoadLimitCases__c = VEHICLE_CAPACITY_CASES
            )
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
        newOrder2.PalletSequence__c = PALLET_SEQUENCE1;
        newOrder2.ShortDescription__c = PALLET_DESCRIPTION1;
        ordersToUpdate.add(newOrder2);

        update ordersToUpdate;

        // add notes to the orders
        ContentVersion note = (ContentVersion) TdfSObjectFactory.insertSObject(
            new ContentVersion(VersionData = Blob.valueOf(FILE_CONTENT), PathOnClient = 'Note.sNote')
        );

        ContentVersion insertedNote = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :note.Id];

        TdfSObjectFactory.insertSObject(
            new ContentDocumentLink(ContentDocumentId = insertedNote.ContentDocumentId, LinkedEntityId = newOrder1.Id)
        );
        TdfSObjectFactory.insertSObject(
            new ContentDocumentLink(ContentDocumentId = insertedNote.ContentDocumentId, LinkedEntityId = newOrder2.Id)
        );

        Test.startTest();
        DeliveryManifestGenerationService service = new DeliveryManifestGenerationService(
            new List<String>{newOrder1.Id, newOrder2.Id}
        );
        List<DeliveryManifestGenerationService.Load> loads = service.getLoads();
        Test.stopTest();

        // Query data to be verified
        Load__c insertedLoad = [
            SELECT Id, Name, Driver__r.Name, DeliveryDate__c, Vehicle__r.VehicleRegistration__c
            FROM Load__c
            WHERE Id = :newLoad.Id
            LIMIT 1
        ];

        // check load details
        Assert.areEqual(1, loads.size());
        Assert.areEqual(insertedLoad.Name, loads[0].loadID);
        Assert.areEqual(insertedLoad.Driver__r.Name, loads[0].driver);
        Assert.areEqual(insertedLoad.Vehicle__r.VehicleRegistration__c, loads[0].vehicle);
        Assert.areEqual(insertedLoad.DeliveryDate__c, loads[0].deliveryDate);

        String vehicleCapacity = VEHICLE_CAPACITY_WEIGHT + ' ' + System.Label.DeliveryManifestKG + ', ' +
            VEHICLE_CAPACITY_CASES + ' ' + System.Label.DeliveryManifestCS;
        Assert.areEqual(vehicleCapacity, loads[0].vehicleCapacity);

        Decimal totalQuantity = newOrderItem1.Quantity + newOrderItem2.Quantity;
        Assert.areEqual(totalQuantity, loads[0].totalQuantity);

        Decimal totalWeight = (newProduct.aforza__Weight__c * newOrderItem1.Quantity) +
                (newProduct.aforza__Weight__c * newOrderItem2.Quantity);
        Assert.areEqual(totalWeight, loads[0].totalWeight);

        Assert.areEqual(1, loads[0].numberOfDps);
        Assert.areEqual(1, loads[0].numberOfPallets);

        // check load items
        Assert.areEqual(2, loads[0].loadItems.size());

        Assert.areEqual(PALLET_SEQUENCE1, loads[0].loadItems[0].palletSequence);
        Assert.areEqual(PALLET_SEQUENCE1, loads[0].loadItems[1].palletSequence);

        Assert.areEqual(PALLET_DESCRIPTION1, loads[0].loadItems[0].palletDescription);
        Assert.areEqual(PALLET_DESCRIPTION1, loads[0].loadItems[1].palletDescription);

        Assert.areEqual(FILE_CONTENT, loads[0].loadItems[0].notes);
        Assert.areEqual(FILE_CONTENT, loads[0].loadItems[1].notes);

        Assert.areEqual(dpAccount.Name, loads[0].loadItems[0].accountName);
        Assert.areEqual(dpAccount.Name, loads[0].loadItems[1].accountName);

        Assert.areEqual(dpAccount.FixedDeliveryInstructions__c, loads[0].loadItems[0].deliveryInstructions);
        Assert.areEqual(dpAccount.FixedDeliveryInstructions__c, loads[0].loadItems[1].deliveryInstructions);

        Assert.areEqual(dpAccount.Phone, loads[0].loadItems[1].phone);
        Assert.areEqual(dpAccount.Phone, loads[0].loadItems[1].phone);

        Assert.areEqual(newOrder1.PaymentMethod__c, loads[0].loadItems[0].paymentMethod);
        Assert.areEqual(newOrder1.PaymentMethod__c, loads[0].loadItems[1].paymentMethod);

        String openingTime = dpAccount.OpeningTime__c.hour() + ':' + dpAccount.OpeningTime__c.minute();
        Assert.areEqual(openingTime, loads[0].loadItems[0].openingTime);
        Assert.areEqual(openingTime, loads[0].loadItems[1].openingTime);

        String address1 = newOrder1.ShippingStreet + ' ' + newOrder1.ShippingCity;
        String address2 = newOrder2.ShippingStreet + ' ' + newOrder2.ShippingCity;
        Assert.areEqual(address1, loads[0].loadItems[0].shippingAddress);
        Assert.areEqual(address2, loads[0].loadItems[1].shippingAddress);

        Assert.areEqual(newOrder1.ShippingPostalCode, loads[0].loadItems[0].shippingPostalCode);
        Assert.areEqual(newOrder2.ShippingPostalCode, loads[0].loadItems[1].shippingPostalCode);

        String tam = UserInfo.getName();
        Assert.areEqual(tam, loads[0].loadItems[0].tam);
        Assert.areEqual(tam, loads[0].loadItems[1].tam);

        Assert.areEqual(newOrderItem1.Quantity, loads[0].loadItems[0].quantity);
        Assert.areEqual(newOrderItem2.Quantity, loads[0].loadItems[1].quantity);

        Decimal orderWeight1 = newProduct.aforza__Weight__c * newOrderItem1.Quantity;
        Decimal orderWeight2 = newProduct.aforza__Weight__c * newOrderItem2.Quantity;
        Assert.areEqual(orderWeight1, loads[0].loadItems[0].weight);
        Assert.areEqual(orderWeight2, loads[0].loadItems[1].weight);
    }

    @IsTest
    private static void testLoadGeneration_MultipleLoadsMultipleSequences() {
        // create products
        Product2 newProduct1 = (Product2) TdfSObjectFactory.insertSObject(
            new Product2(Name = 'Test Product', aforza__Weight__c = 1.5)
        );
        Product2 newProduct2 = (Product2) TdfSObjectFactory.insertSObject(
            new Product2(Name = 'Test Product', aforza__Weight__c = 1)
        );

        // add new products to standard PB
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct1.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct2.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create custom pricebook and add products to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry productPricebookEntry1 = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct1.Id, Pricebook2Id = newPricebook.Id)
        );
        PricebookEntry productPricebookEntry2 = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct2.Id, Pricebook2Id = newPricebook.Id)
        );
        // create account
        Account dpAccount1 = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                aforza__Default_Price_Book__c = newPricebook.Id,
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = GRID1,
                FixedDeliveryInstructions__c = 'Fixed Delivery Instructions',
                PrimaryPaymentMethod__c = 'Cash',
                OpeningTime__c = Time.newInstance(9, 0, 0, 0)
            )
        );
        Account dpAccount2 = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                aforza__Default_Price_Book__c = newPricebook.Id,
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = GRID2,
                FixedDeliveryInstructions__c = 'Fixed Delivery Instructions',
                PrimaryPaymentMethod__c = 'Cash',
                OpeningTime__c = Time.newInstance(9, 0, 0, 0)
            )
        );

        // create inventory and add products to inventory
        aforza__Inventory__c newInventory = (aforza__Inventory__c) TdfSObjectFactory.insertSObject(
            new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID)
        );

        // create orders and add products to it
        List<Order> ordersToInsert = new List<Order>();
        Order newOrder1 = (Order) TdfSObjectFactory.createSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
                AccountId = dpAccount1.Id,
                Grid__c = GRID1,
                Pricebook2Id = newPricebook.Id,
                aforza__Inventory__c = newInventory.Id,
                ShippingCity = 'Test City',
                ShippingStreet = 'Test Street',
                ShippingPostalCode = '054354',
                PaymentMethod__c = 'Card Payment'
            )
        );

        ordersToInsert.add(newOrder1);

        Order newOrder2 = (Order) TdfSObjectFactory.createSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
                AccountId = dpAccount2.Id,
                Grid__c = GRID2,
                Pricebook2Id = newPricebook.Id,
                aforza__Inventory__c = newInventory.Id,
                ShippingCity = 'Test City',
                ShippingStreet = 'Test Street',
                ShippingPostalCode = '054354',
                PaymentMethod__c = 'Direct Debit'
            )
        );
        ordersToInsert.add(newOrder2);

        Order newOrder3 = (Order) TdfSObjectFactory.createSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
                AccountId = dpAccount1.Id,
                Grid__c = GRID1,
                Pricebook2Id = newPricebook.Id,
                aforza__Inventory__c = newInventory.Id,
                ShippingCity = 'Test City',
                ShippingStreet = 'Test Street',
                ShippingPostalCode = '054354',
                PaymentMethod__c = 'Cash'
            )
        );

        ordersToInsert.add(newOrder3);

        Order newOrder4 = (Order) TdfSObjectFactory.createSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
                AccountId = dpAccount2.Id,
                Grid__c = GRID2,
                Pricebook2Id = newPricebook.Id,
                aforza__Inventory__c = newInventory.Id,
                ShippingCity = 'Test City',
                ShippingStreet = 'Test Street',
                ShippingPostalCode = '054354',
                PaymentMethod__c = 'Cheque'
            )
        );
        ordersToInsert.add(newOrder4);
        insert ordersToInsert;

        List<OrderItem> orderItemsToInsert = new List<OrderItem>();
        OrderItem newOrderItem4 = (OrderItem) TdfSObjectFactory.createSObject(
            new OrderItem(
                OrderId = newOrder4.Id,
                Product2Id = newProduct2.Id,
                Quantity = 10,
                PricebookEntryId = productPricebookEntry2.Id
            )
        );
        orderItemsToInsert.add(newOrderItem4);
        OrderItem newOrderItem1 = (OrderItem) TdfSObjectFactory.createSObject(
            new OrderItem(
                OrderId = newOrder1.Id,
                Product2Id = newProduct1.Id,
                Quantity = 10,
                PricebookEntryId = productPricebookEntry1.Id
            )
        );
        orderItemsToInsert.add(newOrderItem1);
        OrderItem newOrderItem2 = (OrderItem) TdfSObjectFactory.createSObject(
            new OrderItem(
                OrderId = newOrder2.Id,
                Product2Id = newProduct2.Id,
                Quantity = 10,
                PricebookEntryId = productPricebookEntry2.Id
            )
        );
        orderItemsToInsert.add(newOrderItem2);
        OrderItem newOrderItem3 = (OrderItem) TdfSObjectFactory.createSObject(
            new OrderItem(
                OrderId = newOrder3.Id,
                Product2Id = newProduct1.Id,
                Quantity = 10,
                PricebookEntryId = productPricebookEntry1.Id
            )
        );
        orderItemsToInsert.add(newOrderItem3);
        insert orderItemsToInsert;

        // create Vehicle
        Vehicle__c newVehicle = (Vehicle__c) TdfSObjectFactory.insertSObject(
            new Vehicle__c(
                VehicleRegistration__c = VEHICLE_REGISTRATION_NUMBER,
                LoadCapacityWeight__c = VEHICLE_CAPACITY_WEIGHT,
                LoadLimitCases__c = VEHICLE_CAPACITY_CASES
            )
        );

        // create Load
        Load__c newLoad1 = (Load__c) TdfSObjectFactory.insertSObject(
            new Load__c(DeliveryDate__c = DELIVERY_DATE1, Vehicle__c = newVehicle.Id, Driver__c = UserInfo.getUserId())
        );
        Load__c newLoad2 = (Load__c) TdfSObjectFactory.insertSObject(
            new Load__c(DeliveryDate__c = DELIVERY_DATE2, Vehicle__c = newVehicle.Id, Driver__c = UserInfo.getUserId())
        );
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

        // add notes to the orders
        ContentVersion note = (ContentVersion) TdfSObjectFactory.insertSObject(
            new ContentVersion(VersionData = Blob.valueOf(FILE_CONTENT), PathOnClient = 'Note.sNote')
        );

        ContentVersion insertedNote = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :note.Id];

        TdfSObjectFactory.insertSObject(
            new ContentDocumentLink(ContentDocumentId = insertedNote.ContentDocumentId, LinkedEntityId = newOrder1.Id)
        );
        TdfSObjectFactory.insertSObject(
            new ContentDocumentLink(ContentDocumentId = insertedNote.ContentDocumentId, LinkedEntityId = newOrder2.Id)
        );
        TdfSObjectFactory.insertSObject(
            new ContentDocumentLink(ContentDocumentId = insertedNote.ContentDocumentId, LinkedEntityId = newOrder3.Id)
        );
        TdfSObjectFactory.insertSObject(
            new ContentDocumentLink(ContentDocumentId = insertedNote.ContentDocumentId, LinkedEntityId = newOrder4.Id)
        );

        Test.startTest();
        DeliveryManifestGenerationService service = new DeliveryManifestGenerationService(
            new List<String>{newOrder1.Id, newOrder2.Id, newOrder3.Id, newOrder4.Id}
        );
        List<DeliveryManifestGenerationService.Load> loads = service.getLoads();
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

        Order insertedOrder1 = [SELECT Id, GridDelivery__c FROM Order WHERE Id = :newOrder1.Id];
        Order insertedOrder2 = [SELECT Id, GridDelivery__c FROM Order WHERE Id = :newOrder2.Id];
        Order insertedOrder3 = [SELECT Id, GridDelivery__c FROM Order WHERE Id = :newOrder3.Id];
        Order insertedOrder4 = [SELECT Id, GridDelivery__c FROM Order WHERE Id = :newOrder4.Id];

        // check load details
        Assert.areEqual(2, loads.size());

        Assert.areEqual(insertedLoad1.Name, loads[0].loadID);
        Assert.areEqual(insertedLoad2.Name, loads[1].loadID);

        Assert.areEqual(insertedLoad1.Driver__r.Name, loads[0].driver);
        Assert.areEqual(insertedLoad2.Driver__r.Name, loads[1].driver);

        Assert.areEqual(insertedLoad1.Vehicle__r.VehicleRegistration__c, loads[0].vehicle);
        Assert.areEqual(insertedLoad2.Vehicle__r.VehicleRegistration__c, loads[1].vehicle);

        Assert.areEqual(insertedLoad1.DeliveryDate__c, loads[0].deliveryDate);
        Assert.areEqual(insertedLoad2.DeliveryDate__c, loads[1].deliveryDate);

        String vehicleCapacity = VEHICLE_CAPACITY_WEIGHT + ' ' + System.Label.DeliveryManifestKG + ', ' +
            VEHICLE_CAPACITY_CASES + ' ' + System.Label.DeliveryManifestCS;
        Assert.areEqual(vehicleCapacity, loads[0].vehicleCapacity);
        Assert.areEqual(vehicleCapacity, loads[1].vehicleCapacity);

        Decimal totalQuantity1 = newOrderItem1.Quantity + newOrderItem2.Quantity;
        Decimal totalQuantity2 = newOrderItem3.Quantity + newOrderItem4.Quantity;
        Assert.areEqual(totalQuantity1, loads[0].totalQuantity);
        Assert.areEqual(totalQuantity2, loads[1].totalQuantity);

        Decimal totalWeight1 = (newProduct1.aforza__Weight__c * newOrderItem1.Quantity) +
            (newProduct2.aforza__Weight__c * newOrderItem2.Quantity);
        Decimal totalWeight2 = (newProduct1.aforza__Weight__c * newOrderItem3.Quantity) +
            (newProduct2.aforza__Weight__c * newOrderItem4.Quantity);
        Assert.areEqual(totalWeight1, loads[0].totalWeight);
        Assert.areEqual(totalWeight2, loads[1].totalWeight);

        Assert.areEqual(2, loads[0].numberOfDps);
        Assert.areEqual(2, loads[1].numberOfDps);

        Assert.areEqual(2, loads[0].numberOfPallets);
        Assert.areEqual(2, loads[1].numberOfPallets);

        Assert.isTrue(loads[0].grid.contains(insertedOrder1.GridDelivery__c));
        Assert.isTrue(loads[0].grid.contains(insertedOrder2.GridDelivery__c));
        Assert.isTrue(loads[1].grid.contains(insertedOrder3.GridDelivery__c));
        Assert.isTrue(loads[1].grid.contains(insertedOrder4.GridDelivery__c));

        // check load items
        Assert.areEqual(2, loads[0].loadItems.size());
        Assert.areEqual(2, loads[1].loadItems.size());

        Assert.areEqual(PALLET_SEQUENCE1, loads[0].loadItems[0].palletSequence);
        Assert.areEqual(PALLET_SEQUENCE2, loads[0].loadItems[1].palletSequence);
        Assert.areEqual(PALLET_SEQUENCE1, loads[1].loadItems[0].palletSequence);
        Assert.areEqual(PALLET_SEQUENCE2, loads[1].loadItems[1].palletSequence);

        Assert.areEqual(PALLET_DESCRIPTION1, loads[0].loadItems[0].palletDescription);
        Assert.areEqual(PALLET_DESCRIPTION2, loads[0].loadItems[1].palletDescription);
        Assert.areEqual(PALLET_DESCRIPTION1, loads[1].loadItems[0].palletDescription);
        Assert.areEqual(PALLET_DESCRIPTION2, loads[1].loadItems[1].palletDescription);

        Assert.areEqual(FILE_CONTENT, loads[0].loadItems[0].notes);
        Assert.areEqual(FILE_CONTENT, loads[0].loadItems[1].notes);
        Assert.areEqual(FILE_CONTENT, loads[1].loadItems[0].notes);
        Assert.areEqual(FILE_CONTENT, loads[1].loadItems[1].notes);

        Assert.areEqual(dpAccount1.Name, loads[0].loadItems[0].accountName);
        Assert.areEqual(dpAccount2.Name, loads[0].loadItems[1].accountName);
        Assert.areEqual(dpAccount1.Name, loads[1].loadItems[0].accountName);
        Assert.areEqual(dpAccount2.Name, loads[1].loadItems[1].accountName);

        Assert.areEqual(dpAccount1.FixedDeliveryInstructions__c, loads[0].loadItems[0].deliveryInstructions);
        Assert.areEqual(dpAccount2.FixedDeliveryInstructions__c, loads[0].loadItems[1].deliveryInstructions);
        Assert.areEqual(dpAccount1.FixedDeliveryInstructions__c, loads[1].loadItems[0].deliveryInstructions);
        Assert.areEqual(dpAccount2.FixedDeliveryInstructions__c, loads[1].loadItems[1].deliveryInstructions);

        Assert.areEqual(dpAccount1.Phone, loads[0].loadItems[0].phone);
        Assert.areEqual(dpAccount2.Phone, loads[0].loadItems[1].phone);
        Assert.areEqual(dpAccount1.Phone, loads[1].loadItems[0].phone);
        Assert.areEqual(dpAccount2.Phone, loads[1].loadItems[1].phone);

        Assert.areEqual(newOrder1.PaymentMethod__c, loads[0].loadItems[0].paymentMethod);
        Assert.areEqual(newOrder2.PaymentMethod__c, loads[0].loadItems[1].paymentMethod);
        Assert.areEqual(newOrder3.PaymentMethod__c, loads[1].loadItems[0].paymentMethod);
        Assert.areEqual(newOrder4.PaymentMethod__c, loads[1].loadItems[1].paymentMethod);

        String openingTime1 = dpAccount1.OpeningTime__c.hour() + ':' + dpAccount1.OpeningTime__c.minute();
        String openingTime2 = dpAccount2.OpeningTime__c.hour() + ':' + dpAccount2.OpeningTime__c.minute();
        Assert.areEqual(openingTime1, loads[0].loadItems[0].openingTime);
        Assert.areEqual(openingTime2, loads[0].loadItems[1].openingTime);
        Assert.areEqual(openingTime1, loads[1].loadItems[0].openingTime);
        Assert.areEqual(openingTime2, loads[1].loadItems[1].openingTime);

        String address1 = newOrder1.ShippingStreet + ' ' + newOrder1.ShippingCity;
        String address2 = newOrder2.ShippingStreet + ' ' + newOrder2.ShippingCity;
        String address3 = newOrder3.ShippingStreet + ' ' + newOrder3.ShippingCity;
        String address4 = newOrder4.ShippingStreet + ' ' + newOrder4.ShippingCity;
        Assert.areEqual(address1, loads[0].loadItems[0].shippingAddress);
        Assert.areEqual(address2, loads[0].loadItems[1].shippingAddress);
        Assert.areEqual(address3, loads[1].loadItems[0].shippingAddress);
        Assert.areEqual(address4, loads[1].loadItems[1].shippingAddress);

        Assert.areEqual(newOrder1.ShippingPostalCode, loads[0].loadItems[0].shippingPostalCode);
        Assert.areEqual(newOrder2.ShippingPostalCode, loads[0].loadItems[1].shippingPostalCode);
        Assert.areEqual(newOrder3.ShippingPostalCode, loads[1].loadItems[0].shippingPostalCode);
        Assert.areEqual(newOrder4.ShippingPostalCode, loads[1].loadItems[1].shippingPostalCode);

        String tam = UserInfo.getName();
        Assert.areEqual(tam, loads[0].loadItems[0].tam);
        Assert.areEqual(tam, loads[0].loadItems[1].tam);
        Assert.areEqual(tam, loads[1].loadItems[0].tam);
        Assert.areEqual(tam, loads[1].loadItems[1].tam);

        Assert.areEqual(newOrderItem1.Quantity, loads[0].loadItems[0].quantity);
        Assert.areEqual(newOrderItem2.Quantity, loads[0].loadItems[1].quantity);
        Assert.areEqual(newOrderItem3.Quantity, loads[1].loadItems[0].quantity);
        Assert.areEqual(newOrderItem4.Quantity, loads[1].loadItems[1].quantity);

        Decimal orderWeight1 = newProduct1.aforza__Weight__c * newOrderItem1.Quantity;
        Decimal orderWeight2 = newProduct2.aforza__Weight__c * newOrderItem2.Quantity;
        Decimal orderWeight3 = newProduct1.aforza__Weight__c * newOrderItem3.Quantity;
        Decimal orderWeight4 = newProduct2.aforza__Weight__c * newOrderItem4.Quantity;
        Assert.areEqual(orderWeight1, loads[0].loadItems[0].weight);
        Assert.areEqual(orderWeight2, loads[0].loadItems[1].weight);
        Assert.areEqual(orderWeight3, loads[1].loadItems[0].weight);
        Assert.areEqual(orderWeight4, loads[1].loadItems[1].weight);
    }
}