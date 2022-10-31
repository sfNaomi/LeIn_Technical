/**
 * Created by naomi.gabriel on 12.10.2022.
 */
@isTest
public class SixOrderSummaryControllerTest {

  private static List < SixOrderSummaryController.skuDto > CreateTestSKu(OrderItem ord, Product2 prod) {
    SixOrderSummaryController.SkuDto skuDto = new SixOrderSummaryController.SkuDto();
    skuDto.sku = Prod.ProductCode;
    skuDto.description = 'Description';
    skuDto.productId = prod.id;
    skuDto.isActive = Prod.IsActive;
    skuDto.totalQuantity = 0;
    skuDto.totalOrders = 0;
    skuDto.quantity = ord.quantity;
    skuDto.average = 0;
    skudto.id = ord.id;
    skudto.unitPrice = ord.unitPrice;
    skuDto.pricebookentryid = ord.pricebookentryid;
    skudto.effectiveDate = date.today().format();
    skuDto.stockRemaining = 0;
    List < SixOrderSummaryController.skudto > skuList = new List < SixOrderSummaryController.skudto > ();
    skuList.add(skuDto);
    return skuList;
  }

  @isTest
  private static void TestGetOrdersList_ValidOrder() {
    aforza__Attribute__c attribute = (aforza__Attribute__c) TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
    Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
      new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders', creditStatus__c = 'Good')
    );

    Test.startTest();
    Order newOrder1 = (Order) TdfSObjectFactory.insertSObject(
      new Order(AccountId = dpAccount.Id,
        Status = 'draft', effectiveDate = Date.today(),
        RecordTypeId = recordTypes.ORDER_TELESALES_ID));
    List < SixOrderSummaryController.skudto > orderDtosToReturn = new List < SixOrderSummaryController.skudto > ();

    OrderItem newOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(orderId = newOrder1.id, quantity = 4));

    newOrder1.Status = 'Activated';
    update newOrder1;
    orderDtosToReturn = SixOrderSummaryController.getOrdersList(dpAccount.id);
    Test.stopTest();

    system.debug(orderDtosToReturn);
  }

  @isTest
  private static void TestGetOrdersListInvalidOrder() {
    aforza__Attribute__c attribute = (aforza__Attribute__c) TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
    Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
      new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders', creditStatus__c = 'Good')
    );

    Order newOrder1 = (Order) TdfSObjectFactory.insertSObject(
      new Order(AccountId = dpAccount.Id,
        Status = 'draft',
        RecordTypeId = recordTypes.ORDER_TELESALES_ID));
    List < SixOrderSummaryController.skudto > orderDtosToReturn = new List < SixOrderSummaryController.skudto > ();

    orderDtosToReturn = SixOrderSummaryController.getOrdersList(dpAccount.id);
    system.debug(orderDtosToReturn);

    System.assertEquals(orderDtosToReturn.size(), 0, '0 skuDto to be returned');

  }

  @isTest
  static void TestGetInventoryMap() {
    aforza__Attribute__c attribute = (aforza__Attribute__c) TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
    //method stores stock quantity from inventory to map
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
        aforza__Stock_Quantity__c = 10
      )
    );
    aforza__Inventory_Product__c newInventoryProduct2 = (aforza__Inventory_Product__c) TdfSObjectFactory.insertSObject(
      new aforza__Inventory_Product__c(
        aforza__Inventory__c = newInventory.Id,
        aforza__Product__c = newProduct2.Id,
        aforza__Stock_Quantity__c = 20
      )
    );

    // create orders and add products to it
    Order newOrder1 = (Order) TdfSObjectFactory.insertSObject(new Order(
      RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
      AccountId = dpAccount.Id,
      Pricebook2Id = newPricebook.Id,
      aforza__Inventory__c = newInventory.Id
    ));
    OrderItem newOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(
      OrderId = newOrder1.Id,
      Product2Id = newProduct1.Id,
      Quantity = 10,
      PricebookEntryId = product1PricebookEntry.Id
    ));
    OrderItem newOrderItem2 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(
      OrderId = newOrder1.Id,
      Product2Id = newProduct2.Id,
      Quantity = 20,
      PricebookEntryId = product2PricebookEntry.Id
    ));

    Map < String, SixOrderSummaryController.SkuDto > skuDtoMap = new Map < String, SixOrderSummaryController.SkuDto > ();
    Map < String, Integer > totalQuantityMap = new Map < String, Integer > ();

    List < SixOrderSummaryController.skudto > orderDtosToReturn = new List < SixOrderSummaryController.skudto > ();

    Test.startTest();

    Map < String, aforza__Inventory_Product__c > prodInventMap = SixOrderSummaryController.getInventoryMap(new List < OrderItem > {
      newOrderItem1,
      newOrderItem2
    }, new Set < String > {
      newProduct1.id,
      newProduct2.id
    });
    system.debug(prodInventMap);

    Test.stopTest();
    System.assertEquals(2, prodInventMap.size(), 'Should return 2 inventory products');
    System.assertEquals(prodInventMap.get(newProduct1.id).aforza__Stock_Quantity__c, 10, 'Product 1 inventory should be 10');
    System.assertEquals(prodInventMap.get(newProduct2.id).aforza__Stock_Quantity__c, 20, 'Product 1 inventory should be 20');

  }

  @isTest
  static void TestCreateSkus() {
    aforza__Attribute__c attribute = (aforza__Attribute__c) TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

    Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
      new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
    );

    Order newOrder1 = (Order) TdfSObjectFactory.insertSObject(
      new Order(AccountId = dpAccount.Id,
        Status = 'draft',
        RecordTypeId = recordTypes.ORDER_TELESALES_ID));

    OrderItem newOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(orderId = newOrder1.id));
    OrderItem newOrderItem2 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(orderId = newOrder1.id));
    OrderItem newOrderItem3 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(orderId = newOrder1.id));
    OrderItem newOrderItem4 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(orderId = newOrder1.id));

    Map < String, SixOrderSummaryController.SkuDto > skuDtoMap = new Map < String, SixOrderSummaryController.SkuDto > ();
    Map < String, Integer > totalQuantityMap = new Map < String, Integer > ();

    List < SixOrderSummaryController.skudto > orderDtosToReturn = new List < SixOrderSummaryController.skudto > ();
    Map < String, aforza__Inventory_Product__c > prodInventMap = new Map < String, aforza__Inventory_Product__c > ();

    Test.startTest();

    orderDtosToReturn = SixOrderSummaryController.createSkus(new List < OrderItem > {
      newOrderItem1,
      newOrderItem2,
      newOrderItem3,
      newOrderItem4
    }, prodInventMap, skuDtoMap, totalQuantityMap, orderDtosToReturn);
    Test.stopTest();

    System.assertEquals(4, orderDtosToReturn.size(), 'Should return 4 SkuDto items');

  }

  @isTest
  static void TestaddInventoryQuantity() {
    aforza__Attribute__c attribute = (aforza__Attribute__c) TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
    Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
      new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
    );

    Order newOrder1 = (Order) TdfSObjectFactory.insertSObject(
      new Order(AccountId = dpAccount.Id,
        Status = 'draft',
        RecordTypeId = recordTypes.ORDER_TELESALES_ID));

    Order newOrder2 = (Order) TdfSObjectFactory.insertSObject(
      new Order(AccountId = dpAccount.Id,
        Status = 'draft',
        RecordTypeId = recordTypes.ORDER_TELESALES_ID));

    OrderItem newOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(orderId = newOrder1.id, quantity = 3));
    OrderItem newOrderItem2 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(orderId = newOrder1.id, quantity = 4));
    OrderItem newOrderItem3 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(orderId = newOrder2.id, quantity = 7));
    OrderItem newOrderItem4 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(orderId = newOrder2.id, quantity = 8));

    Map < String, List < Decimal >> mapProductEntity = new Map < String, List < Decimal >> ();

    List < SixOrderSummaryController.skudto > orderDtosToReturn = new List < SixOrderSummaryController.skudto > ();

    Test.startTest();

    mapProductEntity = SixOrderSummaryController.addInventoryQuantity(new List < OrderItem > {
      newOrderItem1,
      newOrderItem2,
      newOrderItem3,
      newOrderItem4
    }, mapProductEntity);
    Test.stopTest();

    Decimal count = 0;
    Decimal total = 0;
    List < List < Decimal >> mapValues = mapProductEntity.values();
    List < String > res = new List < String > ();
    for (List < Decimal > dList: mapValues) {
      for (Decimal d: dList) {
        total = total + d;
        count++;
      }

    }
    System.assertEquals(count, 4, 'should be 4 order items');
    System.assertEquals(total, 22, 'addition of all values, 3, 4 , 7, 8');

  }

  @isTest
  static void getQuantityAndTotalOrders() {
    aforza__Attribute__c attribute = (aforza__Attribute__c) TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

    Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
      new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
    );

    Order newOrder1 = (Order) TdfSObjectFactory.insertSObject(
      new Order(AccountId = dpAccount.Id,
        Status = 'draft',
        RecordTypeId = recordTypes.ORDER_TELESALES_ID));

    OrderItem newOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(orderId = newOrder1.id, quantity = 3));
    OrderItem newOrderItem2 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(orderId = newOrder1.id, quantity = 4));
    OrderItem newOrderItem3 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(orderId = newOrder1.id, quantity = 7));
    OrderItem newOrderItem4 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(orderId = newOrder1.id, quantity = 8));

    OrderItem item1 = [SELECT id, Product2Id FROM orderitem where id =: newOrderItem1.id];
    OrderItem item2 = [SELECT id, Product2Id FROM orderitem where id =: newOrderItem2.id];
    OrderItem item3 = [SELECT id, Product2Id FROM orderitem where id =: newOrderItem3.id];
    OrderItem item4 = [SELECT id, Product2Id FROM orderitem where id =: newOrderItem4.id];

    Map < String, SixOrderSummaryController.SkuDto > skuDtoMap = new Map < String, SixOrderSummaryController.SkuDto > ();
    Map < String, Integer > totalQuantityMap = new Map < String, Integer > ();

    List < SixOrderSummaryController.skudto > orderDtosToReturn = new List < SixOrderSummaryController.skudto > ();
    Map < String, List < Decimal >> mapProductEntity = new Map < String, List < Decimal >> ();

    List < SixOrderSummaryController.skudto > orderDtosToReturnList = new List < SixOrderSummaryController.skudto > ();

    mapProductEntity = SixOrderSummaryController.addInventoryQuantity(new List < OrderItem > {
      newOrderItem1,
      newOrderItem2,
      newOrderItem3,
      newOrderItem4
    }, mapProductEntity);

    Map < String, aforza__Inventory_Product__c > prodInventMap = SixOrderSummaryController.getInventoryMap(new List < OrderItem > {
      newOrderItem1,
      newOrderItem2,
      newOrderItem3,
      newOrderItem4
    }, new Set < String > {
      item1.product2Id,
      item2.Product2Id,
      item3.product2Id,
      item4.Product2Id

    });
    SixOrderSummaryController.createSkus(new List < OrderItem > {
      newOrderItem1,
      newOrderItem2,
      newOrderItem3,
      newOrderItem4
    }, prodInventMap, skuDtoMap, totalQuantityMap, orderDtosToReturn);
    Map < String, SixOrderSummaryController.SkuDto > ReturnskuDtoMap = SixOrderSummaryController.getQuantityAndTotalOrders(skuDtoMap, mapProductEntity);

    system.debug('ReturnskuDtoMap');
    List < SixOrderSummaryController.SkuDto > skuValues = ReturnskuDtoMap.values();
    system.debug(skuValues);
    System.assertEquals(skuValues[0].totalOrders, 4, 'Should return 4 SkuDto items');
    System.assertEquals(skuValues[0].totalQuantity, 22, 'Should return 22 total items');

  }

  @isTest
  static void TestCalculateAverage() {
    aforza__Attribute__c attribute = (aforza__Attribute__c) TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
    Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
      new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders', creditStatus__c = 'Good')
    );

    Order newOrder1 = (Order) TdfSObjectFactory.insertSObject(
      new Order(AccountId = dpAccount.Id,
        Status = 'draft',
        RecordTypeId = recordTypes.ORDER_TELESALES_ID));

    OrderItem newOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(orderId = newOrder1.id, quantity = 4));

    OrderItem newOrderItem2 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(PricebookEntryId = newOrderItem1.pricebookentryid, orderId = newOrder1.id, quantity = 20));
    OrderItem item1 = [SELECT id, Product2Id FROM orderitem where id =: newOrderItem1.id];
    Product2 prod = [SELECT id, productCode, StockKeepingUnit, isActive from product2 where id =: item1.Product2Id];

    Map < String, aforza__Inventory_Product__c > prodInventMap = new Map < String, aforza__Inventory_Product__c > ();

    Map < String, SixOrderSummaryController.SkuDto > skuDtoMap = new Map < String, SixOrderSummaryController.SkuDto > ();
    Map < String, Integer > totalQuantityMap = new Map < String, Integer > ();

    List < SixOrderSummaryController.skudto > orderDtosToReturn = new List < SixOrderSummaryController.skudto > ();

    list < SixOrderSummaryController.skudto > sku1 = CreateTestSKu(newOrderItem1, prod);
    sku1[0].totalOrders = 2;
    sku1[0].totalQuantity = 24;
    skuDtoMap.put(sku1[0].productid, sku1[0]);
    list < SixOrderSummaryController.skudto > sku2 = CreateTestSKu(newOrderItem2, prod);
    sku2[0].totalOrders = 2;
    sku2[0].totalQuantity = 24;
    skuDtoMap.put(sku2[0].productid, sku2[0]);

    orderDtosToReturn = SixOrderSummaryController.calculateAverage(skuDtoMap, orderDtosToReturn);

    System.assertEquals(orderDtosToReturn[0].average, 12, 'Average should be 12');

  }

  @isTest
  static void TestCalculateStockLeft() {
    aforza__Attribute__c attribute = (aforza__Attribute__c) TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
    Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
      new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders', creditStatus__c = 'Good')
    );

    Order newOrder1 = (Order) TdfSObjectFactory.insertSObject(
      new Order(AccountId = dpAccount.Id,
        Status = 'draft',
        RecordTypeId = recordTypes.ORDER_TELESALES_ID));

    OrderItem newOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(orderId = newOrder1.id, quantity = 4));
    OrderItem item1 = [SELECT id, Product2Id, pricebookEntryId FROM orderitem where id =: newOrderItem1.id];

    Product2 prod = [SELECT id, productCode, StockKeepingUnit, isActive from product2 where id =: item1.Product2Id];

    OrderItem newOrderItem2 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(PricebookEntryId = Item1.pricebookentryid,
      orderId = newOrder1.id, product2Id = prod.id, quantity = 20));

    Map < String, SixOrderSummaryController.SkuDto > skuDtoMap = new Map < String, SixOrderSummaryController.SkuDto > ();
    Map < String, Integer > totalQuantityMap = new Map < String, Integer > ();

    List < SixOrderSummaryController.skudto > orderDtosToReturn = new List < SixOrderSummaryController.skudto > ();

    list < SixOrderSummaryController.skudto > sku1 = CreateTestSKu(newOrderItem1, prod);
    sku1[0].totalOrders = 2;
    sku1[0].totalQuantity = 24;
    sku1[0].Average = 12;

    skuDtoMap.put(sku1[0].productid, sku1[0]);
    list < SixOrderSummaryController.skudto > sku2 = CreateTestSKu(newOrderItem2, prod);
    sku2[0].totalOrders = 2;
    sku2[0].Average = 12;

    skuDtoMap.put(sku2[0].productid, sku2[0]);

    orderDtosToReturn = SixOrderSummaryController.calculateStockLeft(skuDtoMap, orderDtosToReturn);

    system.debug(orderDtosToReturn);
    System.assertEquals(orderDtosToReturn[0].stockRemaining, -12, 'Stock remaining should be -12');

  }

  @isTest
  private static void TestGetOrderDates() {
    aforza__Attribute__c attribute = (aforza__Attribute__c) TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
    Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
      new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders', creditStatus__c = 'Good')
    );

    Test.startTest();
    Order newOrder1 = (Order) TdfSObjectFactory.insertSObject(
      new Order(AccountId = dpAccount.Id,
        Status = 'draft', effectiveDate = Date.today(),
        RecordTypeId = recordTypes.ORDER_TELESALES_ID));

    OrderItem newOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(orderId = newOrder1.id, quantity = 4));
    List < SixOrderSummaryController.OrderDto > orderDtosToReturn = new List < SixOrderSummaryController.orderDto > ();

    newOrder1.Status = 'Activated';
    update newOrder1;
    orderDtosToReturn = SixOrderSummaryController.getOrdersDates(dpAccount.id);

    Test.stopTest();
    System.assertEquals(orderDtosToReturn[0].id, newOrder1.id, 'Order Ids to match');

    system.debug(orderDtosToReturn);
  }

  @isTest
  static void TestgetLastOrderLists() {
    aforza__Attribute__c attribute = (aforza__Attribute__c) TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
    Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
      new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders', creditStatus__c = 'Good')
    );

    Test.startTest();
    Order newOrder1 = (Order) TdfSObjectFactory.insertSObject(
      new Order(AccountId = dpAccount.Id,
        Status = 'draft', effectiveDate = Date.today(),
        RecordTypeId = recordTypes.ORDER_TELESALES_ID));
    List < OrderItem > orderItems = new List < OrderItem > ();

    OrderItem newOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(orderId = newOrder1.id, quantity = 4));
    OrderItem item1 = [SELECT id, Product2Id, pricebookEntryId FROM orderitem where id =: newOrderItem1.id];

    Product2 prod = [SELECT id, family, productCode, StockKeepingUnit, isActive from product2 where id =: item1.Product2Id];

    newOrder1.Status = 'Activated';
    update newOrder1;
    orderItems = SixOrderSummaryController.getLastOrderLists(dpAccount.id);
    Test.stopTest();
    system.debug(orderItems);
    System.assertEquals(orderItems[0].product2Id, prod.id, 'Product Id should be same as in order item');
    System.assertEquals(orderItems[0].orderId, newOrder1.id, 'Product Id should be same as in order item');

  }

  @IsTest
  private static void testMapJson() {
    aforza__Attribute__c attribute = (aforza__Attribute__c) TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
    Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
      new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
    );
    Order oldOrder1 = (Order) TdfSObjectFactory.insertSObject(
      new Order(AccountId = dpAccount.Id,
        Status = 'draft',
        RecordTypeId = recordTypes.ORDER_TELESALES_ID));

    OrderItem newOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(orderId = oldOrder1.id, quantity = 3));
    OrderItem item1 = [SELECT id, Product2Id, pricebookEntryId FROM orderitem where id =: newOrderItem1.id];

    Product2 prod = [SELECT id, productCode, StockKeepingUnit, isActive from product2 where id =: item1.Product2Id];

    Map < String, String > jsonMap = new Map < String, String > {
      'productId' => prod.id,
      'Average' => '10',
      'pricebookentryid' => newOrderItem1.pricebookEntryId,
      'unitPrice' => '8'
    };

    Test.startTest();
    SixOrderSummaryController.skuDto newSku = SixOrderSummaryController.MapJson(jsonMap);
    Test.stopTest();

    System.assertEquals(Prod.id, newSku.productId, 'Expected one order withs status draft');
    System.assertEquals(newOrderItem1.pricebookEntryid, newSku.pricebookEntryid, 'Expected one order withs status draft');

  }

  @IsTest
  private static void testCreateOrder() {
    aforza__Attribute__c attribute = (aforza__Attribute__c) TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
    Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
      new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
    );

    Order oldOrder1 = (Order) TdfSObjectFactory.insertSObject(
      new Order(AccountId = dpAccount.Id,
        Status = 'draft',
        RecordTypeId = recordTypes.ORDER_TELESALES_ID));

    OrderItem newOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(orderId = oldOrder1.id, quantity = 3));
    OrderItem newOrderItem2 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(orderId = oldOrder1.id, quantity = 8));
    OrderItem item1 = [SELECT id, Product2Id, pricebookEntryId FROM orderitem where id =: newOrderItem1.id];

    Product2 prod = [SELECT id, productCode, StockKeepingUnit, isActive from product2 where id =: item1.Product2Id];

    List < Map < String, String >> jsonMap = new List < Map < String, String >> {
      new Map < String,
      String > {
        'productId' => prod.id,
        'Average' => '10',
        'pricebookentryid' => newOrderItem1.pricebookEntryId,
        'unitPrice' => '8'
      },
      new Map < String,
      String > {
        'productId' => prod.id,
        'Average' => '4',
        'pricebookentryid' => newOrderItem2.pricebookEntryId,
        'unitPrice' => '4'
      }
    };
    List < SixOrderSummaryController.SkuDto > OrderToSkuList = new List < SixOrderSummaryController.SkuDto > ();

    Test.startTest();
    dpAccount.aforza__Default_Price_Book__c = oldOrder1.Pricebook2Id;

    update dpAccount;
    String orderid = SixOrderSummaryController.createOrder(jsonMap, dpAccount.id);
    Test.stopTest();

    system.debug(OrderToSkuList);
    System.assertEquals(orderid == null, false, 'Expected order id to be returned');
    System.assertEquals(orderid == oldOrder1.id, false, 'Expected order id to be different from orginial order');

  }

  @isTest
  static void TestInsertOrder() {
    aforza__Attribute__c attribute = (aforza__Attribute__c) TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
    Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
      new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders', creditStatus__c = 'Good')
    );

    Order newOrder1 = (Order) TdfSObjectFactory.insertSObject(
      new Order(AccountId = dpAccount.Id,
        Status = 'draft',
        RecordTypeId = recordTypes.ORDER_TELESALES_ID));

    OrderItem newOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(orderId = newOrder1.id));
    List < OrderItem > OrderItems = [
      SELECT Id, OrderId, Product2Id, UnitPrice, pricebookentryid, quantity
      FROM OrderItem
      WHERE OrderId =: newOrder1.Id
    ];
    Id newProduct1Id = OrderItems[0].Product2Id;

    Product2 newProduct1 = [
      SELECT Id, productCode, isActive
      FROM Product2
      WHERE Id =: newProduct1Id
    ];
    Map < String, aforza__Inventory_Product__c > prodInventMap = new Map < String, aforza__Inventory_Product__c > ();

    Map < String, SixOrderSummaryController.SkuDto > skuDtoMap = new Map < String, SixOrderSummaryController.SkuDto > ();
    Map < String, Integer > totalQuantityMap = new Map < String, Integer > ();

    List < SixOrderSummaryController.skudto > orderDtosToReturn = new List < SixOrderSummaryController.skudto > ();

    list < SixOrderSummaryController.skudto > skus = CreateTestSKu(OrderItems[0], newProduct1);

    Test.startTest();

    String orderId = SixOrderSummaryController.InsertOrder(skus, newOrder1.id);

    List < orderItem > items = [select id, Quantity, product2Id, orderId, unitPrice from orderItem where orderId =: newOrder1.id];
    system.debug('orders itemms in test' + items);
    Test.stopTest();
    System.assertEquals(items[0].unitPrice, OrderItems[0].unitPrice, 'Should return same as original');
    System.assertEquals(items[0].quantity, OrderItems[0].quantity, 'Should return same as original');
    System.assertEquals(items[0].product2Id, newProduct1.Id, 'Should return same as original');

  }

  @IsTest
  private static void testCreateOrderDetails() {
    aforza__Attribute__c attribute = (aforza__Attribute__c) TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
    Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
      new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
    );
    Test.startTest();
    SixOrderSummaryController.createOrderDetails(dpAccount.id);
    Test.stopTest();
    Order returnedOrder = [select Id, status from order where accountid =: dpAccount.id];
    System.assertEquals('Draft', returnedOrder.status, 'Expected one order withs status draft');

  }

}
