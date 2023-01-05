public with sharing class SixOrderSummaryController {
    public class SkuDto {
        @AuraEnabled public String productId;
        @AuraEnabled public String description;
        @AuraEnabled public String sku;
        @AuraEnabled public String id;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public Integer totalOrders;
        @AuraEnabled public Decimal totalQuantity;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Integer average;
        @AuraEnabled public String effectiveDate;
        @AuraEnabled public String pricebookentryid;
        @AuraEnabled public Decimal unitPrice;
        @AuraEnabled public Boolean offSale;
        @AuraEnabled public Decimal stock;
        @AuraEnabled public Decimal stockRemaining;
        @AuraEnabled public String effectiveDateFieldName;
        @AuraEnabled public String orderId;
    }

    public class OrderDto {
        @AuraEnabled public String Id;
        @AuraEnabled public String EffectiveDate;
        @AuraEnabled public List <SkuDto> skus;
        @AuraEnabled public String sku;
        @AuraEnabled public String effectiveDateFieldName;
    }

    @AuraEnabled(cacheable = true)
    public static List<SkuDto> getOrdersList(String accountId) {
        List<SkuDto> orderDtosToReturn = new List<SkuDto>();
        Map<String, SkuDto> skuDtoMap = new Map<String, SkuDto>();
        Map<String, Integer> totalQuantityMap = new Map<String, Integer>();
        Map<String, List <Decimal>> mapProductEntity = new Map<String, List <Decimal>>();

        List<OrderItem> orders = getLastOrderLists(accountId);
        Map<String, aforza__Inventory_Product__c> prodInventMap = getInventoryMap(accountId, orders);

        orderDtosToReturn = createSkus(orders, prodInventMap, skuDtoMap, totalQuantityMap, orderDtosToReturn);
        mapProductEntity = addInventoryQuantity(orders, mapProductEntity);
        skuDtoMap = getQuantityAndTotalOrders(skuDtoMap, mapProductEntity);
        orderDtosToReturn = calculateAverage(skuDtoMap, orderDtosToReturn);
        orderDtosToReturn = calculateStockLeft(skuDtoMap, orderDtosToReturn);

        return orderDtosToReturn;
    }

    @TestVisible
    private static Map<String, aforza__Inventory_Product__c> getInventoryMap(String accountId, List<OrderItem> orders) {
        Set<Id> productIds = new Set<Id>();
        for (OrderItem ord : orders) {
            productIDs.add(ord.Product2Id);
        }

        List <aforza__Inventory_Product__c> inventoryProducts = [
            SELECT Id, aforza__Stock_Quantity__c, aforza__Product__c, OffSale__c, aforza__Inventory__c
            FROM aforza__Inventory_Product__c
            WHERE
                aforza__Product__c IN :productIDs AND
                aforza__Inventory__c IN (SELECT DefaultInventory__c FROM Account WHERE Id = :accountId)
        ];

        Map<String, aforza__Inventory_Product__c> inventoryProductsByProductId = new Map<String, aforza__Inventory_Product__c>();
        for (aforza__Inventory_Product__c newInventoryProduct : inventoryProducts) {
            inventoryProductsByProductId.put(newInventoryProduct.aforza__Product__c, newInventoryProduct);
        }

        return inventoryProductsByProductId;
    }

    @TestVisible
    private static List<SkuDto> createSkus(List<OrderItem> orders, Map<String, aforza__Inventory_Product__c> prodInventMap, Map<String, skuDto> skuDtoMap, Map<String, Decimal> totalQuantityMap, List<SkuDto> orderDtosToReturn) {
        try {
            Map<String, Decimal> quantityMap = new Map<String, Decimal>();

            for (OrderItem ord : orders) {
                SkuDto skuDto = new SkuDto();
                String orderDate = ord.Order?.EffectiveDate.format();
                skuDto.sku = ord.Product2.ProductCode;
                skuDto.description = ord.Product2?.Name;
                skuDto.productId = ord.Product2.Id;
                skuDto.isActive = ord.Product2.IsActive;
                skuDto.totalQuantity = 0;
                skuDto.totalOrders = 0;
                skuDto.quantity = ord.Quantity;
                skuDto.average = 0;
                skudto.id = ord.Id;
                skudto.unitPrice = ord.UnitPrice;
                skuDto.pricebookentryid = ord.PricebookEntryId;
                skuDto.effectiveDateFieldName = (orderDate + ord.Order.Id);
                skudto.effectiveDate = ord.Order?.EffectiveDate.format();

                String productOffSale = ord.Product2.OffSale__c;
                String inventoryProductOffSale = prodInventMap.get(ord.Product2Id)?.OffSale__c;
                skuDto.offSale = computeOffSaleStatus(productOffSale, inventoryProductOffSale);

                skuDto.stockRemaining = 0;
                skudto.stock = prodInventMap.get(ord.Product2.Id)?.aforza__Stock_Quantity__c;
                skuDtoMap.put(ord.Product2.Id, skuDto);

                quantityMap.put(ord.Product2.Id, 0);
                quantityMap.put(ord.Product2.Id, (quantityMap.get(ord.Product2.Id) + ord.Quantity));
                totalQuantityMap.put(ord.Product2.Id, 1);

                if (ord.Quantity != null && ord.Quantity > 0) {
                    orderDtosToReturn.add(skuDto);
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'No related product in inventory');
            throw PopulateAuraHandledException.newMessageException('Check all products are related to inventory');
        }

        return orderDtosToReturn;
    }

    @TestVisible
    private static Boolean computeOffSaleStatus(String productOffSale, String inventoryProductOffSale) {
        return inventoryProductOffSale == null ? (productOffSale == 'Yes' ? true : false) : (inventoryProductOffSale == 'Yes' ? true : false);
    }

    @TestVisible
    private static Map<String, List<Decimal>> addInventoryQuantity(List<OrderItem> orders, Map <String, List<Decimal>> mapProductEntity) {
        for (OrderItem et : orders) {
            if (mapProductEntity.containsKey(et.Product2.Id)) {
                mapProductEntity.get(et.Product2.Id).add(et.Quantity);
            } else {
                mapProductEntity.put(et.Product2.Id, new List<Decimal>{et.Quantity});
            }
        }
        return mapProductEntity;
    }

    @TestVisible
    private static Map<String, SkuDto> getQuantityAndTotalOrders(Map<String, SkuDto> skuDtoMap, Map<String, List<Decimal>> mapProductEntity) {
        for (String st : skuDtoMap.keyset()) {
            List<Decimal> thisList = mapProductEntity.get(st);
            Integer size = thisList.size();
            skuDtoMap.get(st).totalOrders = size;
            Decimal count = 0;
            for (Decimal i : thisList) {
                count = count + i;
            }
            skuDtoMap.get(st).totalQuantity = count;
        }
        return SkuDtoMap;
    }

    @TestVisible
    private static List<SkuDto> calculateAverage(Map<String, SkuDto> skuDtoMap, List<SkuDto> orderDtosToReturn) {
        for (String st : skuDtoMap.keyset()) {
            skuDtoMap.get(st).Average = Integer.valueOf((skuDtoMap.get(st).totalQuantity / skuDtoMap.get(st).totalOrders).round(RoundingMode.UP));
            orderDtosToReturn.add(skuDtoMap.get(st));
        }
        return orderDtosToReturn;
    }

    @TestVisible
    private static List<SkuDto> calculateStockLeft(Map<String, SkuDto> SkuDtoMap, List<skuDto> orderDtosToReturn) {
        for (String st : skuDtoMap.keyset()) {
         if (skuDtoMap.get(st).stock != null) {
                skuDtoMap.get(st).stockRemaining = Integer.valueOf((skuDtoMap.get(st).stock - skuDtoMap.get(st).Average));
            } else {
                skuDtoMap.get(st).stockRemaining = 0 - skuDtoMap.get(st).Average;
            }
            orderDtosToReturn.add(skuDtoMap.get(st));
        }
        return orderDtosToReturn;
    }

    @AuraEnabled(cacheable = true)
    public static List<OrderDto> getOrdersDates(String accountId) {
        List<OrderDto> orderDtoList = new List<OrderDto>();
        List<Order> orderList = [
            SELECT
                Id, EffectiveDate, Clone__c, Status, AccountId, Description, (SELECT OrderId FROM OrderItems)
            FROM Order
            WHERE
                AccountId = :accountId AND
                RecordType.DeveloperName IN :OrderService.RECORD_TYPES_TO_UPDATE_ACCOUNT_ON_ORDER_COMPLETION AND
                Status IN :OrderService.COMPLETED_ORDER_STATUSES AND
                Clone__c = FALSE
            ORDER BY EffectiveDate DESC
            LIMIT 6
        ];
        List<Order> orderedOrderList = [
            SELECT
                Id, EffectiveDate, Clone__c, Status, AccountId, Description, (SELECT OrderId FROM OrderItems)
            FROM Order
            WHERE Id IN :orderList
            ORDER BY EffectiveDate ASC
        ];

        for (Order ord : orderedOrderList) {
            String orderDate = ord.EffectiveDate.format();
            OrderDto orderDto = new OrderDto();
            orderDto.effectiveDate = orderDate;
            orderDto.id = ord.Id;
            orderDto.effectiveDateFieldName = (orderDate+ord.id);
            orderDtoList.add(orderDto);
        }

        return orderDtoList;
    }

    @AuraEnabled(cacheable = true)
    public static List<OrderItem> getLastOrderLists(String accountId) {
        try{
            List<Order> orderList = [
                SELECT
                    EffectiveDate, Status, Description, Id, (SELECT OrderId FROM OrderItems)
                FROM Order
                WHERE
                    AccountId = :accountId AND
                    RecordType.DeveloperName IN :OrderService.RECORD_TYPES_TO_UPDATE_ACCOUNT_ON_ORDER_COMPLETION AND
                    Status IN :OrderService.COMPLETED_ORDER_STATUSES AND
                    Clone__c = FALSE
                ORDER BY EffectiveDate DESC
                LIMIT 6
            ];

            List<String> orderNumbers = new List<String>();
            List<OrderItem> orderItemsList = new List<OrderItem>();
            for (Order orl : orderList) {
                orderNumbers.add(orl.Id);
            }
            orderItemsList = getAllOrderItems(orderNumbers);

            return orderItemsList;
        } catch (Exception e) {
            throw PopulateAuraHandledException.newMessageException('Check all necessary order detail are associated to Account');
        }
    }

    @TestVisible
    private static List<OrderItem> getAllOrderItems(List<String> orderIds) {
        List<OrderItem> orderItems = [
            SELECT
                Product2.ProductCode, Product2.Family, Quantity, Product2Id, PricebookEntryId,
                Product2.IsDRSProduct__c, Product2.Description, Product2.Name, Order.Id, Order.Effectivedate,
                UnitPrice, Order.Status, Product2.IsActive, Product2.OffSale__c
            FROM OrderItem
            WHERE
                Order.Id IN :orderIds AND
                Product2.Family = 'Product' AND
                Product2.IsDRSProduct__c = FALSE AND
                Order.RecordType.DeveloperName IN :OrderService.RECORD_TYPES_TO_UPDATE_ACCOUNT_ON_ORDER_COMPLETION AND
                Order.Status IN :OrderService.COMPLETED_ORDER_STATUSES AND
                Order.Clone__c = FALSE
            ORDER BY Order.EffectiveDate DESC
        ];
        return orderItems;
   }

    @AuraEnabled
    public static String createOrder(List<Map<String, String>> orderJSON, String accountId) {
        try {
            List<SkuDto> orderToSkuList = new List<SkuDto>();
            for (Map<String, String> mapJ : orderJson) {
                SkuDto newSku = mapJson(mapJ);
                orderToSkuList.add(newSku);
            }

            String orderId = createOrderDetails(accountId);
            insertOrder(orderToSkuList, orderId);

            return orderId;
        } catch (Exception e) {
            throw PopulateAuraHandledException.newMessageException('Check Pricebook entry matches products');
        }
    }

    @TestVisible
    private static SkuDto mapJson(Map <String, String> orderJSON) {
        SkuDto sku = new SkuDto();
        sku.productId = orderJSON.get('productId');
        sku.quantity = Decimal.valueof(orderJSON.get('Average'));
        sku.pricebookentryid = orderJSON.get('pricebookentryid');
        sku.unitPrice = Decimal.valueof(orderJSON.get('unitPrice'));
        return sku;
    }

    @TestVisible
    private static String insertOrder(List<SkuDto> skuList, Id ordId) {
        List<OrderItem> orderItems = new List<OrderItem>();

        OrderItem newI;
        for (SkuDto sku : skuList) {
            newI = new OrderItem(
                OrderId = ordId,
                Product2Id = sku?.productId,
                Quantity = sku?.quantity,
                PricebookEntryId = sku?.pricebookentryid,
                unitPrice = sku?.unitPrice,
                aforza__Type__c = 'Product');

            orderItems.add(newI);
        }
        insert orderItems;

        return ordId;
    }
    
    @TestVisible 
    private static String createOrderDetails(String accountId) {
        try {
            Account dPData = [
                SELECT
                    aforza__Default_Price_Book__c, BillingPostalCode, BillingCity,
                    BillingCountryCode, BillingState, BillingStateCode, BillingStreet, Depot__c,
                    /*NextDeliveryDate__c,*/ ShippingAddress, ShippingCity, ShippingCountry, ShippingCountryCode,
                    ShippingStateCode, ShippingStreet, Name, SalesRepresentativeCode__c, SalesRepresentative__c,
                    DefaultInventory__c, DeliveryPointReference__c, ShippingPostalCode
                FROM Account
                WHERE Id = :accountId
            ];
        
            Order newOrder = new Order();
            newOrder.put('Name', 'Suggested Order: ' + String.valueof(Date.today()));
            newOrder.Status = 'Draft';
            newOrder.Type = 'Product Order';
            newOrder.RecordTypeId = RecordTypes.ORDER_TELESALES_ID;
            newOrder.AccountId = accountId;
            newOrder.EffectiveDate = Date.today();
            //newOrder.DeliveryDate__c = dPData?.NextDeliveryDate__c;
            newOrder.Depot__c = dPData?.Depot__c;
            newOrder.SalesRepresentative__c = dpData?.SalesRepresentative__c;
            newOrder.SalesRepresentativeCode__c = dpData?.SalesRepresentativeCode__c;
            newOrder.OwnerId = UserInfo.getUserId();
            newOrder.aforza__Inventory__c = dpData?.DefaultInventory__c;
            newOrder.BillingCity = dpData?.BillingCity;
            newOrder.BillingPostalCode = dpData?.BillingPostalCode;
            newOrder.BillingStateCode = dpData?.BillingStateCode;
            newOrder.BillingCountryCode = dpData?.BillingCountryCode;
            newOrder.BillingStreet = dpData?.BillingStreet;
            newOrder.ShippingCity = dpData?.ShippingCity;
            newOrder.ShippingCountryCode = dpData?.ShippingCountryCode;
            newOrder.ShippingStateCode = dpData?.ShippingStateCode;
            newOrder.ShippingPostalCode = dpData?.ShippingPostalCode;
            newOrder.ShippingStreet = dpData?.ShippingStreet;
            newOrder.Pricebook2Id = dpData.aforza__Default_Price_Book__c;

            Database.SaveResult sr = Database.insert(newOrder);
            Id orderId = sr.getId();

            return orderId;
        } catch (Exception e) {
            throw PopulateAuraHandledException.newMessageException('Check all necessary order detail are associated to Account');
        }
    }
}