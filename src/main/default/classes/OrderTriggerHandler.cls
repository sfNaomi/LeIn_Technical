/**
 * Created by magdalena.stanciu on 13.09.2022.
 */

public with sharing class OrderTriggerHandler {
    public static void updateLastOrderDateAndStatusOnParentAccount(List<Order> newOrders, Map<Id, Order> oldOrders) {
        List<Order> ordersToUpdateAccountLastOrder = new List<Order>();
        for (Order newOrder : newOrders) {
            Order oldOrder = oldOrders?.get(newOrder.Id);
            if (
                OrderService.orderTypeCountsTowardsAccountLastOrderDate(newOrder.RecordTypeId) &&
                    (
                        (oldOrder == null && OrderService.isOrderCompleted(newOrder.Status)) ||
                        (oldOrder != null && newOrder.Status != oldOrder.Status && !OrderService.isOrderCompleted(oldOrder.Status) && OrderService.isOrderCompleted(newOrder.Status)) ||
                        (oldOrder != null && newOrder.Status != oldOrder.Status && OrderService.isOrderCompleted(oldOrder.Status) && !OrderService.isOrderCompleted(newOrder.Status)) ||
                        (oldOrder != null && newOrder.EffectiveDate != oldOrder.EffectiveDate && OrderService.isOrderCompleted(newOrder.Status))
                    )
            ) {
                ordersToUpdateAccountLastOrder.add(newOrder);
            }
        }
        OrderService.updateLastOrderDateAndStatusOnParentAccount(ordersToUpdateAccountLastOrder);
    }

    public static void validateOrderCreation(List<Order> newOrders, Map<Id, Order> oldOrders) {
        Set<Id> relatedAccountIds = new Set<Id>();
        for (Order newOrder : newOrders) {
            relatedAccountIds.add(newOrder.AccountId);
        }

        Map<Id, Account> relatedAccounts = new Map<Id, Account>([
                SELECT Id, AccountStatus__c
                FROM Account
                WHERE Id IN :relatedAccountIds
        ]);

        for (Order newOrder : newOrders) {
            Order oldOrder = oldOrders?.get(newOrder.Id);
            Account relatedAccount = relatedAccounts.get(newOrder.AccountId);
            if (!AccountService.STATUSES_WHERE_ORDER_CREATION_ALLOWED.contains(relatedAccount.AccountStatus__c) &&
                (
                    (oldOrder == null) ||
                    (oldOrder != null && newOrder.Status != oldOrder.Status && !OrderService.isOrderCompleted(oldOrder.Status) && OrderService.isOrderCompleted(newOrder.Status))
                )
            ) {
                newOrder.addError(Label.OrderCreationActivationIsNotAllowedForCurrentAccountStatus);
            }
        }
    }

    public static void createInvoice(List<Order> newOrders, Map<Id, Order> oldOrders) {
        Set<Id> orderIdsToCreateInvoiceFor = new Set<Id>();
        for (Order newOrder : newOrders) {
            Order oldOrder = oldOrders?.get(newOrder.Id);
            if (
                    OrderService.orderTypeRequiresInvoiceCreation(newOrder.RecordTypeId) &&
                    oldOrder != null && newOrder.Status != oldOrder.Status &&
                    newOrder.Status == OrderService.SETTINGS.StatusToCreateInvoice__c
            ) {
                orderIdsToCreateInvoiceFor.add(newOrder.Id);
            }
        }
        InvoiceService.createInvoicesForOrders(orderIdsToCreateInvoiceFor);
    }

    public static void cloneCompletedOrder(List<Order> newOrders, Map<Id, Order> oldOrders) {
        List<Order> toBeClonedOrders = new List<Order>();
        for (Order order : newOrders) {
            if (
                order.Status == 'Activated' &&
                oldOrders.get(order.Id).Status != order.Status &&
                (order.RecordTypeId == RecordTypes.ORDER_FIELD_DIRECT_ID ||
                order.RecordTypeId == RecordTypes.ORDER_TELESALES_ID ||
                order.RecordTypeId == RecordTypes.ORDER_ECOMMERCE_ID ||
                order.RecordTypeId == RecordTypes.ORDER_EDI_ID)
            ) {
                cloneOrderAndMapSpecificFields(order, toBeClonedOrders);
            }
        }
        insert toBeClonedOrders;
        cloneOrderItemsFromOriginalOrder(toBeClonedOrders);
    }

    private static void cloneOrderAndMapSpecificFields(Order order, List<Order> toBeClonedOrders) {
        Order tempClonedOrder = order.clone(false, true, false, false);
        tempClonedOrder.Status = 'Draft';
        tempClonedOrder.Clone__c = true;
        tempClonedOrder.aforza__Original_Order__c = order.Id;
        toBeClonedOrders.add(tempClonedOrder);
    }

    public static void cloneOrderItemsFromOriginalOrder(List<Order> succesfullyClonedOrders) {
        Map<Id, Id> originalOrderIdsToClonedOrderIds = new Map<Id, Id>();
        List<OrderItem> clonedOrderItems = new List<OrderItem>();
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
        for (OrderItem orderItem : orderItemsFromAllOriginalOrders) {
            OrderItem tempOrderItem = orderItem.clone(false, true, false, false);
            tempOrderItem.OrderId = originalOrderIdsToClonedOrderIds.get(orderItem.OrderId);
            clonedOrderItems.add(tempOrderItem);
        }
        insert clonedOrderItems;
    }
}