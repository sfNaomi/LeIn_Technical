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
            if (
                !AccountService.STATUSES_WHERE_ORDER_CREATION_ALLOWED.contains(relatedAccount.AccountStatus__c) &&
                (
                    (oldOrder == null) ||
                    (oldOrder != null && newOrder.Status != oldOrder.Status && OrderService.COMPLETED_ORDER_STATUSES.contains(newOrder.Status))
                )
            ) {
                newOrder.addError(Label.OrderCreationActivationIsNotAllowedForCurrentAccountStatus);
            }
        }
    }
}