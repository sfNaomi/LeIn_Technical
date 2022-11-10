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
                toBeClonedOrders.add(order);
            } 
        }
        InsecureOrderCloningService.deepCloneOrders(toBeClonedOrders);
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
            Account relatedAccount = relatedAccounts?.get(newOrder.AccountId);
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
                    if(relatedAccount.CreditStatus__c == AccountService.STATUSES_WHERE_ORDER_ACTIVATION_IS_NOT_ALLOWED 
                         && newOrder.RecordTypeId != RecordTypes.ORDER_FIELD_DIRECT_ID && newOrder.IsApproved__c == false){
                            newOrder.addError(Label.OrderActivationPreventedDueToDPOnHold);
                    }
                    if (relatedAccount.AvailableCredit__c < 0 && newOrder.IsApproved__c == false) {
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

    public static void populateDefaultInventory(List<Order> newOrders, Map<Id, Order> oldOrders){
        Map<String, Id> inventoryIdMap = InventoryService.getDepotInventoryMapping();
        for (Order newOrder : newOrders) {
            Order oldOrder = oldOrders?.get(newOrder.Id);
            if (
                (oldOrder == null && newOrder.Depot__c != null) ||
                (oldOrder != null && newOrder.Depot__c != oldOrder.Depot__c)
            ){
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
		DeliveryNoteService.generateOrderAttachmentsAndSendDeliveryEmails(orderIdsToSendDeliveryNoteEmail);
	}
}