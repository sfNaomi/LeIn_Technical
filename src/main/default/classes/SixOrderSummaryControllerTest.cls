/**
 * Created by naomi.gabriel on 12.10.2022.
 */
@IsTest
private class SixOrderSummaryControllerTest {
    private static List<SixOrderSummaryController.SkuDto> createTestSku(OrderItem ord, Product2 prod) {
        SixOrderSummaryController.SkuDto skuDto = new SixOrderSummaryController.SkuDto();

        skuDto.sku = prod.ProductCode;
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

        List<SixOrderSummaryController.skudto> skuList = new List<SixOrderSummaryController.skudto>();
        skuList.add(skuDto);

        return skuList;
    }

    @IsTest
    private static void testGetOrdersList_ValidOrder() {
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders', creditStatus__c = 'Good')
        );

        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(AccountId = dpAccount.Id, Status = 'Draft', EffectiveDate = Date.today(), RecordTypeId = RecordTypes.ORDER_TELESALES_ID)
        );
        TdfSObjectFactory.insertSObject(new OrderItem(OrderId = newOrder.Id, Quantity = 4));

        newOrder.Status = 'Activated';
        update newOrder;

        Test.startTest();
        List<SixOrderSummaryController.SkuDto> orderDtosToReturn = SixOrderSummaryController.getOrdersList(dpAccount.Id);
        Test.stopTest();

        Assert.isFalse(orderDtosToReturn.isEmpty());
    }

    @IsTest
    private static void testGetOrdersList_InvalidOrder() {
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
        
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders', CreditStatus__c = 'Good')
        );
    
        TdfSObjectFactory.insertSObject(
            new Order(AccountId = dpAccount.Id, Status = 'Draft', RecordTypeId = RecordTypes.ORDER_TELESALES_ID)
        );

        Test.startTest();
        List<SixOrderSummaryController.SkuDto> orderDtosToReturn = SixOrderSummaryController.getOrdersList(dpAccount.Id);
        Test.stopTest();

        Assert.areEqual(0, orderDtosToReturn.size(), '0 skuDto to be returned');
    }
  
    @IsTest
    static void testGetInventoryMap() {
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
        
        //method stores stock quantity from inventory to map
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

        // create inventory and add products to inventory
        aforza__Inventory__c newInventory = (aforza__Inventory__c) TdfSObjectFactory.insertSObject(
            new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID, InventoryCode__c = 'W')
        );
        TdfSObjectFactory.insertSObject(
            new aforza__Inventory_Product__c(
                aforza__Inventory__c = newInventory.Id,
                aforza__Product__c = newProduct1.Id,
                aforza__Stock_Quantity__c = 10
            )
        );
        TdfSObjectFactory.insertSObject(
            new aforza__Inventory_Product__c(
                aforza__Inventory__c = newInventory.Id,
                aforza__Product__c = newProduct2.Id,
                aforza__Stock_Quantity__c = 20
            )
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                aforza__Default_Price_Book__c = newPricebook.Id,
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3W7201MOW'
            )
        );

        // create orders and add products to it
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID, AccountId = dpAccount.Id, 
                Pricebook2Id = newPricebook.Id, aforza__Inventory__c = newInventory.Id
            )
        );
        OrderItem newOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(
                OrderId = newOrder.Id, Product2Id = newProduct1.Id,
                Quantity = 10, PricebookEntryId = product1PricebookEntry.Id
            )     
        );
        OrderItem newOrderItem2 = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(
                OrderId = newOrder.Id, Product2Id = newProduct2.Id,
                Quantity = 20, PricebookEntryId = product2PricebookEntry.Id
            )
        );
        
        Test.startTest();
        Map<String, aforza__Inventory_Product__c> prodInventMap = SixOrderSummaryController.getInventoryMap(
            dpAccount.Id, new List<OrderItem>{newOrderItem1, newOrderItem2}
        );
        Test.stopTest();
        
        Assert.areEqual(2, prodInventMap.size(), 'Should return 2 inventory products');
        Assert.areEqual(prodInventMap.get(newProduct1.Id).aforza__Stock_Quantity__c, 10, 'Product 1 inventory should be 10');
        Assert.areEqual(prodInventMap.get(newProduct2.Id).aforza__Stock_Quantity__c, 20, 'Product 1 inventory should be 20');
    }
  
    @IsTest
    static void testCreateSkus() {
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
    
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );
    
        Order newOrder1 = (Order) TdfSObjectFactory.insertSObject(
            new Order(AccountId = dpAccount.Id, Status = 'Draft', RecordTypeId = RecordTypes.ORDER_TELESALES_ID)
        );
    
        OrderItem newOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(OrderId = newOrder1.Id));
        OrderItem newOrderItem2 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(OrderId = newOrder1.Id));
        OrderItem newOrderItem3 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(OrderId = newOrder1.Id));
        OrderItem newOrderItem4 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(OrderId = newOrder1.Id));
      
        List<SixOrderSummaryController.SkuDto> orderDtosToReturn = new List<SixOrderSummaryController.SkuDto>();
        Map<String, aforza__Inventory_Product__c> prodInventMap = new Map<String, aforza__Inventory_Product__c>();
        Map<String, SixOrderSummaryController.SkuDto> skuDtoMap = new Map <String, SixOrderSummaryController.SkuDto>();
        Map<String, Integer> totalQuantityMap = new Map<String, Integer>();
    
        Test.startTest();
        orderDtosToReturn = SixOrderSummaryController.createSkus(
            new List<OrderItem>{newOrderItem1, newOrderItem2, newOrderItem3, newOrderItem4}, prodInventMap, skuDtoMap, totalQuantityMap, orderDtosToReturn
        );
        Test.stopTest();
    
        Assert.areEqual(4, orderDtosToReturn.size(), 'Should return 4 SkuDto items');
    }
  
    @IsTest
    static void testAddInventoryQuantity() {
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
        
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );
    
        Order newOrder1 = (Order) TdfSObjectFactory.insertSObject(
            new Order(AccountId = dpAccount.Id, Status = 'Draft', RecordTypeId = RecordTypes.ORDER_TELESALES_ID)
        );
        Order newOrder2 = (Order) TdfSObjectFactory.insertSObject(
            new Order(AccountId = dpAccount.Id, Status = 'Draft', RecordTypeId = RecordTypes.ORDER_TELESALES_ID)
        );
    
        OrderItem newOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(OrderId = newOrder1.Id, Quantity = 3));
        OrderItem newOrderItem2 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(OrderId = newOrder1.Id, Quantity = 4));
        OrderItem newOrderItem3 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(OrderId = newOrder2.Id, Quantity = 7));
        OrderItem newOrderItem4 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(OrderId = newOrder2.Id, Quantity = 8));

        Test.startTest();
        Map<String, List<Decimal>> mapProductEntity = new Map<String, List<Decimal>>();
        mapProductEntity = SixOrderSummaryController.addInventoryQuantity(
            new List<OrderItem>{newOrderItem1, newOrderItem2, newOrderItem3, newOrderItem4}, mapProductEntity
        );
        Test.stopTest();
    
        Decimal count = 0;
        Decimal total = 0;
        List<List<Decimal>> mapValues = mapProductEntity.values();
        
        for (List<Decimal> dList : mapValues) {
            for (Decimal d : dList) {
                total = total + d;
                count++;
            }
        }
        
        Assert.areEqual(count, 4, 'should be 4 order items');
        Assert.areEqual(total, 22, 'addition of all values, 3, 4 , 7, 8');
    }
  
    @IsTest
    static void testGetQuantityAndTotalOrders() {
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
    
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );
    
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(AccountId = dpAccount.Id, Status = 'Draft', RecordTypeId = RecordTypes.ORDER_TELESALES_ID)
        );
        OrderItem newOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(OrderId = newOrder.Id, Quantity = 3));
        OrderItem newOrderItem2 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(OrderId = newOrder.Id, Quantity = 4));
        OrderItem newOrderItem3 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(OrderId = newOrder.Id, Quantity = 7));
        OrderItem newOrderItem4 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(OrderId = newOrder.Id, Quantity = 8));
    
        OrderItem item1 = [SELECT Id, Product2Id FROM OrderItem WHERE Id =: newOrderItem1.Id];
        OrderItem item2 = [SELECT Id, Product2Id FROM OrderItem WHERE Id =: newOrderItem2.Id];
        OrderItem item3 = [SELECT Id, Product2Id FROM OrderItem WHERE Id =: newOrderItem3.Id];
        OrderItem item4 = [SELECT Id, Product2Id FROM OrderItem WHERE Id =: newOrderItem4.Id];

        Test.startTest();
        Map<String, SixOrderSummaryController.SkuDto> skuDtoMap = new Map<String, SixOrderSummaryController.SkuDto>();
        Map<String, Integer> totalQuantityMap = new Map<String, Integer>();
    
        Map<String, List<Decimal>> mapProductEntity = new Map<String, List<Decimal>>();
        mapProductEntity = SixOrderSummaryController.addInventoryQuantity(
            new List<OrderItem>{newOrderItem1, newOrderItem2, newOrderItem3, newOrderItem4}, mapProductEntity
        );
    
        Map<String, aforza__Inventory_Product__c> prodInventMap = SixOrderSummaryController.getInventoryMap(
            null, new List<OrderItem>{newOrderItem1, newOrderItem2, newOrderItem3, newOrderItem4}
        );
  
        List<SixOrderSummaryController.SkuDto> orderDtosToReturn = new List<SixOrderSummaryController.SkuDto>();
        SixOrderSummaryController.createSkus(
            new List<OrderItem>{newOrderItem1, newOrderItem2, newOrderItem3, newOrderItem4}, 
            prodInventMap, skuDtoMap, totalQuantityMap, orderDtosToReturn
        );
        
        Map<String, SixOrderSummaryController.SkuDto> returnskuDtoMap = SixOrderSummaryController.getQuantityAndTotalOrders(
            skuDtoMap, mapProductEntity
        );
        Test.stopTest();
        
        List<SixOrderSummaryController.SkuDto> skuValues = returnskuDtoMap.values();
        Assert.areEqual(skuValues[0].totalOrders, 4, 'Should return 4 SkuDto items');
        Assert.areEqual(skuValues[0].totalQuantity, 22, 'Should return 22 total items');
    }
  
    @IsTest
    static void testCalculateAverage() {
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
        
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders', CreditStatus__c = 'Good')
        );
    
        Order newOrder1 = (Order) TdfSObjectFactory.insertSObject(
            new Order(AccountId = dpAccount.Id, Status = 'Draft', RecordTypeId = RecordTypes.ORDER_TELESALES_ID)
        );
    
        OrderItem newOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(OrderId = newOrder1.Id, Quantity = 4));
        OrderItem newOrderItem2 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(PricebookEntryId = newOrderItem1.pricebookentryid, orderId = newOrder1.id, quantity = 20));
        
        OrderItem item1 = [SELECT Id, Product2Id FROM OrderItem WHERE Id =: newOrderItem1.Id];
        Product2 prod = [SELECT Id, ProductCode, StockKeepingUnit, IsActive FROM Product2 WHERE Id =: item1.Product2Id];

        Test.startTest();
        Map<String, SixOrderSummaryController.SkuDto> skuDtoMap = new Map<String, SixOrderSummaryController.SkuDto>();

        List<SixOrderSummaryController.SkuDto> sku1 = createTestSKu(newOrderItem1, prod);
        sku1[0].totalOrders = 2;
        sku1[0].totalQuantity = 24;
        skuDtoMap.put(sku1[0].productId, sku1[0]);
        
        List<SixOrderSummaryController.SkuDto> sku2 = createTestSKu(newOrderItem2, prod);
        sku2[0].totalOrders = 2;
        sku2[0].totalQuantity = 24;
        skuDtoMap.put(sku2[0].productId, sku2[0]);

        List<SixOrderSummaryController.SkuDto> orderDtosToReturn = new List<SixOrderSummaryController.SkuDto>();
        orderDtosToReturn = SixOrderSummaryController.calculateAverage(skuDtoMap, orderDtosToReturn);
        Test.stopTest();
    
        Assert.areEqual(orderDtosToReturn[0].average, 12, 'Average should be 12');
    }
  
    @IsTest
    static void testCalculateStockLeft() {
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
        
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders', CreditStatus__c = 'Good')
        );
    
        Order newOrder1 = (Order) TdfSObjectFactory.insertSObject(
            new Order(AccountId = dpAccount.Id, Status = 'Draft', RecordTypeId = RecordTypes.ORDER_TELESALES_ID)
        );
        OrderItem newOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(OrderId = newOrder1.Id, Quantity = 4));
        
        OrderItem item1 = [SELECT Id, Product2Id, PricebookEntryId FROM OrderItem WHERE Id =: newOrderItem1.Id];
        Product2 prod = [SELECT Id, ProductCode, StockKeepingUnit, IsActive FROM Product2 WHERE Id =: item1.Product2Id];
    
        OrderItem newOrderItem2 = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(PricebookEntryId = Item1.PricebookEntryId, OrderId = newOrder1.Id, Product2Id = prod.Id, Quantity = 20)
        );

        Test.startTest();
        Map<String, SixOrderSummaryController.SkuDto> skuDtoMap = new Map <String, SixOrderSummaryController.SkuDto>();
        
        List<SixOrderSummaryController.SkuDto> sku1 = createTestSKu(newOrderItem1, prod);
        sku1[0].totalOrders = 2;
        sku1[0].totalQuantity = 24;
        sku1[0].Average = 12;
        skuDtoMap.put(sku1[0].productid, sku1[0]);
        
        List<SixOrderSummaryController.SkuDto> sku2 = createTestSKu(newOrderItem2, prod);
        sku2[0].totalOrders = 2;
        sku2[0].Average = 12;
        skuDtoMap.put(sku2[0].productId, sku2[0]);
        
        List<SixOrderSummaryController.SkuDto> orderDtosToReturn = new List<SixOrderSummaryController.SkuDto>();
        orderDtosToReturn = SixOrderSummaryController.calculateStockLeft(skuDtoMap, orderDtosToReturn);
        Test.stopTest();
        
        Assert.areEqual(orderDtosToReturn[0].stockRemaining, -12, 'Stock remaining should be -12');
    }
  
    @IsTest
    private static void testGetOrderDates() {
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders', CreditStatus__c = 'Good')
        );

        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(AccountId = dpAccount.Id, Status = 'draft', EffectiveDate = Date.today(), RecordTypeId = RecordTypes.ORDER_TELESALES_ID)
        );
        TdfSObjectFactory.insertSObject(new OrderItem(OrderId = newOrder.Id, Quantity = 4));

        newOrder.Status = 'Activated';
        update newOrder;

        Test.startTest();
        List<SixOrderSummaryController.OrderDto> orderDtosToReturn = SixOrderSummaryController.getOrdersDates(dpAccount.id);
        Test.stopTest();

        Assert.areEqual(orderDtosToReturn[0].Id, newOrder.Id, 'Order Ids to match');
    }
  
    @IsTest
    static void testGetLastOrderLists() {
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders', creditStatus__c = 'Good')
        );
  
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(AccountId = dpAccount.Id, Status = 'Draft', EffectiveDate = Date.today(), RecordTypeId = RecordTypes.ORDER_TELESALES_ID)
        );
  
        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(OrderId = newOrder.Id, Quantity = 4));
  
        OrderItem item = [SELECT Id, Product2Id, PricebookEntryId FROM OrderItem WHERE Id = :newOrderItem.Id];
        Product2 prod = [SELECT Id, Family, ProductCode, StockKeepingUnit, IsActive FROM Product2 WHERE Id = :item.Product2Id];
  
        newOrder.Status = 'Activated';
        update newOrder;
        
        Test.startTest();
        List<OrderItem> orderItems = SixOrderSummaryController.getLastOrderLists(dpAccount.Id);
        Test.stopTest();
        
        Assert.areEqual(orderItems[0].Product2Id, prod.Id, 'Product Id should be same as in order item');
        Assert.areEqual(orderItems[0].OrderId, newOrder.Id, 'Product Id should be same as in order item');
    }
  
    @IsTest
    private static void testMapJson() {
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
        
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );

        Order oldOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(AccountId = dpAccount.Id, Status = 'Draft', RecordTypeId = RecordTypes.ORDER_TELESALES_ID)
        );
        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(OrderId = oldOrder.Id, Quantity = 3));
        
        OrderItem item = [SELECT Id, Product2Id, PricebookEntryId FROM OrderItem WHERE Id =: newOrderItem.Id];
        Product2 prod = [SELECT Id, ProductCode, StockKeepingUnit, IsActive FROM Product2 WHERE Id =: item.Product2Id];
    
        Map<String, String> jsonMap = new Map<String, String>{
            'productId' => prod.Id, 'Average' => '10', 'pricebookentryid' => newOrderItem.PricebookEntryId, 'unitPrice' => '8'
        };
    
        Test.startTest();
        SixOrderSummaryController.SkuDto newSku = SixOrderSummaryController.MapJson(jsonMap);
        Test.stopTest();
    
        Assert.areEqual(prod.Id, newSku.productId, 'Expected one order withs status draft');
        Assert.areEqual(newOrderItem.PricebookEntryId, newSku.pricebookentryid, 'Expected one order withs status draft');
    }
  
    @IsTest
    private static void testCreateOrder() {
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
        
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );
    
        Order oldOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(AccountId = dpAccount.Id, Status = 'Draft', RecordTypeId = RecordTypes.ORDER_TELESALES_ID)
        );
        OrderItem newOrderItem1 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(OrderId = oldOrder.Id, Quantity = 3));
        OrderItem newOrderItem2 = (OrderItem) TdfSObjectFactory.insertSObject(new OrderItem(OrderId = oldOrder.Id, Quantity = 8));

        OrderItem item1 = [SELECT Id, Product2Id, PricebookEntryId FROM OrderItem WHERE Id =: newOrderItem1.Id];
        Product2 prod = [SELECT Id, ProductCode, StockKeepingUnit, IsActive FROM Product2 WHERE Id = :item1.Product2Id];

        List<Map<String, String>> jsonMap = new List<Map<String, String>>{
            new Map<String, String>{'productId' => prod.Id, 'Average' => '10', 'pricebookentryid' => newOrderItem1.PricebookEntryId, 'unitPrice' => '8'},
            new Map<String, String>{'productId' => prod.Id, 'Average' => '4', 'pricebookentryid' => newOrderItem2.PricebookEntryId, 'unitPrice' => '4'}
        };
        
        Test.startTest();
        dpAccount.aforza__Default_Price_Book__c = oldOrder.Pricebook2Id;
        update dpAccount;

        String orderId = SixOrderSummaryController.createOrder(jsonMap, dpAccount.Id);
        Test.stopTest();
        
        Assert.isNotNull(orderId, 'Expected order id to be returned');
        Assert.areNotEqual(orderId, oldOrder.Id, 'Expected order id to be different from orginial order');
    }
  
    @IsTest
    static void testInsertOrder() {
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
        
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders', CreditStatus__c = 'Good')
        );
    
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(AccountId = dpAccount.Id, Status = 'Draft', RecordTypeId = RecordTypes.ORDER_TELESALES_ID)
        );
        TdfSObjectFactory.insertSObject(new OrderItem(OrderId = newOrder.Id));
        
        List<OrderItem> orderItems = [
            SELECT Id, OrderId, Product2Id, UnitPrice, PricebookEntryId, Quantity
            FROM OrderItem
            WHERE OrderId =: newOrder.Id
        ];
        
        Id newProductId = orderItems[0].Product2Id;
    
        Product2 newProduct = [
            SELECT Id, ProductCode, IsActive
            FROM Product2
            WHERE Id =: newProductId
        ];
    
        List<SixOrderSummaryController.SkuDto> skus = createTestSKu(orderItems[0], newProduct);
    
        Test.startTest();
        SixOrderSummaryController.insertOrder(skus, newOrder.Id);
        Test.stopTest();
  
        List<OrderItem> items = [
            SELECT Id, Quantity, Product2Id, OrderId, UnitPrice 
            FROM OrderItem 
            WHERE OrderId = :newOrder.Id
        ];

        Assert.areEqual(items[0].UnitPrice, OrderItems[0].UnitPrice, 'Should return same as original');
        Assert.areEqual(items[0].Quantity, OrderItems[0].Quantity, 'Should return same as original');
        Assert.areEqual(items[0].Product2Id, newProduct.Id, 'Should return same as original');
    }
  
    @IsTest
    private static void testCreateOrderDetails() {
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );
        
        Test.startTest();
        SixOrderSummaryController.createOrderDetails(dpAccount.Id);
        Test.stopTest();
        
        Order returnedOrder = [SELECT Id, Status FROM Order WHERE AccountId = :dpAccount.Id];
        Assert.areEqual('Draft', returnedOrder.Status, 'Expected one order withs status draft');
    }

    @IsTest
    private static void testComputeOffSaleStatus_OffSaleAtGlobalAndInventoryLevel() {
        String productOffSale = 'Yes';
        String inventoryProductOffSale= 'Yes';

        Test.startTest();
        Boolean isProductOffSale = SixOrderSummaryController.computeOffSaleStatus(productOffSale, inventoryProductOffSale);
        Test.stopTest();

        Assert.isTrue(isProductOffSale);
    }

    @IsTest
    private static void testComputeOffSaleStatus_OnSaleAtGlobalAndInventoryLevel() {
        String productOffSale = 'No';
        String inventoryProductOffSale= 'No';

        Test.startTest();
        Boolean isProductOffSale = SixOrderSummaryController.computeOffSaleStatus(productOffSale, inventoryProductOffSale);
        Test.stopTest();

        Assert.isFalse(isProductOffSale);
    }

    @IsTest
    private static void testComputeOffSaleStatus_OnSaleAtGlobalLevelOffSaleAtInventoryLevel() {
        String productOffSale = 'No';
        String inventoryProductOffSale= 'Yes';

        Test.startTest();
        Boolean isProductOffSale = SixOrderSummaryController.computeOffSaleStatus(productOffSale, inventoryProductOffSale);
        Test.stopTest();

        Assert.isTrue(isProductOffSale);
    }

    @IsTest
    private static void testComputeOffSaleStatus_OffSaleAtGlobalLevelOnSaleAtInventoryLevel() {
        String productOffSale = 'Yes';
        String inventoryProductOffSale= 'No';

        Test.startTest();
        Boolean isProductOffSale = SixOrderSummaryController.computeOffSaleStatus(productOffSale, inventoryProductOffSale);
        Test.stopTest();

        Assert.isFalse(isProductOffSale);
    }

    @IsTest
    private static void testComputeOffSaleStatus_UnknownAtGlobalLevelOnSaleAtInventoryLevel() {
        String productOffSale = null;
        String inventoryProductOffSale= 'No';

        Test.startTest();
        Boolean isProductOffSale = SixOrderSummaryController.computeOffSaleStatus(productOffSale, inventoryProductOffSale);
        Test.stopTest();

        Assert.isFalse(isProductOffSale);
    }

    @IsTest
    private static void testComputeOffSaleStatus_UnknownAtGlobalLevelOffSaleAtInventoryLevel() {
        String productOffSale = null;
        String inventoryProductOffSale= 'Yes';

        Test.startTest();
        Boolean isProductOffSale = SixOrderSummaryController.computeOffSaleStatus(productOffSale, inventoryProductOffSale);
        Test.stopTest();

        Assert.isTrue(isProductOffSale);
    }

    @IsTest
    private static void testComputeOffSaleStatus_OnSaleAtGlobalLevelUnknownAtInventoryLevel() {
        String productOffSale = 'No';
        String inventoryProductOffSale= null;

        Test.startTest();
        Boolean isProductOffSale = SixOrderSummaryController.computeOffSaleStatus(productOffSale, inventoryProductOffSale);
        Test.stopTest();

        Assert.isFalse(isProductOffSale);
    }

    @IsTest
    private static void testComputeOffSaleStatus_OffSaleAtGlobalLevelUnknownAtInventoryLevel() {
        String productOffSale = 'Yes';
        String inventoryProductOffSale= null;

        Test.startTest();
        Boolean isProductOffSale = SixOrderSummaryController.computeOffSaleStatus(productOffSale, inventoryProductOffSale);
        Test.stopTest();

        Assert.isTrue(isProductOffSale);
    }
}