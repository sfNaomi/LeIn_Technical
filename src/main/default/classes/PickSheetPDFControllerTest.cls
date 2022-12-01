/**
 * Created by magdalena.stanciu on 15.10.2022.
 */
@IsTest
private with sharing class PickSheetPDFControllerTest {
    private static final String GRID = '3C7201MOW';
    private static final String VEHICLE_REGISTRATION_NUMBER = 'AA11 AAA';
    private static final Date DELIVERY_DATE = Date.parse('12/10/2022');
    private static final Integer PALLET_SEQUENCE = 1;
    private static final String PALLET_DESCRIPTION = 'Description 1';
    private static final String PICK_LOCATION_PROD = 'A1';

    @IsTest
    private static void testInitializePageWithIncorrectParameters() {
        PageReference pageRef = Page.AGBarrPickSheet;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('p', 'test');

        Test.startTest();
        PickSheetPDFController ctrl = new PickSheetPDFController();
        Test.stopTest();

        Assert.areEqual(0, ctrl.loadPlans.size());
    }

    @IsTest
    private static void testInitializePageWithCorrectParameters_SingleOrder() {
        // create product
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());

        // add new product to standard PB
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add products to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry productPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
            aforza__Default_Price_Book__c = newPricebook.Id,
            RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
            PrimaryGridNumber__c = GRID
        ));

        // create inventory and add products to inventory
        aforza__Inventory__c newInventory = (aforza__Inventory__c) TdfSObjectFactory.insertSObject(
                new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID)
        );
        aforza__Inventory_Product__c newInventoryProduct1 = (aforza__Inventory_Product__c) TdfSObjectFactory.insertSObject(
            new aforza__Inventory_Product__c(
                aforza__Inventory__c = newInventory.Id,
                aforza__Product__c = newProduct.Id,
                PickingLocation__c = PICK_LOCATION_PROD
            )
        );

        // create orders and add products to it
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(
            RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
            AccountId = dpAccount.Id,
            Grid__c = GRID,
            Pricebook2Id = newPricebook.Id,
            aforza__Inventory__c = newInventory.Id
        ));
        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(
            OrderId = newOrder.Id,
            Product2Id = newProduct.Id,
            Quantity = 10,
            PricebookEntryId = productPricebookEntry.Id
        ));

        // create Vehicle
        Vehicle__c newVehicle = (Vehicle__c) TdfSObjectFactory.insertSObject(
            new Vehicle__c(VehicleRegistration__c = VEHICLE_REGISTRATION_NUMBER)
        );

        // create Load
        Load__c newLoad = (Load__c) TdfSObjectFactory.insertSObject(
            new Load__c(DeliveryDate__c = DELIVERY_DATE, Vehicle__c = newVehicle.Id, Driver__c = UserInfo.getUserId())
        );

        // add orders to the load
        List<Order> ordersToUpdate = new List<Order>();

        newOrder.Load__c = newLoad.Id;
        newOrder.PalletSequence__c = PALLET_SEQUENCE;
        newOrder.ShortDescription__c = PALLET_DESCRIPTION;
        ordersToUpdate.add(newOrder);

        update ordersToUpdate;

        PageReference pageRef = Page.AGBarrPickSheet;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('p', newOrder.Id);

        Test.startTest();
        PickSheetPDFController ctrl = new PickSheetPDFController();
        Test.stopTest();

        Assert.areEqual(1, ctrl.loadPlans.size());
    }

    @IsTest
    private static void testInitializePageWithCorrectParameters_MultipleOrders() {
        // create product
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());

        // add new product to standard PB
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add products to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry productPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
            aforza__Default_Price_Book__c = newPricebook.Id,
            RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
            PrimaryGridNumber__c = GRID
        ));

        // create inventory and add products to inventory
        aforza__Inventory__c newInventory = (aforza__Inventory__c) TdfSObjectFactory.insertSObject(
            new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID)
        );
        TdfSObjectFactory.insertSObject(
            new aforza__Inventory_Product__c(
                aforza__Inventory__c = newInventory.Id,
                aforza__Product__c = newProduct.Id,
                PickingLocation__c = PICK_LOCATION_PROD
            )
        );

        // create orders and add products to it
        Order newOrder1 = (Order) TdfSObjectFactory.insertSObject(new Order(
            RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
            AccountId = dpAccount.Id,
            Grid__c = GRID,
            Pricebook2Id = newPricebook.Id,
            aforza__Inventory__c = newInventory.Id
        ));
        TdfSObjectFactory.insertSObject(new OrderItem(
            OrderId = newOrder1.Id,
            Product2Id = newProduct.Id,
            Quantity = 10,
            PricebookEntryId = productPricebookEntry.Id
        ));

        Order newOrder2 = (Order) TdfSObjectFactory.insertSObject(new Order(
            RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
            AccountId = dpAccount.Id,
            Grid__c = GRID,
            Pricebook2Id = newPricebook.Id,
            aforza__Inventory__c = newInventory.Id
        ));
        OrderItem newOrderItem2 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(
            OrderId = newOrder1.Id,
            Product2Id = newProduct.Id,
            Quantity = 20,
            PricebookEntryId = productPricebookEntry.Id
        ));

        // create Vehicle
        Vehicle__c newVehicle = (Vehicle__c) TdfSObjectFactory.insertSObject(
            new Vehicle__c(VehicleRegistration__c = VEHICLE_REGISTRATION_NUMBER)
        );

        // create Load
        Load__c newLoad = (Load__c) TdfSObjectFactory.insertSObject(
            new Load__c(DeliveryDate__c = DELIVERY_DATE, Vehicle__c = newVehicle.Id, Driver__c = UserInfo.getUserId())
        );

        // add orders to the load
        List<Order> ordersToUpdate = new List<Order>();

        newOrder1.Load__c = newLoad.Id;
        newOrder1.PalletSequence__c = PALLET_SEQUENCE;
        newOrder1.ShortDescription__c = PALLET_DESCRIPTION;
        ordersToUpdate.add(newOrder1);

        newOrder2.Load__c = newLoad.Id;
        newOrder2.PalletSequence__c = PALLET_SEQUENCE;
        newOrder2.ShortDescription__c = PALLET_DESCRIPTION;
        ordersToUpdate.add(newOrder2);

        update ordersToUpdate;

        PageReference pageRef = Page.AGBarrPickSheet;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('p', newOrder1.Id + ',' + newOrder2.Id);

        Test.startTest();
        PickSheetPDFController ctrl = new PickSheetPDFController();
        Test.stopTest();

        Assert.areEqual(1, ctrl.loadPlans.size());
    }
}