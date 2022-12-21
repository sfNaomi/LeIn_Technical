/**
 * Created by magdalena.stanciu on 23.11.2022.
 */

public with sharing class OrderItemTriggerHandler {
    @TestVisible private static String ORDER_ITEM_TYPE_PRODUCT = 'Product';
    @TestVisible private static String ORDER_ITEM_TYPE_TAX = 'Tax';

    /**
     * @description identifies order items which require recalculation of vat (tax field on order item) and fires the recalculation
     *
     * @param newOrderItems list containing new versions of the inserted/updated order items
     * @param oldOrderItems map containing old versions of the updated order items
     *
     * @author Magdalena Stanciu
     * @date 2022-11-23
     */
    public static void calculateVatOnOrderItemLevel(List<OrderItem> newOrderItems, Map<Id, OrderItem> oldOrderItems) {
        for (OrderItem newOrderItem : newOrderItems) {
            OrderItem oldOrderItem = oldOrderItems?.get(newOrderItem.Id);
            if (newOrderItem.aforza__Type__c == ORDER_ITEM_TYPE_PRODUCT && (oldOrderItem == null || (oldOrderItem != null &&
                (newOrderItem.Quantity != oldOrderItem.Quantity || newOrderItem.UnitPrice != oldOrderItem.UnitPrice)))) {
                calculateVat(newOrderItem);
            }
        }
    }

    /**
     * @description identifies orders which require recalculation of vat (tax order item) and fires the recalculation
     *
     * @param newOrderItems map containing new versions of the inserted/updated order items
     * @param oldOrderItems map containing old versions of the updated order items
     *
     * @author Magdalena Stanciu
     * @date 2022-11-23
     */
    public static void calculateVatOnOrderLevel(Map<Id, OrderItem> newOrderItems, Map<Id, OrderItem> oldOrderItems) {
        Set<Id> allOrderItemIds = getAllOrderItems(newOrderItems?.keySet(), oldOrderItems?.keySet());

        Set<Id> allOrderIdsToUpdateTaxFor = new Set<Id>();
        for(Id orderItemId : allOrderItemIds) {
            OrderItem newOrderItem = newOrderItems?.get(orderItemId);
            OrderItem oldOrderItem = oldOrderItems?.get(orderItemId);
            if ((newOrderItem == null && oldOrderItem != null && oldOrderItem.aforza__Type__c == ORDER_ITEM_TYPE_PRODUCT) ||
                (newOrderItem != null && oldOrderItem == null && newOrderItem.aforza__Type__c == ORDER_ITEM_TYPE_PRODUCT) ||
                (
                    newOrderItem != null & oldOrderItem != null &&
                    newOrderItem.aforza__Type__c == ORDER_ITEM_TYPE_PRODUCT &&
                    newOrderItem.aforza__Tax__c != oldOrderItem.aforza__Tax__c
                )) {

                Id orderId = newOrderItem != null ? newOrderItem.OrderId : oldOrderItem.OrderId;
                allOrderIdsToUpdateTaxFor.add(orderId);

            }
        }
		
        Map<Id, Order> notClonedOrdersById = getNotClonedOrders(allOrderIdsToUpdateTaxFor);
        Map<Id, Order> productOrderItemsByOrderId = getOrdersWithRelatedProductLineItems(notClonedOrdersById.keySet());
        Map<Id, Order> taxOrderItemsByOrderId = getOrdersWithRelatedTaxOrderItem(notClonedOrdersById.keySet());

        List<OrderItem> taxOrderItemsToUpdate = new List<OrderItem>();
        for (Id orderId : notClonedOrdersById.keySet()) {
            List<OrderItem> productOrderItems = productOrderItemsByOrderId?.get(orderId)?.OrderItems;
            List<OrderItem> taxOrderItems = taxOrderItemsByOrderId?.get(orderId)?.OrderItems;
            if (!taxOrderItems.isEmpty()) {
                taxOrderItems[0].UnitPrice = calculateTotalVat(productOrderItems);
                taxOrderItemsToUpdate.add(taxOrderItems[0]);
            }
        }

        update taxOrderItemsToUpdate;
    }

    /**
      * @description creates a set will all order item ids
      *
      * @param newOrderItemIds ids of order items
      * @param oldOrderItemIds ids of order items
      *
      * @return set of IDs
      *
      * @author Magdalena Stanciu
      * @date 2022-11-23
      */
    @TestVisible
    private static Set<Id> getAllOrderItems(Set<Id> newOrderItemIds, Set<Id> oldOrderItemIds) {
        Set<Id> allOrderItemIds = new Set<Id>();
        if (newOrderItemIds != null) allOrderItemIds.addAll(newOrderItemIds);
        if (oldOrderItemIds != null) allOrderItemIds.addAll(oldOrderItemIds);
        return allOrderItemIds;
    }

    /**
      * @description calculates vat for an order item
      *
      * @param newOrderItem order item to calculate vat for
      *
      * @author Magdalena Stanciu
      * @date 2022-11-23
      */
    @TestVisible
    private static void calculateVat(OrderItem newOrderItem) {
        if (newOrderItem.UnitPrice != null && newOrderItem.aforza__Tax_Percent__c != null && newOrderItem.Quantity != null) {
            Decimal calculatedVat;
            calculatedVat = newOrderItem.Quantity * newOrderItem.UnitPrice * newOrderItem.aforza__Tax_Percent__c / 100;
            newOrderItem.aforza__Tax__c = calculatedVat.setScale(2, RoundingMode.HALF_UP);
        } else {
            newOrderItem.aforza__Tax__c = null;
        }
    }

    /**
      * @description calculates total vat for an order
      *
      * @param orderItems list of order items based on which the total vat is calculated
      *
      * @return total vat on order level
      *
      * @author Magdalena Stanciu
      * @date 2022-11-23
      */
    @TestVisible
    private static Decimal calculateTotalVat(List<OrderItem> orderItems) {
        Decimal totalVat = 0;
        for (OrderItem newOrderItem : orderItems) {
            totalVat += newOrderItem.aforza__Tax__c == null ? 0 : newOrderItem.aforza__Tax__c;
        }
        return totalVat;
    }

    /**
      * @description retrieves orders and related product order line items
      *
      * @param orderIds ids of orders to be retrieved
      *
      * @return map of retrieved orders
      *
      * @author Magdalena Stanciu
      * @date 2022-11-23
      */
    @TestVisible
    private static Map<Id, Order> getOrdersWithRelatedProductLineItems(Set<Id> orderIds) {
        Map<Id, Order> orders = new Map<Id, Order>([
            SELECT Id, (
                SELECT Id, aforza__Tax__c
                FROM OrderItems
                WHERE aforza__Type__c = :ORDER_ITEM_TYPE_PRODUCT
            )
            FROM Order
            WHERE Id IN :orderIds
        ]);
        return orders;
    }

    /**
      * @description retrieves orders and related tax order line item
      *
      * @param orderIds ids of orders to be retrieved
      *
      * @return map of retrieved orders
      *
      * @author Magdalena Stanciu
      * @date 2022-11-23
      */
    @TestVisible
    private static Map<Id, Order> getOrdersWithRelatedTaxOrderItem(Set<Id> orderIds) {
        Map<Id, Order> orders = new Map<Id, Order>([
            SELECT Id, (
                SELECT Id, UnitPrice
                FROM OrderItems
                WHERE aforza__Type__c = :ORDER_ITEM_TYPE_TAX AND Quantity = 1
                LIMIT 1
            )
            FROM Order
            WHERE Id IN :orderIds
        ]);
        return orders;
    }
    
    @TestVisible
    private static Map<Id, Order> getNotClonedOrders(Set<Id> orderIds) {
        Map<Id, Order> notClonedOrdersById = new Map<Id, Order>([
            SELECT Id, Clone__c 
            FROM Order 
            WHERE Id IN :orderIds 
            AND Clone__c = FALSE]);
        return notClonedOrdersById;
    }
}