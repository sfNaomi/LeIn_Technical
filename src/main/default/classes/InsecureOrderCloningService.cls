public without sharing class InsecureOrderCloningService {
	
    public static void deepCloneOrders(List<Order> toBeClonedOrders) {
        List<Order> clonedOrders = new List<Order>();
        for (Order newOrder : toBeClonedOrders) {
            Order tempClonedOrder = newOrder.clone(false, true, false, false);
            tempClonedOrder.Status = 'Draft';
            tempClonedOrder.Clone__c = true;
            tempClonedOrder.aforza__Original_Order__c = newOrder.Id;
            clonedOrders.add(tempClonedOrder);
        }
        insert clonedOrders;
        cloneOrderItemsFromOriginalOrder(clonedOrders);
    }

    public static void cloneOrderItemsFromOriginalOrder(List<Order> succesfullyClonedOrders) {
        Map<Id, Id> originalOrderIdsToClonedOrderIds = new Map<Id, Id>();
        for (Order order : succesfullyClonedOrders) {
            originalOrderIdsToClonedOrderIds.put(order.aforza__Original_Order__c, order.Id);
        }

        List<OrderItem> orderItemsFromAllOriginalOrders = [
                SELECT
                        Id, 
            			UnitPrice,
                        Quantity,
                        OrderId,
                        PricebookEntryId,
                        aforza__Automatic_Discount_Rule__c,
                        aforza__Automatic_Discount_Rule_2__c,
                        aforza__Automatic_Discount_Rule_3__c,
                        aforza__Automatic_Discount_Rule_4__c,
                        aforza__Automatic_Discount_Rule_5__c,
                        aforza__Automatic_Discount_Rule_6__c,
                        aforza__Automatic_Discount_Rule_7__c,
                        aforza__Automatic_Discount_Rule_8__c,
                        aforza__Automatic_Discount_Rule_9__c,
                        aforza__Automatic_Discount_Rule_10__c,
                        AvailableQuantity,
                        aforza__Bundle_Discount_Rule__c,
                        aforza__Bundle_Product__c,
                        aforza__Commission__c,
            			aforza__Commission_Percent__c,
                        aforza__Conditional_Product_Type__c,
                        aforza__Discount_Absolute__c,
                        aforza__Discount_Percent__c,
                        aforza__Discount_Set__c,
                        EndDate,
                        aforza__Granted_Item__c,
                        Description,
                        ListPrice,
                        aforza__Local_Id__c,
                        aforza__Manual_Discount_Rule__c,
                        aforza__Order_Discount_Rule__c,
                        OriginalOrderItemId,
                        Product2Id,
                        ProductWeight__c,
                        aforza__Promotion__c,
                        aforza__Promotion_Product__c,
                        aforza__Promotion_Product_Group__c,
                        aforza__Scheduled_For_Deletion__c,
                        ServiceDate,
                        aforza__Tax__c,
                        TotalPrice,
                        aforza__Type__c,
                        aforza__Volume_Discount_Rule__c
                FROM OrderItem
                WHERE OrderId IN :originalOrderIdsToClonedOrderIds.keySet()
        ];

        List<OrderItem> clonedOrderItems = new List<OrderItem>();
        for (OrderItem orderItem : orderItemsFromAllOriginalOrders) {
            OrderItem tempOrderItem = orderItem.clone(false, true, false, false);
            tempOrderItem.OrderId = originalOrderIdsToClonedOrderIds.get(orderItem.OrderId);
            clonedOrderItems.add(tempOrderItem);
        }

        insert clonedOrderItems;
    }
}