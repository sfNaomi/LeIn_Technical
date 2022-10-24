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
        @AuraEnabled public Decimal stock;
        @AuraEnabled public Decimal stockRemaining;
        @AuraEnabled public String effectiveDateFieldName;
        @AuraEnabled public String orderId;

    }

    public class OrderDto {
        @AuraEnabled public String Id;
        @AuraEnabled public String EffectiveDate;
        @AuraEnabled public List < SkuDto > skus;
        @AuraEnabled public String sku;
        @AuraEnabled public String effectiveDateFieldName;
    }


    @AuraEnabled(cacheable = true)
    public static List < skudto > getOrdersList(String accountId) {

        Map < String, SkuDto > skuDtoMap = new Map < String, SkuDto > ();
        Map < String, Integer > totalQuantityMap = new Map < String, Integer > ();

        List < skudto > orderDtosToReturn = new List < skudto > ();
        Set < String > assignedSkus = new Set < String > ();
        Set < String > productIDs = new Set < String > ();
        Map < String, String > skuProductIDmap = new Map < String, String > ();
        Map < String, List < Decimal >> mapProductEntity = new Map < String, List < Decimal >> ();
        List < OrderItem > orders = getLastOrderLists(accountId);
        Map < String, aforza__Inventory_Product__c > prodInventMap = getInventoryMap(orders, productIDs);  
        orderDtosToReturn = createSkus(orders, prodInventMap, skuDtoMap, totalQuantityMap, orderDtosToReturn); 
        mapProductEntity = addInventoryQuantity(orders, mapProductEntity);

        skuDtoMap = getQuantityAndTotalOrders(skuDtoMap, mapProductEntity);
        orderDtosToReturn = calculateAverage(skuDtoMap, orderDtosToReturn);
        orderDtosToReturn = calculateStockLeft(skuDtoMap, orderDtosToReturn);
        system.debug(orderDtosToReturn);
        return orderDtosToReturn;
    }

    @TestVisible 
    private static Map < String, aforza__Inventory_Product__c > getInventoryMap(List < orderItem > orders, Set < String > productIDs) {

        for (OrderItem ord: orders) {
            productIDs.add(ord.product2.id);
        }
        List < aforza__Inventory_Product__c > InventoryProducts = [Select id, aforza__Stock_Quantity__c, aforza__Product__c
            from aforza__Inventory_Product__c where aforza__Product__c in: productIDs
        ];
        Map < String, aforza__Inventory_Product__c > ProdIDAforzaInventMap = new Map < String, aforza__Inventory_Product__c > ();
        for (aforza__Inventory_Product__c objCS: InventoryProducts) {
            prodIDAforzaInventMap.put(objCS.aforza__Product__c, objCS);
        }
        return prodIDAforzaInventMap;
    }

    @TestVisible 
    private static List < skuDto > createSkus(List < ORderItem > orders, Map < String, aforza__Inventory_Product__c > prodInventMap, Map < String, skuDto > skuDtoMap, Map < String, Decimal > totalQuantityMap, List < skuDto > orderDtosToReturn) {
        try {
        Map < String, Decimal > quantityMap = new Map < String, Decimal > ();
       
            for (OrderItem ord: orders) {
                SkuDto skuDto = new SkuDto();
                String orderDate = ord.order?.EffectiveDate.format();
                skuDto.sku = ord.Product2.ProductCode;
                skuDto.description = ord.Product2?.Name;
                skuDto.productId = ord.product2.id;
                skuDto.isActive = ord.Product2.IsActive;
                skuDto.totalQuantity = 0;
                skuDto.totalOrders = 0;
                skuDto.quantity = ord.quantity;
                skuDto.average = 0;
                skudto.id = ord.id;
                skudto.unitPrice = ord.unitPrice;
                skuDto.pricebookentryid = ord.pricebookentryid;
                skuDto.effectiveDateFieldName = (orderDate+ord.order.id);
                skudto.effectiveDate =  ord.order?.EffectiveDate.format();  
                skuDto.stockRemaining = 0;
                skudto.stock = prodInventMap.get(ord.Product2.id)?.aforza__Stock_Quantity__c;
                skuDtoMap.put(ord.Product2.id, skuDto);

                quantityMap.put(ord.Product2.id, 0);
                quantityMap.put(ord.Product2.id, (quantityMap.get(ord.Product2.id) + ord.quantity));
                totalQuantityMap.put(ord.Product2.id, 1);

                if (ord.quantity != null && ord.quantity > 0) {
                    orderDtosToReturn.add(skuDto);
                }
            }
        } catch (Exception e) {
            System.debug('No related product in inventory');
            throw PopulateAuraHandledException.newMessageException('Check all products are related to inventory');
        }

        return orderDtosToReturn;
    }


    @TestVisible 
    private static Map < String, List < Decimal >> addInventoryQuantity(List < OrderItem > orders, Map < String, List < Decimal >> mapProductEntity) {

        for (OrderItem et: orders) {
            if (mapProductEntity.containsKey(et.Product2.id)) {
                mapProductEntity.get(et.Product2.id).add(et.quantity);
            } else {
                mapProductEntity.put(et.Product2.id, new List < Decimal > {
                    et.quantity
                });
            }
        }
        return mapProductEntity;
    }

    @TestVisible 
    private static Map < String, skuDto > getQuantityAndTotalOrders(Map < String, skuDto > skuDtoMap, Map < String, List < Decimal >> mapProductEntity) {
        for (String st: skuDtoMap.keyset()) {
            List < Decimal > thisList = mapProductEntity.get(st);
            Integer size = thisList.size();
            skuDtoMap.get(st).totalOrders = size;
            Decimal count = 0;
            for (Decimal i: thisList) {
                count = count + i;
            }
            skuDtoMap.get(st).totalQuantity = count;
        }
        return skuDtoMap;
    }

    @TestVisible 
    private static List < skuDto > calculateAverage(Map < String, skuDto > skuDtoMap, List < skuDto > orderDtosToReturn) {
        for (String st: skuDtoMap.keyset()) {
            skuDtoMap.get(st).Average = Integer.valueOf((skuDtoMap.get(st).totalQuantity / skuDtoMap.get(st).totalOrders).round(RoundingMode.UP));
            orderDtosToReturn.add(skuDtoMap.get(st));
        }
        return orderDtosToReturn;
    }

    @TestVisible 
    private static List < skuDto > calculateStockLeft(Map < String, skuDto > skuDtoMap, List < skuDto > orderDtosToReturn) {
        for (String st: skuDtoMap.keyset()) {
         if(skuDtoMap.get(st).stock != null){
            skuDtoMap.get(st).stockRemaining = Integer.valueOf((skuDtoMap.get(st).stock - skuDtoMap.get(st).Average));
            }
            else{
            skuDtoMap.get(st).stockRemaining = 0 - skuDtoMap.get(st).Average;
            }
            orderDtosToReturn.add(skuDtoMap.get(st));
        }
        system.debug(orderDtosToReturn);
        return orderDtosToReturn;
    }

    @AuraEnabled(cacheable = true)
    public static List < OrderDto > getOrdersDates(String accountId) {
        List < String > orderNumbers = new List < String > ();
        List < OrderDto > orderDtoList = new List < OrderDto > ();
        List < Order > orderList = [
            SELECT Id, EffectiveDate, Clone__c, Status, AccountId, Description, (SELECT OrderId FROM OrderItems)
            FROM Order
            WHERE Id IN(SELECT OrderId FROM OrderItem)
             AND  RecordType.DeveloperName IN :OrderService.RECORD_TYPES_TO_UPDATE_ACCOUNT_ON_ORDER_COMPLETION 
            AND Status IN: OrderService.COMPLETED_ORDER_STATUSES And Clone__c != TRUE
            AND
            AccountId =: accountId
            ORDER BY EffectiveDate DESC Limit 6
        ];
        system.debug('orderList ' + orderList);
        for (Order ord: orderList) {
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
    public static List < OrderItem > getLastOrderLists(String accountId) {
        try{
        List < String > orderNumbers = new List < String > ();
        List < OrderItem > orderItemsList = new List < OrderItem > ();
        List < Order > orderList = [
            SELECT
            EffectiveDate, Status, Description, id, (SELECT OrderId FROM OrderItems)
            FROM Order
            WHERE Id IN(SELECT OrderId FROM OrderItem) AND AccountId =: accountId
             AND  RecordType.DeveloperName IN :OrderService.RECORD_TYPES_TO_UPDATE_ACCOUNT_ON_ORDER_COMPLETION 
            AND Status IN: OrderService.COMPLETED_ORDER_STATUSES AND Clone__c != TRUE
            ORDER BY EffectiveDate DESC Limit 6
        ];
        system.debug(orderList);
        for (Order orl: orderList) {
            orderNumbers.add(orl.id);
        }
        orderItemsList = getAllOrderItems(orderNumbers);
        return orderItemsList;
    } catch (Exception e) {
        throw PopulateAuraHandledException.newMessageException('Check all necessary order detail are associated to Account');

    }
        }

    @TestVisible 
    private static List < OrderItem > getAllOrderItems(List < String > orderIds) {
        List < OrderItem > orderItems = [
            SELECT product2.ProductCode, quantity, product2.id, pricebookEntryId,
            product2.description, product2.name, order.id, order.effectivedate, UnitPrice, product2.IsDRSProduct__c,
            product2.isactive FROM orderitem WHERE order.id IN: orderIds AND id != null AND product2.IsDRSProduct__c = FALSE
        ];
        return orderItems;
       }

    @AuraEnabled
    public static String CreateOrder(List < Map < String, String >> orderJSON, String accountId) {
    try{
        List < SkuDto > OrderToSkuList = new List < SkuDto > ();

        for (Map < String, String > mapJ: orderJson) {
            skuDto newSku = MapJson(mapJ);
            OrderToSkuList.add(newSku);
        }
        String orderId = CreateOrderDetails(accountId);

        InsertOrder(OrderToSkuList, orderId);
        return orderId;
    } catch (Exception e) {
        throw PopulateAuraHandledException.newMessageException('Check Pricebook entry matches products');

    }
    }

    @TestVisible 
    private static skuDto MapJson(Map < String, String > orderJSON) {

        SkuDto sku = new skuDto();
        sku.productId = orderJSON.get('productId');
        sku.quantity = Decimal.valueof(orderJSON.get('Average'));
        sku.pricebookentryid = orderJSON.get('pricebookentryid');
        sku.unitPrice = Decimal.valueof(orderJSON.get('unitPrice'));
        return sku;
    }

    @TestVisible 
    private static String InsertOrder(List < skuDto > skuList, Id ordId) {

        list < OrderItem > orderItems = new list < OrderItem > ();

        OrderItem newI;
        for (SkuDto sku: skuList) {
            newI = new OrderItem(
                OrderId = ordId,
                Product2Id = sku?.productId,
                Quantity = sku?.quantity,
                PricebookEntryId = sku?.pricebookentryid,
                unitPrice = sku?.unitPrice,
                aforza__Type__c = 'Product');

            orderItems.add(newI);
        }

        insert orderitems;
        return OrdId;
    }
    
    @TestVisible 
    private static String CreateOrderDetails(String accountId) {

        try {
        Account dPData = [SELECT aforza__Default_Price_Book__c, BillingPostalCode, BillingCity,
            BillingState, BillingStateCode, BillingStreet, Depot__c, NextDeliveryDate__c,
            ShippingAddress, ShippingCity, ShippingCountry, ShippingCountryCode, ShippingStateCode,
            ShippingStreet, Name, SalesRepresentativeCode__c, SalesRepresentative__c,
            DefaultInventory__c,
            DeliveryPointReference__c, ShippingPostalCode FROM Account where id =: accountId
        ];

        
        Order newOrder = new Order();
        newOrder.put('Name', 'Suggested Order: ' + String.valueof(Date.today()));
        newOrder.status = 'Draft';
        newOrder.type = 'Product Order';
        newOrder.RecordTypeId = RecordTypes.ORDER_TELESALES_ID;
        newOrder.accountId = accountId;
        newOrder.EffectiveDate = Date.today();
        newOrder.DeliveryDate__c = dPData?.NextDeliveryDate__c;
        newOrder.Depot__c = dPData?.Depot__c;
        newOrder.SalesRepresentative__c = dpData?.SalesRepresentative__c;
        newOrder.SalesRepresentativeCode__c = dpData?.SalesRepresentativeCode__c;
        newOrder.ownerId = UserInfo.getUserId();
        newOrder.DefaultPriceBook__c = dPData.aforza__Default_Price_Book__c;
        newOrder.aforza__Inventory__c = dpData?.DefaultInventory__c;
        newOrder.DPName__c = dPData.Name;
        newOrder.DPReference__c = dpData?.DeliveryPointReference__c;
        newOrder.BillingCity = dpData?.BillingCity;
        newOrder.BillingPostalCode = dpData?.BillingPostalCode;
        newOrder.BillingState = dpData?.BillingState;
        newOrder.BillingStreet = dpData?.BillingStreet;
        newOrder.ShippingCity = dpData?.ShippingCity;
        newOrder.ShippingCountry = dpData?.ShippingCountry;
        newOrder.ShippingPostalCode = dpData?.ShippingPostalCode;
        newOrder.ShippingStreet = dpData?.ShippingStreet;
        newOrder.Pricebook2Id = dpData.aforza__Default_Price_Book__c;
        
            Id OrderId;
            Database.SaveResult sr = Database.insert(newOrder);

            OrderId = sr.getId();

            return OrderId;
        } catch (Exception e) {
            throw PopulateAuraHandledException.newMessageException('Check all necessary order detail are associated to Account');

        }
    }
}
