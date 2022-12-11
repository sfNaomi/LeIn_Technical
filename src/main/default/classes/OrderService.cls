/**
 * Created by magdalena.stanciu on 19.09.2022.
 */

public with sharing class OrderService {
    public static final OrderSetting__mdt SETTINGS {
        get {
            if (SETTINGS == null) {
                SETTINGS = OrderSetting__mdt.getInstance('OrgDefaultOrderSettings');
            }
            return SETTINGS;
        }
        set;
    }

    public static final Set<String> COMPLETED_ORDER_STATUSES {
        get {
            if (COMPLETED_ORDER_STATUSES == null) {
                COMPLETED_ORDER_STATUSES = new Set<String>(SETTINGS.CompletedOrderStatuses__c.split(','));
            }
            return COMPLETED_ORDER_STATUSES;
        }
        set;
    }

    public static final Set<String> RECORD_TYPES_TO_UPDATE_ACCOUNT_ON_ORDER_COMPLETION {
        get {
            if (RECORD_TYPES_TO_UPDATE_ACCOUNT_ON_ORDER_COMPLETION == null) {
                RECORD_TYPES_TO_UPDATE_ACCOUNT_ON_ORDER_COMPLETION = new Set<String>(SETTINGS.RTsToUpdateAccOnOrderCompletion__c.split(','));
            }
            return RECORD_TYPES_TO_UPDATE_ACCOUNT_ON_ORDER_COMPLETION;
        }
        set;
    }

    public static final Set<String> RECORD_TYPES_TO_CREATE_INVOICE {
        get {
            if (RECORD_TYPES_TO_CREATE_INVOICE == null) {
                RECORD_TYPES_TO_CREATE_INVOICE = new Set<String>(SETTINGS.RTsToCreateInvoice__c.split(','));
            }
            return RECORD_TYPES_TO_CREATE_INVOICE;
        }
        set;
    }
    public static final Set<String> UNFULFILLED_ORDER_STATUS {
        get {
            if (UNFULFILLED_ORDER_STATUS == null) {
                UNFULFILLED_ORDER_STATUS = new Set<String>(SETTINGS.UnfulfilledOrders__c.split(','));
            }
            return UNFULFILLED_ORDER_STATUS;
        }
        set;
    }

    public static final Set<String> RECORD_TYPES_FOR_STOCK_UPDATE {
        get {
            if (RECORD_TYPES_FOR_STOCK_UPDATE == null) {
                RECORD_TYPES_FOR_STOCK_UPDATE = new Set<String>(SETTINGS.RtsStockUpdate__c.split(','));
            }
            return RECORD_TYPES_FOR_STOCK_UPDATE;
        }
        set;
    }


    public static Boolean isOrderCompleted(String orderStatus) {
        return COMPLETED_ORDER_STATUSES.contains(orderStatus);
    }

    public static Boolean orderTypeCountsTowardsAccountLastOrderDate(Id orderRecordTypeId) {
        return RECORD_TYPES_TO_UPDATE_ACCOUNT_ON_ORDER_COMPLETION.contains(RecordTypes.ORDER_RT_INFO_BY_ID?.get(orderRecordTypeId)?.getDeveloperName());
    }

    public static Boolean orderTypeRequiresInvoiceCreation(Id orderRecordTypeId) {
        return RECORD_TYPES_TO_CREATE_INVOICE.contains(RecordTypes.ORDER_RT_INFO_BY_ID?.get(orderRecordTypeId)?.getDeveloperName());
    }

    public static void updateLastOrderDateAndStatusOnParentAccount(List<Order> newOrders) {
        Set<Id> relatedAccountIds = new Set<Id>();
        for (Order newOrder : newOrders) {
            relatedAccountIds.add(newOrder.AccountId);
        }
        AccountService.updateLastOrderDateAndAccountStatus(relatedAccountIds);
    }

    public static void updateOrderStatus(List<Order> newOrders, String newStatus) {
        List<Order> ordersToUpdate = new List<Order>();
        for (Order newOrder : newOrders) {
            ordersToUpdate.add(new Order(Id = newOrder.Id, Status = newStatus));
        }
        update ordersToUpdate;
    }

    public static void updateOrdersByPreventingLockValidation(List<Order> newOrders) {
        // enable saving of locked orders
        OrderTriggerHandler.allowUpdateOfLockedOrders = true;

        update newOrders;

        // disable saving of locked orders
        OrderTriggerHandler.allowUpdateOfLockedOrders = false;
    }
}