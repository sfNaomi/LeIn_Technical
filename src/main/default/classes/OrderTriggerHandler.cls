/**
 * Created by magdalena.stanciu on 13.09.2022.
 */

public with sharing class OrderTriggerHandler {

    private static final Map<String, String> STATUS_TO_FIELD_MAPPING {
        get {
            if (STATUS_TO_FIELD_MAPPING == null) {
                STATUS_TO_FIELD_MAPPING = getOrderStatusesToLoadFieldMapping();
            }
            return STATUS_TO_FIELD_MAPPING;
        }
        set;
    }
    public static void updateLastOrderDateAndStatusOnParentAccount(List<Order> newOrders, Map<Id, Order> oldOrders) {
        List<Order> ordersToUpdateAccountLastOrder = new List<Order>();
        for (Order newOrder : newOrders) {
            Order oldOrder = oldOrders?.get(newOrder.Id);
            if (OrderService.orderTypeCountsTowardsAccountLastOrderDate(newOrder.RecordTypeId) &&
                    ((oldOrder == null && OrderService.isOrderCompleted(newOrder.Status)) ||
                            (oldOrder != null && newOrder.Status != oldOrder.Status && !OrderService.isOrderCompleted(oldOrder.Status) && OrderService.isOrderCompleted(newOrder.Status)) ||
                            (oldOrder != null && newOrder.Status != oldOrder.Status && OrderService.isOrderCompleted(oldOrder.Status) && !OrderService.isOrderCompleted(newOrder.Status)) ||
                            (oldOrder != null && newOrder.EffectiveDate != oldOrder.EffectiveDate && OrderService.isOrderCompleted(newOrder.Status))
                    )) {
                ordersToUpdateAccountLastOrder.add(newOrder);
            }
        }
        OrderService.updateLastOrderDateAndStatusOnParentAccount(ordersToUpdateAccountLastOrder);
    }

    public static void validateOrderCreationOrCompletion(List<Order> newOrders, Map<Id, Order> oldOrders) {
        Set<Id> relatedAccountIds = new Set<Id>();
        for (Order newOrder : newOrders) {
            relatedAccountIds.add(newOrder.AccountId);
        }

        Map<Id, Account> relatedAccounts = new Map<Id, Account>([
                SELECT Id, AccountStatus__c, CreditStatus__c, AvailableCredit__c, (
                        SELECT Id, AccountId, TeamMemberRole, UserId
                        FROM AccountTeamMembers
                        WHERE TeamMemberRole = 'TAM'
                )
                FROM Account
                WHERE Id IN :relatedAccountIds
        ]);

        for (Order newOrder : newOrders) {
            Order oldOrder = oldOrders?.get(newOrder.Id);
            Account relatedAccount = relatedAccounts.get(newOrder.AccountId);
            if (!AccountService.STATUSES_WHERE_ORDER_CREATION_ALLOWED.contains(relatedAccount.AccountStatus__c) &&
                    ((oldOrder == null) || (oldOrder != null && newOrder.Status != oldOrder.Status &&
                            !OrderService.isOrderCompleted(oldOrder.Status) && OrderService.isOrderCompleted(newOrder.Status)))) {
                newOrder.addError(Label.OrderCreationActivationIsNotAllowedForCurrentAccountStatus);
            }

            if (oldOrder != null && newOrder.Status != oldOrder.Status &&
                    !OrderService.isOrderCompleted(oldOrder.Status) && OrderService.isOrderCompleted(newOrder.Status) && (
                    relatedAccount.CreditStatus__c == AccountService.STATUSES_WHERE_ORDER_ACTIVATION_IS_NOT_ALLOWED || relatedAccount.AvailableCredit__c < 0) && (
                    newOrder.RecordTypeId == RecordTypes.ORDER_TELESALES_ID || newOrder.RecordTypeId == RecordTypes.ORDER_ECOMMERCE_ID ||
                            newOrder.RecordTypeId == RecordTypes.ORDER_EDI_ID ||
                            newOrder.RecordTypeId == RecordTypes.ORDER_FIELD_DIRECT_ID)) {
                if (relatedAccount.CreditStatus__c == AccountService.STATUSES_WHERE_ORDER_ACTIVATION_IS_NOT_ALLOWED &&
                        newOrder.RecordTypeId != RecordTypes.ORDER_FIELD_DIRECT_ID) {
                    newOrder.addError(Label.OrderActivationPreventedDueToDPOnHold);
                }

                if (relatedAccount.AvailableCredit__c < 0) {
                    newOrder.addError(Label.OrderActivationPreventedDueToDPNegativeCredit);
                }

                OrderTriggerHandler.sendNotificationToTAM(newOrder.OrderNumber, newOrder.AccountName__c, newOrder.Id, relatedAccount.AccountTeamMembers);
            }
        }
    }

    private static void sendNotificationToTAM(String orderNumber, String orderAccountName, String orderId, List<AccountTeamMember> tamUsersIds) {
        String notificationName = 'NotificationToTAM';
        String notificationTitle = 'Order in need of Approval';
        Set<String> usersToBeNotified = new Set<String>();

        for (AccountTeamMember atm : tamUsersIds) {
            usersToBeNotified.add(atm.UserId);
        }

        CustomNotificationType notificationType = [
                SELECT Id, DeveloperName
                FROM CustomNotificationType
                WHERE DeveloperName = :notificationName
        ];

        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(notificationTitle);
        notification.setBody('Order number: ' + orderNumber + ' from account ' + orderAccountName + ' needs to be submitted for approval.');
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(orderId);

        try {
            notification.send(usersToBeNotified);
        } catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }
    }

    public static void createInvoice(List<Order> newOrders, Map<Id, Order> oldOrders) {
        Set<Id> orderIdsToCreateInvoiceFrom = new Set<Id>();
        for (Order newOrder : newOrders) {
            Order oldOrder = oldOrders?.get(newOrder.Id);
            if (OrderService.orderTypeRequiresInvoiceCreation(newOrder.RecordTypeId) &&
                    oldOrder != null && newOrder.Status != oldOrder.Status &&
                    newOrder.Status == OrderService.SETTINGS.StatusToCreateInvoice__c
            ) {
                orderIdsToCreateInvoiceFrom.add(newOrder.Id);
            }
        }
        if (!orderIdsToCreateInvoiceFrom.isEmpty()) {
            InvoiceService.createInvoicesFromOrders(orderIdsToCreateInvoiceFrom);
        }
    }

    public static void cloneCompletedOrder(List<Order> newOrders, Map<Id, Order> oldOrders) {
        List<Order> toBeClonedOrders = new List<Order>();
        for (Order order : newOrders) {
            if (order.Status == 'Activated' &&
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

        List<OrderItem> clonedOrderItems = new List<OrderItem>();
        for (OrderItem orderItem : orderItemsFromAllOriginalOrders) {
            OrderItem tempOrderItem = orderItem.clone(false, true, false, false);
            tempOrderItem.OrderId = originalOrderIdsToClonedOrderIds.get(orderItem.OrderId);
            clonedOrderItems.add(tempOrderItem);
        }

        insert clonedOrderItems;
    }


    public static void populateLoadWhenAllLInkedOrdersShareStatus(List<Order> orders, Map<Id, Order> oldOrdersMap) {
        Set<Id> loadIds = new Set<Id>();
        Map<Id, Set<String>> loadsWithOrderStatusesMap = new Map<Id, Set<String>>();
        List<Order> ordersToCheck = new List<Order>();

        for (Order order : orders) {
            Order oldOrder = oldOrdersMap.get(order.Id);
            if (oldOrder.Status <> order.Status && STATUS_TO_FIELD_MAPPING.containsKey(order.Status) && order.Load__c <> null) {
                loadIds.add(order.Load__c);
                ordersToCheck.add(order);
            }
        }

        // merge together new changes and existing data from DB
        prepareLoadToOrdersMap(loadsWithOrderStatusesMap, ordersToCheck);
        prepareLoadToOrdersMap(loadsWithOrderStatusesMap, [SELECT Id, Status, Load__c FROM Order WHERE Load__c IN :loadIds]);

        processOrdersToPopulateLoadField(loadsWithOrderStatusesMap);
    }

    private static Map<String, String> getOrderStatusesToLoadFieldMapping() {
        Map<String, String> statusToFieldMap = new Map<String, String>();
        for (OrderStatusToLoadFieldMapping__mdt mapping : OrderStatusToLoadFieldMapping__mdt.getAll().values()) {
            statusToFieldMap.put(mapping.OrderStatus__c, mapping.LoadFieldToModify__c);
        }
        return statusToFieldMap;
    }

    private static void prepareLoadToOrdersMap(Map<Id, Set<String>> loadsWithOrderStatusesMap, List<Order> orders) {
        for (Order order : orders) {
            if (loadsWithOrderStatusesMap.containsKey(order.Load__c)) {
                loadsWithOrderStatusesMap.get(order.Load__c).add(order.Status);
            } else {
                loadsWithOrderStatusesMap.put(order.Load__c, new Set<String>{order.Status});
            }
        }
    }

    private static void processOrdersToPopulateLoadField(Map<Id, Set<String>> loadsWithOrderStatusesMap) {
        List<Load__c> loadsToUpdate = new List<Load__c>();
        //iterate over each value from settings
        for (String statusValue : STATUS_TO_FIELD_MAPPING.keySet()) {
            // for each load
            for (Id loadId : loadsWithOrderStatusesMap.keySet()) {
                Set<String> orderStatuses = loadsWithOrderStatusesMap.get(loadId);
                // we are allowed to update value on load only when all order statuses have same value
                if (orderStatuses.contains(statusValue) && orderStatuses.size() == 1) {
                    Load__c loadToUpdate = new Load__c();
                    loadToUpdate.Id = loadId;
                    loadToUpdate.put(STATUS_TO_FIELD_MAPPING.get(statusValue), true);

                    loadsToUpdate.add(loadToUpdate);
                }
            }
        }
        update loadsToUpdate;
    }
}

