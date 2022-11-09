@IsTest
private with sharing class InventoryProductServiceTest {

  @IsTest
  private static void updateInventoryStockNoUnfufilledOrdersWithoutStockQuantityUpdate() {
    // create products
    Product2 newProduct1 = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product', ProductCode = 'SKU1'));
    Product2 newProduct2 = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product', ProductCode = 'SKU2'));

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
      RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID
    ));

    // create inventory and add products to inventory
    aforza__Inventory__c newInventory = (aforza__Inventory__c) TdfSObjectFactory.insertSObject(
      new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID)
    );
    aforza__Inventory_Product__c newInventoryProduct1 = (aforza__Inventory_Product__c) TdfSObjectFactory.insertSObject(
      new aforza__Inventory_Product__c(
        aforza__Inventory__c = newInventory.Id,
        aforza__Product__c = newProduct1.Id,
        JDEStockQuantity__c = 200
      )
    );
    aforza__Inventory_Product__c newInventoryProduct2 = (aforza__Inventory_Product__c) TdfSObjectFactory.insertSObject(
      new aforza__Inventory_Product__c(
        aforza__Inventory__c = newInventory.Id,
        aforza__Product__c = newProduct2.Id,
        JDEStockQuantity__c = 100
      )
    );
    List < aforza__Inventory_Product__c > oldList = [SELECT Id, aforza__Stock_Quantity__c, JDEStockQuantity__c, NonSalableStock__c FROM aforza__Inventory_Product__c];

    Test.startTest();
    InventoryProductService.updateInventoryStock(new List < aforza__Inventory_Product__c > {
      newInventoryProduct1,
      newInventoryProduct2
    });
    Test.stopTest();

    List < aforza__Inventory_Product__c > newList = [SELECT Id, aforza__Stock_Quantity__c, JDEStockQuantity__c, NonSalableStock__c FROM aforza__Inventory_Product__c];


    System.assertEquals(200, newList[0].aforza__Stock_Quantity__c);
    System.assertEquals(100, newList[1].aforza__Stock_Quantity__c);

  }
  @IsTest
  private static void updateInventoryStockNoUnfufilledOrdersWithStockQuantityUpdate() {
    // create products
    Product2 newProduct1 = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product', ProductCode = 'SKU1'));
    Product2 newProduct2 = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product', ProductCode = 'SKU2'));

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
      RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID
    ));

    // create inventory and add products to inventory
    aforza__Inventory__c newInventory = (aforza__Inventory__c) TdfSObjectFactory.insertSObject(
      new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID)
    );
    aforza__Inventory_Product__c newInventoryProduct1 = (aforza__Inventory_Product__c) TdfSObjectFactory.insertSObject(
      new aforza__Inventory_Product__c(
        aforza__Inventory__c = newInventory.Id,
        aforza__Product__c = newProduct1.Id,
        NonSalableStock__c = 100,
        JDEStockQuantity__c = 200
      )
    );
    aforza__Inventory_Product__c newInventoryProduct2 = (aforza__Inventory_Product__c) TdfSObjectFactory.insertSObject(
      new aforza__Inventory_Product__c(
        aforza__Inventory__c = newInventory.Id,
        aforza__Product__c = newProduct2.Id,
        NonSalableStock__c = 50,
        JDEStockQuantity__c = 100
      )
    );
    List < aforza__Inventory_Product__c > oldList = [SELECT Id, aforza__Stock_Quantity__c, JDEStockQuantity__c, NonSalableStock__c FROM aforza__Inventory_Product__c];

    Test.startTest();
    InventoryProductService.updateInventoryStock(new List < aforza__Inventory_Product__c > {
      newInventoryProduct1,
      newInventoryProduct2
    });
    Test.stopTest();

    List < aforza__Inventory_Product__c > newList = [SELECT Id, aforza__Stock_Quantity__c, JDEStockQuantity__c, NonSalableStock__c FROM aforza__Inventory_Product__c];

    //Product 1 = 200 - (100 )  = 100
    System.assertEquals(200, oldList[0].JDEStockQuantity__c);
    System.assertEquals(100, oldList[0].NonSalableStock__c);
    System.assertEquals(100, newList[0].aforza__Stock_Quantity__c);

    //Product 2 = 100 - (50 )  = 50
    System.assertEquals(100, oldList[1].JDEStockQuantity__c);
    System.assertEquals(50, oldList[1].NonSalableStock__c);
    System.assertEquals(50, newList[1].aforza__Stock_Quantity__c);

  }

  @IsTest
  private static void updateInventoryStockOneFulfilledOrderOneUnfulfilledOrder() {
    // create products
    Product2 newProduct1 = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product', ProductCode = 'SKU1'));
    Product2 newProduct2 = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product', ProductCode = 'SKU2'));

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
      RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID
    ));

    // create inventory and add products to inventory
    aforza__Inventory__c newInventory = (aforza__Inventory__c) TdfSObjectFactory.insertSObject(
      new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID)
    );
    aforza__Inventory_Product__c newInventoryProduct1 = (aforza__Inventory_Product__c) TdfSObjectFactory.insertSObject(
      new aforza__Inventory_Product__c(
        aforza__Inventory__c = newInventory.Id,
        aforza__Product__c = newProduct1.Id,
        NonSalableStock__c = 100,
        JDEStockQuantity__c = 200
      )
    );
    aforza__Inventory_Product__c newInventoryProduct2 = (aforza__Inventory_Product__c) TdfSObjectFactory.insertSObject(
      new aforza__Inventory_Product__c(
        aforza__Inventory__c = newInventory.Id,
        aforza__Product__c = newProduct2.Id,
        NonSalableStock__c = 50,
        JDEStockQuantity__c = 100
      )
    );

    // create orders and add products to it
    Order newOrder1 = (Order) TdfSObjectFactory.insertSObject(new Order(
      RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
      AccountId = dpAccount.Id,
      Pricebook2Id = newPricebook.Id,
      aforza__Inventory__c = newInventory.Id,
      Status = 'Delivered'
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
      Pricebook2Id = newPricebook.Id,
      aforza__Inventory__c = newInventory.Id,
      Status = 'Draft'
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

    List < aforza__Inventory_Product__c > oldList = [SELECT Id, aforza__Stock_Quantity__c, JDEStockQuantity__c, NonSalableStock__c FROM aforza__Inventory_Product__c];
    
    Test.startTest();
    InventoryProductService.updateInventoryStock(new List < aforza__Inventory_Product__c > {
      newInventoryProduct1,
      newInventoryProduct2
    });
    Test.stopTest();

    List < aforza__Inventory_Product__c > newList = [select id, aforza__Stock_Quantity__c, JDEStockQuantity__c, NonSalableStock__c from aforza__Inventory_Product__c];

    //Product 1 = 200 - (100 + 10 )  = 90
    System.assertEquals(200, oldList[0].JDEStockQuantity__c);
    System.assertEquals(100, oldList[0].NonSalableStock__c);
    System.assertEquals(90, newList[0].aforza__Stock_Quantity__c);

    //Product 2 = 100 - (50 + 20 )  = 30
    System.assertEquals(100, oldList[1].JDEStockQuantity__c);
    System.assertEquals(50, oldList[1].NonSalableStock__c);
    System.assertEquals(30, newList[1].aforza__Stock_Quantity__c);
  }

  @IsTest
  private static void updateInventoryStockTwoUnfufilledOrders() {
    // create products
    Product2 newProduct1 = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product', ProductCode = 'SKU1'));
    Product2 newProduct2 = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product', ProductCode = 'SKU2'));

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
      RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID
    ));

    // create inventory and add products to inventory
    aforza__Inventory__c newInventory = (aforza__Inventory__c) TdfSObjectFactory.insertSObject(
      new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID)
    );
    aforza__Inventory_Product__c newInventoryProduct1 = (aforza__Inventory_Product__c) TdfSObjectFactory.insertSObject(
      new aforza__Inventory_Product__c(
        aforza__Inventory__c = newInventory.Id,
        aforza__Product__c = newProduct1.Id,
        NonSalableStock__c = 100,
        JDEStockQuantity__c = 200
      )
    );
    aforza__Inventory_Product__c newInventoryProduct2 = (aforza__Inventory_Product__c) TdfSObjectFactory.insertSObject(
      new aforza__Inventory_Product__c(
        aforza__Inventory__c = newInventory.Id,
        aforza__Product__c = newProduct2.Id,
        NonSalableStock__c = 50,
        JDEStockQuantity__c = 100
      )
    );

    // create orders and add products to it
    Order newOrder1 = (Order) TdfSObjectFactory.insertSObject(new Order(
      RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
      AccountId = dpAccount.Id,
      Pricebook2Id = newPricebook.Id,
      aforza__Inventory__c = newInventory.Id,
      Status = 'Delivered'
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
      Pricebook2Id = newPricebook.Id,
      aforza__Inventory__c = newInventory.Id,
      Status = 'Delivered'
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

    List < aforza__Inventory_Product__c > oldList = [SELECT Id, aforza__Stock_Quantity__c, JDEStockQuantity__c, NonSalableStock__c FROM aforza__Inventory_Product__c];

    Test.startTest();
    InventoryProductService.updateInventoryStock(new List < aforza__Inventory_Product__c > {
      newInventoryProduct1,
      newInventoryProduct2
    });
    Test.stopTest();

    List < aforza__Inventory_Product__c > newList = [SELECT Id, aforza__Stock_Quantity__c, JDEStockQuantity__c, NonSalableStock__c FROM aforza__Inventory_Product__c];

    //Product 1 = 200 - (100 + (10+30) )  = 60
    System.assertEquals(200, oldList[0].JDEStockQuantity__c);
    System.assertEquals(100, oldList[0].NonSalableStock__c);
    System.assertEquals(60, newList[0].aforza__Stock_Quantity__c);

    //Product 2 = 100 - (50 + (20 +40) )  = -10
    System.assertEquals(100, oldList[1].JDEStockQuantity__c);
    System.assertEquals(50, oldList[1].NonSalableStock__c);
    System.assertEquals(-10, newList[1].aforza__Stock_Quantity__c);

  }
 @IsTest
  private static void updateInventoryStockReciptedAndWithhIvoiceNotPushed() {
    // create products
    Product2 newProduct1 = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product', ProductCode = 'SKU1'));
    Product2 newProduct2 = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product', ProductCode = 'SKU2'));

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
      RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID
    ));

    // create inventory and add products to inventory
    aforza__Inventory__c newInventory = (aforza__Inventory__c) TdfSObjectFactory.insertSObject(
      new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID)
    );
    aforza__Inventory_Product__c newInventoryProduct1 = (aforza__Inventory_Product__c) TdfSObjectFactory.insertSObject(
      new aforza__Inventory_Product__c(
        aforza__Inventory__c = newInventory.Id,
        aforza__Product__c = newProduct1.Id,
        NonSalableStock__c = 100,
        JDEStockQuantity__c = 200
      )
    );
    aforza__Inventory_Product__c newInventoryProduct2 = (aforza__Inventory_Product__c) TdfSObjectFactory.insertSObject(
      new aforza__Inventory_Product__c(
        aforza__Inventory__c = newInventory.Id,
        aforza__Product__c = newProduct2.Id,
        NonSalableStock__c = 50,
        JDEStockQuantity__c = 100
      )
    );

    // create orders and add products to it
    Order newOrder1 = (Order) TdfSObjectFactory.insertSObject(new Order(
      RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
      AccountId = dpAccount.Id,
      Pricebook2Id = newPricebook.Id,
      aforza__Inventory__c = newInventory.Id,
      Status = 'Receipted'
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
    
        aforza__Invoice__c newInvoice1 = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(
                new aforza__Invoice__c(
                        aforza__Account__c = dpAccount.Id,
                        aforza__Order__c = newOrder1.Id,
                        PushedtoJde__c  = FALSE
                )
        );

    List < aforza__Inventory_Product__c > oldList = [SELECT Id, aforza__Stock_Quantity__c, JDEStockQuantity__c, NonSalableStock__c FROM aforza__Inventory_Product__c];

    Test.startTest();
    InventoryProductService.updateInventoryStock(new List < aforza__Inventory_Product__c > {
      newInventoryProduct1,
      newInventoryProduct2
    });
    Test.stopTest();

    List < aforza__Inventory_Product__c > newList = [SELECT Id, aforza__Stock_Quantity__c, JDEStockQuantity__c, NonSalableStock__c FROM aforza__Inventory_Product__c];

    //Product 1 = 200 - (100 + 10 )  = 90
    System.assertEquals(200, oldList[0].JDEStockQuantity__c);
    System.assertEquals(100, oldList[0].NonSalableStock__c);
    System.assertEquals(90, newList[0].aforza__Stock_Quantity__c);

    //Product 2 = 100 - (50 + 20 )  = 30
    System.assertEquals(100, oldList[1].JDEStockQuantity__c);
    System.assertEquals(50, oldList[1].NonSalableStock__c);
    System.assertEquals(30, newList[1].aforza__Stock_Quantity__c);

  }

}