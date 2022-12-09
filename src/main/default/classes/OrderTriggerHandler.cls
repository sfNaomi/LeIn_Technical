/**
 * Created by magdalena.stanciu on 13.09.2022.
 */

public with sharing class OrderTriggerHandler {

    @TestVisible private static final String ORDER_STATUS_AFTER_CLONING = 'Unplanned';

    private static final Map<String, String> STATUS_TO_FIELD_MAPPING {
        get {
            if (STATUS_TO_FIELD_MAPPING == null) {
                STATUS_TO_FIELD_MAPPING = getOrderStatusesToLoadFieldMapping();
            }
            return STATUS_TO_FIELD_MAPPING;
        }
        set;
    }

    private static final OrderSetting__mdt ORDER_SETTINGS {
        get {
            if (ORDER_SETTINGS == null) {
                ORDER_SETTINGS = OrderSetting__mdt.getInstance('OrgDefaultOrderSettings');
            }
            return ORDER_SETTINGS;
        }
        set;
    }

    private static final String CANCELLED_STATUS = 'Cancelled';

    public static void cloneCompletedOrder(List<Order> newOrders, Map<Id, Order> oldOrders) {
        List<Order> toBeClonedOrders = new List<Order>();
        for (Order order : newOrders) {
            if (order.Status == 'Activated' &&
                oldOrders.get(order.Id).Status != order.Status &&
                (order.RecordTypeId == RecordTypes.ORDER_FIELD_DIRECT_ID ||
                    order.RecordTypeId == RecordTypes.ORDER_TELESALES_ID ||
                    order.RecordTypeId == RecordTypes.ORDER_ECOMMERCE_ID ||
                    order.RecordTypeId == RecordTypes.ORDER_EDI_ID ||
                    order.RecordTypeId == RecordTypes.ORDER_RETURN_ID
                )
            ) {
                toBeClonedOrders.add(order);
            }
        }
        InsecureOrderCloningService.deepCloneOrders(toBeClonedOrders);
        OrderService.updateOrderStatus(toBeClonedOrders, ORDER_STATUS_AFTER_CLONING);
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
        Set<Id> newOrderIds = new Set<Id>();
        for (Order newOrder : newOrders) {
            relatedAccountIds.add(newOrder.AccountId);
            newOrderIds.add(newOrder.Id);
        }

        Map<Id, Account> relatedAccounts = new Map<Id, Account>([
            SELECT Id, AccountStatus__c, CreditStatus__c, AvailableCredit__c, Parent.AvailableCustomerCredit__c, (
                SELECT Id, AccountId, TeamMemberRole, UserId
                FROM AccountTeamMembers
                WHERE TeamMemberRole = 'TAM'
            )
            FROM Account
            WHERE Id IN :relatedAccountIds
        ]);

        for (Order newOrder : newOrders) {
            Order oldOrder = oldOrders?.get(newOrder.Id);
            Account relatedAccount = relatedAccounts?.get(newOrder.AccountId);

            // Account based check for order creation or update (stops anything that is for on hold customer)
            if (!AccountService.STATUSES_WHERE_ORDER_CREATION_ALLOWED.contains(relatedAccount.AccountStatus__c) &&
                ((oldOrder == null) || (oldOrder != null && newOrder.Status != oldOrder.Status &&
                    !OrderService.isOrderCompleted(oldOrder.Status) && OrderService.isOrderCompleted(newOrder.Status)))) {
                newOrder.addError(Label.OrderCreationActivationIsNotAllowedForCurrentAccountStatus);
            }

            // check for order status change, we check that the status is changed and also changed from not completed to
            // completed status
            if (!(oldOrder != null && newOrder.Status != oldOrder.Status &&
                !OrderService.isOrderCompleted(oldOrder.Status) && OrderService.isOrderCompleted(newOrder.Status))) {
                continue;
            }
            // check if there are any full discount items
            if (newOrder.IsApproved__c == false && newOrder.TotalNumberOfFullyDiscountedItems__c > 0) {
                newOrder.addError(Label.OrderActivationPreventedItemFullDiscount);
                // check for specific order types and some extra statuses
            } else if ((relatedAccount.CreditStatus__c == AccountService.STATUSES_WHERE_ORDER_ACTIVATION_IS_NOT_ALLOWED ||
                relatedAccount.AvailableCredit__c < newOrder.TotalAmount) && (newOrder.RecordTypeId == RecordTypes.ORDER_TELESALES_ID ||
                newOrder.RecordTypeId == RecordTypes.ORDER_ECOMMERCE_ID ||
                newOrder.RecordTypeId == RecordTypes.ORDER_EDI_ID ||
                newOrder.RecordTypeId == RecordTypes.ORDER_FIELD_DIRECT_ID)) {
                if (relatedAccount.CreditStatus__c == AccountService.STATUSES_WHERE_ORDER_ACTIVATION_IS_NOT_ALLOWED
                    && newOrder.IsApproved__c == false && newOrder.PreAuthCaptured__c == false) {
                    newOrder.addError(Label.OrderActivationPreventedDueToAccountOnHold);
                } else if (relatedAccount.AvailableCredit__c < newOrder.TotalAmount &&
                    relatedAccount.Parent != null && relatedAccount.Parent.AvailableCustomerCredit__c < newOrder.TotalAmount &&
                    newOrder.IsApproved__c == false) {
                    newOrder.addError(Label.OrderActivationPreventedAccNotEnoughCredit);
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

    public static void createPaymentTransaction(List<Order> newOrders, Map<Id, Order> oldOrders) {
        Set<Id> orderIdsToCreatePaymentTransactionFrom = new Set<Id>();
        Set<String> allowedPrimaryPaymentMethods = new Set<String>{
            'Direct Debit', 'Bacs'
        };
        for (Order newOrder : newOrders) {
            Order oldOrder = oldOrders?.get(newOrder.Id);
            Boolean isStatusChanged = oldOrder != null && newOrder.Status != oldOrder.Status;
            if (newOrder.RecordTypeId <> RecordTypes.ORDER_ECOMMERCE_ID &&
                allowedPrimaryPaymentMethods.contains(newOrder.PaymentMethod__c) &&
                isStatusChanged &&
                newOrder.Status.equals('Activated')
            ) {
                orderIdsToCreatePaymentTransactionFrom.add(newOrder.Id);
            }
        }
        if (!orderIdsToCreatePaymentTransactionFrom.isEmpty()) {
            PaymentTransactionService.createPaymentTransactionFromOrders(orderIdsToCreatePaymentTransactionFrom);
        }
    }

    public static void populateDefaultInventory(List<Order> newOrders, Map<Id, Order> oldOrders) {
        Map<String, Id> inventoryIdMap = InventoryService.getDepotInventoryMapping();
        for (Order newOrder : newOrders) {
            Order oldOrder = oldOrders?.get(newOrder.Id);
            if (
                (oldOrder == null && newOrder.Depot__c != null) ||
                    (oldOrder != null && newOrder.Depot__c != oldOrder.Depot__c)
            ) {
                newOrder.aforza__Inventory__c = inventoryIdMap.get(newOrder.Depot__c);
            }
        }
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
                loadsWithOrderStatusesMap.put(order.Load__c, new Set<String>{
                    order.Status
                });
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

    public static void validateAndSendDeliveryNoteEmail(List<Order> newOrders, Map<Id, Order> oldOrders) {
        Map<String, Order> ordersWithDeliveryEmail = new Map<String, Order>(
            [SELECT Account.DeliveryNoteEmail__c FROM Order WHERE Id IN :newOrders]
        );
        Set<Id> orderIdsToSendDeliveryNoteEmail = new Set<Id>();
        for (Order newOrder : newOrders) {
            Order oldOrder = oldOrders?.get(newOrder.Id);
            if (
                newOrder.Status != oldOrder.Status &&
                    newOrder.Status.equals('Delivered') &&
                    ordersWithDeliveryEmail.containsKey(newOrder.Id) &&
                    String.isNotEmpty(ordersWithDeliveryEmail.get(newOrder.Id).Account.DeliveryNoteEmail__c)
            ) {
                orderIdsToSendDeliveryNoteEmail.add(newOrder.Id);
            }
        }
        if ((!System.isBatch() || !System.isFuture()) && orderIdsToSendDeliveryNoteEmail.size() > 0) {
            DeliveryNoteService.generateOrderAttachmentsAndSendDeliveryEmails(orderIdsToSendDeliveryNoteEmail);
        }
    }

    public static void removeOrdersFromLoad(Map<Id, Order> ordersMap, Map<Id, Order> oldOrdersMap) {
        Map<Id, Id> orderIdsToLoadIdsToRemoveFromRoute = new Map<Id, Id>();
        Map<Id, Id> accountIdToLoadIdMap = new Map<Id, Id>();
        for (Order order : ordersMap.values()) {
            Order oldOrder = oldOrdersMap.get(order.Id);
            if (ORDER_SETTINGS.TargetStatusRemoveFromRoute__c.contains(order.Status) &&
                order.Replanned__c == true && order.Load__c == null &&
                oldOrder.Load__c != null &&
                ORDER_SETTINGS.CurrentStatusRemoveFromRoute__c.contains(oldOrder.Status)) {
                orderIdsToLoadIdsToRemoveFromRoute.put(order.Id, oldOrder.Load__c);
                accountIdToLoadIdMap.put(order.AccountId, oldOrder.Load__c);
            }
        }

        if (orderIdsToLoadIdsToRemoveFromRoute.size() > 0) {
            removeOrdersFromRoute(orderIdsToLoadIdsToRemoveFromRoute, accountIdToLoadIdMap);
        }
    }

    public static void handleOrdersCancellation(List<Order> newOrders, Map<Id, Order> oldOrders) {
        List<String> orderIds = new List<String>();
        for (Order newOrder : newOrders) {
            Order oldOrder = oldOrders.get(newOrder.Id);
            Boolean isStatusChanged = oldOrder != null && newOrder.Status != oldOrder.Status;
            if (isStatusChanged && newOrder.Status == CANCELLED_STATUS && newOrder.PreAuthCaptured__c == true) {
                orderIds.add(newOrder.Id);
            }
        }
        if (!orderIds.isEmpty()) {
            // Update AGB Transaction Records
            setOrderTransactionsToCancelledStatus(orderIds);
            // Update BT Transaction Records
            setOrderBTTransactionsForRefund(orderIds);
        }
    }

    private static void setOrderTransactionsToCancelledStatus(List<String> orderIds) {
        List<aforza__Payment_Transaction__c> agbTransactionsToUpdate = new List<aforza__Payment_Transaction__c>();
        for (aforza__Payment_Transaction__c trans : [SELECT Id FROM aforza__Payment_Transaction__c WHERE OrderNumber__c IN :orderIds]) {
            trans.aforza__Status__c = CANCELLED_STATUS;
            agbTransactionsToUpdate.add(trans);
        }
        update agbTransactionsToUpdate;
    }

    private static void setOrderBTTransactionsForRefund(List<String> orderIds) {
        List<bt_stripe__Transaction__c> btTransactionsToUpdate = new List<bt_stripe__Transaction__c>();
        for (bt_stripe__Transaction__c trans : [SELECT Id FROM bt_stripe__Transaction__c WHERE Order__c IN :orderIds]) {
            trans.bt_stripe__Refund__c = true;
            btTransactionsToUpdate.add(trans);
        }
        if (!Test.isRunningTest()) {
            update btTransactionsToUpdate;
        }
    }

    private static void removeOrdersFromRoute(Map<Id, Id> orderIdsToLoadIdsToRemoveFromRoute, Map<Id, Id> accountIdToLoadIdMap) {
        Set<Id> visitIds = new Set<Id>();
        Map<Id, Set<Id>> visitIdToTaskIdsForDeletionSet = new Map<Id, Set<Id>>();
        List<Task> tasksToDelete = fetchTasksForOrders((orderIdsToLoadIdsToRemoveFromRoute.keySet()));
        for (Task task : tasksToDelete) {
            visitIds.add(task.aforza__Visit__c);
            if (visitIdToTaskIdsForDeletionSet.containsKey(task.aforza__Visit__c)) {
                visitIdToTaskIdsForDeletionSet.get(task.aforza__Visit__c).add(task.Id);
            } else {
                visitIdToTaskIdsForDeletionSet.put(task.aforza__Visit__c, new Set<Id>{
                    task.Id
                });
            }
        }
        List<aforza__Visit__c> visitsWithTasks = fetchVisitsWithTasks(visitIds);
        List<aforza__Visit__c> visitsToDelete = new List<aforza__Visit__c>();
        Set<Id> accountIds = new Set<Id>();
        for (aforza__Visit__c visit : visitsWithTasks) {
            // understand if there would be any task left after deletion
            Set<Id> taskIds = visitIdToTaskIdsForDeletionSet.get(visit.Id);
            List<LookedUpFromActivity> existingTasks = visit.aforza__Activities__r;
            for (Integer i = existingTasks.size() - 1; i >= 0; i--) {
                if (taskIds.contains(existingTasks[i].Id)) {
                    existingTasks.remove(i);
                }
            }
            // when there would be no tasks left delete visit and route location
            if (existingTasks.size() == 0) {
                visitsToDelete.add(visit);
                // when deleting visit we also need to delete route location we can get it by combining account Id and Load Id
                accountIds.add(visit.aforza__Account__c);
            }
        }

        delete tasksToDelete;
        delete visitsToDelete;

        if (accountIds.size() > 0) {
            deleteRouteLocations(accountIds, accountIdToLoadIdMap);
        }
        deleteLoadAndRouteIfAllOrdersWereRemoved(orderIdsToLoadIdsToRemoveFromRoute);
    }

    private static List<Task> fetchTasksForOrders(Set<Id> orderIds) {
        return [SELECT Id, aforza__Visit__c FROM Task WHERE aforza__Order__c IN :orderIds];
    }

    private static List<aforza__Visit__c> fetchVisitsWithTasks(Set<Id> visitIds) {
        return [SELECT Id, (SELECT Id FROM aforza__Activities__r), aforza__Account__c FROM aforza__Visit__c WHERE Id IN :visitIds];
    }

    private static void deleteRouteLocations(Set<Id> accountIds, Map<Id, Id> accountIdToLoadIdMap) {
        List<aforza__Route_Location__c> routeLocationsForDeletion = new List<aforza__Route_Location__c>();
        for (aforza__Route_Location__c routeLocation : [
            SELECT Id, aforza__Account__c, aforza__Route__r.LoadId__c
            FROM aforza__Route_Location__c
            WHERE aforza__Account__c IN :accountIds
            AND aforza__Route__r.LoadId__c IN :accountIdToLoadIdMap.values()
        ]) {
            // when we have account in the account to load map, and the load is the same as the load on the route
            // we add the route for deletion
            if (accountIdToLoadIdMap.containsKey(routeLocation.aforza__Account__c) &&
                routeLocation.aforza__Route__r.LoadId__c == accountIdToLoadIdMap.get(routeLocation.aforza__Account__c)) {
                routeLocationsForDeletion.add(routeLocation);
            }
        }
        delete routeLocationsForDeletion;
    }

    private static void deleteLoadAndRouteIfAllOrdersWereRemoved(Map<Id, Id> orderIdsToLoadIdsToRemoveFromRoute) {
        List<SObject> routeAndLoadForDeletion = new List<SObject>();
        // get loads with orders and delete any load and linked route that has no more Orders
        for (Load__c load : [SELECT Id, Route__c, (SELECT Id FROM Orders__r) FROM Load__c WHERE Id IN :orderIdsToLoadIdsToRemoveFromRoute.values()]) {
            if (load.Orders__r.size() == 0) {
                routeAndLoadForDeletion.add(load);
                routeAndLoadForDeletion.add(new aforza__Route__c(Id = load.Route__c));
            }
        }

        delete routeAndLoadForDeletion;
    }
}