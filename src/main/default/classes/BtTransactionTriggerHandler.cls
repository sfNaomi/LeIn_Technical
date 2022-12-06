/**
 * Created by svatopluk.sejkora on 15.11.2022.
 */

public with sharing class BtTransactionTriggerHandler {

    /**
     * @description creates aforza transaction whenever specific BT transaction is created
     *
     * @param transactions new BT transactions
     *
     *
     * @author Svatopluk Sejkora, BearingPoint
     * @date 2022-11-14
     */
    public static void createAforzaTransaction(List<bt_stripe__Transaction__c> transactions) {
        Set<Id> accountIds = new Set<Id>();
        Map<String, List<bt_stripe__Transaction__c>> transactionsToProcess = new Map<String, List<bt_stripe__Transaction__c>>{
            'PRE_AUTH' => new List<bt_stripe__Transaction__c>(),
            'INVOICE' => new List<bt_stripe__Transaction__c>(),
            'REFUND' => new List<bt_stripe__Transaction__c>(),
            'JDE' => new List<bt_stripe__Transaction__c>()
        };
        for (bt_stripe__Transaction__c blackthornTransaction : transactions) {
            // to create aforza payment for pre authorised transaction
            if (blackthornTransaction.Order__c != null && blackthornTransaction.bt_stripe__Payment_Status__c == 'Authorized' && blackthornTransaction.Invoice__c == null) {
                accountIds.add(blackthornTransaction.bt_stripe__Related_Account__c);
                transactionsToProcess.get('PRE_AUTH').add(blackthornTransaction);
                continue;
            }
            // to create aforza payment for Straight to JDE orders
            if (blackthornTransaction.Order__c != null && blackthornTransaction.bt_stripe__Payment_Status__c == 'Captured' && blackthornTransaction.Invoice__c == null) {
                accountIds.add(blackthornTransaction.bt_stripe__Related_Account__c);
                transactionsToProcess.get('JDE').add(blackthornTransaction);
                continue;
            }
            // to create aforza payment for invoice based payment creation
            if (blackthornTransaction.Invoice__c != null && blackthornTransaction.Order__c != null) {
                accountIds.add(blackthornTransaction.bt_stripe__Related_Account__c);
                transactionsToProcess.get('INVOICE').add(blackthornTransaction);
                continue;
            }
            // to create aforza payment for refund
            if (blackthornTransaction.bt_stripe__Transaction_Type__c == 'Refund') {
                accountIds.add(blackthornTransaction.bt_stripe__Related_Account__c);
                transactionsToProcess.get('REFUND').add(blackthornTransaction);
            }
        }

        if (transactionsToProcess.size() > 0) {
            List<aforza__Payment_Transaction__c> aforzaTransactionsToInsert = new List<aforza__Payment_Transaction__c>();
            List<Order> ordersToUpdate = new List<Order>();
            Map<Id, Id> accountIdToPaymentMethodId = fetchPaymentMethodsForAccounts(accountIds);
            for (bt_stripe__Transaction__c blackthornTransaction : transactionsToProcess.get('PRE_AUTH')) {
                aforzaTransactionsToInsert.add(mapBlackthornTransactionToAforzaTransaction(blackthornTransaction, accountIdToPaymentMethodId, 'PRE_AUTH'));
                ordersToUpdate.add(new Order(Id = blackthornTransaction.Order__c, PreAuthCaptured__c = true));
            }
            for (bt_stripe__Transaction__c blackthornTransaction : transactionsToProcess.get('JDE')) {
                aforzaTransactionsToInsert.add(mapBlackthornTransactionToAforzaTransaction(blackthornTransaction, accountIdToPaymentMethodId, 'JDE'));
            }
            for (bt_stripe__Transaction__c blackthornTransaction : transactionsToProcess.get('INVOICE')) {
                aforzaTransactionsToInsert.add(mapBlackthornTransactionToAforzaTransaction(blackthornTransaction, accountIdToPaymentMethodId, 'INVOICE'));
            }
            for (bt_stripe__Transaction__c blackthornTransaction : transactionsToProcess.get('REFUND')) {
                aforzaTransactionsToInsert.add(mapBlackthornTransactionToAforzaTransaction(blackthornTransaction, accountIdToPaymentMethodId, 'REFUND'));
            }

            insert aforzaTransactionsToInsert;
            update ordersToUpdate;
        }
    }

    /**
     * @description when BT transaction is completed and Paid update aforza payment and invoice
     *
     * @param transactions BT transactions
     * @param oldMap map with old transactions
     *
     * @author Svatopluk Sejkora, BearingPoint
     * @date 2022-11-14
     */
    public static void updateInvoiceAndAforzaTransactionWhenCompleted(List<bt_stripe__Transaction__c> transactions, Map<Id, bt_stripe__Transaction__c> oldMap) {
        List<SObject> invoicesAndPaymentsToUpdate = new List<SObject>();
        Set<Id> transactionIds = new Set<Id>();
        for (bt_stripe__Transaction__c btTransaction : transactions) {
            bt_stripe__Transaction__c oldTransaction = oldMap.get(btTransaction.Id);
            if (btTransaction.bt_stripe__Payment_Status__c == 'Captured' && btTransaction.bt_stripe__Transaction_Status__c == 'Completed'
                && oldTransaction.bt_stripe__Payment_Status__c <> btTransaction.bt_stripe__Payment_Status__c) {
                // update invoices only when there is an invoice, try to get aforza transactions every time
                if (btTransaction.Invoice__c != null) {
                    invoicesAndPaymentsToUpdate.add(new aforza__Invoice__c(Id = btTransaction.Invoice__c, aforza__Status__c = 'Paid in Full', CreditCardPaymentTaken__c = true));
                }
                transactionIds.add(btTransaction.Id);
            }
        }

        if (transactionIds.size() > 0) {
            invoicesAndPaymentsToUpdate.addAll(preparePaymentsForUpdate(transactionIds));
        }

        update invoicesAndPaymentsToUpdate;
    }

    /**
     * @description maps BT payment to Aforza Payment Transaction
     *
     * @param blackthornTransaction BT transaction
     * @param accountIdToPaymentMethodId map of account Id to ITs payment method
     * @param context context for which the aforza payment is created
     *
     * @return aforzaTransaction with mapped values
     *
     * @author Svatopluk Sejkora, BearingPoint
     * @date 2022-11-14
     */
    @TestVisible
    private static aforza__Payment_Transaction__c mapBlackthornTransactionToAforzaTransaction(bt_stripe__Transaction__c blackthornTransaction, Map<Id, Id> accountIdToPaymentMethodId, String context) {
        aforza__Payment_Transaction__c aforzaTransaction = new aforza__Payment_Transaction__c();
        aforzaTransaction.aforza__Payment_Method__c = accountIdToPaymentMethodId?. get (blackthornTransaction.bt_stripe__Related_Account__c);
        aforzaTransaction.aforza__Amount__c = blackthornTransaction.bt_stripe__Amount__c;
        aforzaTransaction.OrderNumber__c = blackthornTransaction.Order__c;
        aforzaTransaction.aforza__Account__c = blackthornTransaction.bt_stripe__Related_Account__c;
        aforzaTransaction.aforza__Method__c = 'Credit Card';
        aforzaTransaction.aforza__Type__c = 'Customer Payment';
        aforzaTransaction.aforza__Date__c = blackthornTransaction.bt_stripe__Processed_Date__c.date();
        aforzaTransaction.BtTransaction__c = blackthornTransaction.Id;

        if (context == 'PRE_AUTH') {
            aforzaTransaction.aforza__Status__c = 'Pre-Authorization';
        } else if (context == 'INVOICE') {
            aforzaTransaction.aforza__Status__c = 'Pending';
            aforzaTransaction.aforza__Invoice__c = blackthornTransaction.Invoice__c;
        } else if (context == 'REFUND') {
            aforzaTransaction.aforza__Status__c = 'Applied';
            aforzaTransaction.aforza__Invoice__c = blackthornTransaction.Invoice__c;
        } else if (context == 'JDE') {
            aforzaTransaction.aforza__Status__c = 'Applied';
        }

        return aforzaTransaction;
    }

    /**
     * @description fetches specific payment method linked to accounts
     *
     * @param accountIds account Ids to get payments methods for
     *
     * @return accountIdToPaymentMethodId map of account Id to its payment method
     *
     * @author Svatopluk Sejkora, BearingPoint
     * @date 2022-11-14
     */
    @TestVisible
    private static Map<Id, Id> fetchPaymentMethodsForAccounts(Set <Id> accountIds) {
        Map<Id, Id> accountIdToPaymentMethodId = new Map<Id, Id>();
        for (aforza__Payment_Method__c paymentMethod : [
            SELECT Id, aforza__Account__c
            FROM aforza__Payment_Method__c
            WHERE aforza__Account__c IN :accountIds
            AND aforza__Account__r.RecordTypeId = :RecordTypes.ACCOUNT_OUTLET_ID
            AND RecordTypeId = :RecordTypes.PAYMENT_METHOD_CREDIT_CARD_ID
            AND aforza__Active__c = TRUE
        ]) {
            accountIdToPaymentMethodId.put(paymentMethod.aforza__Account__c, paymentMethod.Id);
        }
        return accountIdToPaymentMethodId;
    }

    /**
     * @description obtains aforza payments for each BT transaction and sets it status to Applied
     *
     * @param transactionIds transactions to get aforza payments for
     *
     * @return paymentTransactions - list of aforza transactions to update
     *
     * @author Svatopluk Sejkora, BearingPoint
     * @date 2022-11-14
     */
    @TestVisible
    private static List<aforza__Payment_Transaction__c> preparePaymentsForUpdate(Set <Id> transactionIds) {
        List<aforza__Payment_Transaction__c> paymentTransactions = [SELECT Id, aforza__Status__c FROM aforza__Payment_Transaction__c WHERE BtTransaction__c IN :transactionIds];
        for (aforza__Payment_Transaction__c paymentTransaction : paymentTransactions) {
            paymentTransaction.aforza__Status__c = 'Applied';
            paymentTransaction.aforza__Method__c = 'Credit Card';
        }
        return paymentTransactions;
    }

}