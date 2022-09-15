/**
 * Created by magdalena.stanciu on 13.09.2022.
 */

public with sharing class OrderTriggerHandler {
    public static void determineIfOrderCreationRequiresRelatedAccountStatusUpdate(List<Order> newOrders) {
        Set<Id> accsWithFieldDirectOrder = new Set<Id>();
        for (Order newOrder : newOrders) {
            // New Field Direct Order
            if (newOrder.RecordTypeId == RecordTypes.ORDER_FIELD_DIRECT_ID) {
                accsWithFieldDirectOrder.add(newOrder.AccountId);
            }
        }
        List<Account> relatedAccountsWithUpdatedStatus = AccountService.getAccountsWhichRequireStatusUpdateOnOrderCreation(
                accsWithFieldDirectOrder
        );
        update relatedAccountsWithUpdatedStatus;
    }
}