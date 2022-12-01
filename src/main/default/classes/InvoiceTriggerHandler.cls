/**
 * Created by svatopluk.sejkora on 16.11.2022.
 */

public with sharing class InvoiceTriggerHandler {

    private static final String PAID_INVOICE_STATUS = 'Paid in Full';
    private static final String APPROVE_INVOICE_STATUS = 'Approve for Payment';
    private static final String UNSUCCESSFUL_INVOICE_STATUS = 'Payment Attempt Unsuccessful';

    private static final Boolean CREATE_PAYMENT = InvoiceSettings__c.getOrgDefaults().CreatePaymentWhenInvoiceIsCreated__c;
    private static final Boolean CREATE_PAYMENT_COMMERCE = InvoiceSettings__c.getOrgDefaults().PaymentCommerceOnInvoice__c;
    private static final Set<String> ORDER_RECORD_TYPES_TO_ALLOW_PAYMENT = new Set<String>{
        'EDIOrder', 'FieldDirectOrder', 'TelesalesOrder', 'VanSalesOrder'
    };
    private static final String ORDER_RECORD_TYPE_COMMERCE = 'ECommerceOrder';
    private static final String ORDER_RECORD_TYPE_RETURN = 'ReturnOrder';

    //'StraightToJDEOrder' - yet unused order record types

    /**
     * @description creates BT transaction whenever an invoice without pre auth is created. It needs to be also enabled in custom settings
     * and Payment method needs to be Credit Card
     *
     * @param invoicesMap map of newly created invoices
     *
     *
     * @author Svatopluk Sejkora, BearingPoint
     * @date 2022-11-14
     */
    public static void createTransactions(Map<Id, aforza__Invoice__c> invoicesMap) {
        // get needed data
        List<aforza__Invoice__c> invoicesWithRelatedData = getInvoicesWithNeededData(invoicesMap.keySet());

        List<bt_stripe__Transaction__c> transactionsToCreate = new List<bt_stripe__Transaction__c>();
        Set<Id> invoiceIds = new Set<Id>();
        Set<Id> ordersToGetTransactionsFor = new Set<Id>();
        List<aforza__Invoice__c> refundInvoices = new List<aforza__Invoice__c>();
        for (aforza__Invoice__c invoice : invoicesWithRelatedData) {
            if (invoice.aforza__Order__r.PaymentMethod__c == 'Card Payment' && invoice.aforza__Order__r.PreAuthCaptured__c == false
                && (CREATE_PAYMENT == true && ORDER_RECORD_TYPES_TO_ALLOW_PAYMENT.contains(invoice.aforza__Order__r.RecordType.DeveloperName)
                || CREATE_PAYMENT_COMMERCE == true && invoice.aforza__Order__r.RecordType.DeveloperName == ORDER_RECORD_TYPE_COMMERCE)) {
                transactionsToCreate.add(createTransactionRecord(invoice, null));
                invoiceIds.add(invoice.Id);
                continue;
            }
            if (invoice.Gross__c < 0 && invoice.aforza__Order__r.aforza__Original_Order__c != null &&
                invoice.aforza__Order__r.aforza__Original_Order__r.PaymentMethod__c == 'Card Payment' &&
                invoice.aforza__Order__r.RecordType.DeveloperName == ORDER_RECORD_TYPE_RETURN) {
                ordersToGetTransactionsFor.add(invoice.aforza__Order__r.aforza__Original_Order__c);
                refundInvoices.add(invoice);
            }
        }

        transactionsToCreate.addAll(handleRefundInvoices(ordersToGetTransactionsFor, refundInvoices));

        insert transactionsToCreate;
        if (invoiceIds.size() > 0) {
            updateInvoiceWithPayLink(invoicesWithRelatedData, invoiceIds);
        }
    }

    public static void evaluateAndSendEmailToCustomer(List<aforza__Invoice__c> invoices) {
        Set<Id> invoiceToSendEmailForIds = new Set<Id>();
        for (aforza__Invoice__c invoice : invoices) {
            if (invoice.InvoiceSentToCustomer__c == false && invoice.InvoiceReadyForEvaluation__c == true) {
                invoiceToSendEmailForIds.add(invoice.Id);
            }
        }
        InvoiceEmailService.sendInvoiceToCustomers(invoiceToSendEmailForIds);
    }

    /**
     * @description maps invoice data and default values to BT payment
     *
     * @param invoice invoice from which to create BT payment
     * @param originalTransaction transaction to get data from, it is original transaction required when handling refunds
     *
     * @return mapped BT transaction
     *
     *
     * @author Svatopluk Sejkora, BearingPoint
     * @date 2022-11-14
     */
    @TestVisible
    private static bt_stripe__Transaction__c createTransactionRecord(aforza__Invoice__c invoice, bt_stripe__Transaction__c originalTransaction) {
        bt_stripe__Transaction__c btTransaction = new bt_stripe__Transaction__c();
        btTransaction.RecordTypeId = RecordTypes.BT_TRANSACTION_CHARGE_ID;
        btTransaction.bt_stripe__Amount__c = invoice.Gross__c;
        btTransaction.bt_stripe__Transaction_Status__c = 'Open';
        btTransaction.bt_stripe__Processed_Date__c = System.now();
        btTransaction.Invoice__c = invoice.Id;

        if (originalTransaction != null) {
            btTransaction.bt_stripe__Transaction_Type__c = 'Refund';
            btTransaction.Order__c = invoice.aforza__Order__r.aforza__Original_Order__c;
            btTransaction.bt_stripe__Parent_Transaction__c = originalTransaction.Id;
            btTransaction.bt_stripe__Parent_Transaction_Id__c = originalTransaction.Id;
            btTransaction.bt_stripe__Payment_Method_Billing_Email__c = originalTransaction.bt_stripe__Payment_Method_Billing_Email__c;
            btTransaction.bt_stripe__Stripe_Customer__c = originalTransaction.bt_stripe__Stripe_Customer__c;
            btTransaction.bt_stripe__Related_Contact__c = originalTransaction.bt_stripe__Related_Contact__c;
            btTransaction.bt_stripe__Related_Account__c = originalTransaction.bt_stripe__Related_Account__c;
            btTransaction.bt_stripe__Payment_Method__c = originalTransaction.bt_stripe__Payment_Method__c;
            btTransaction.bt_stripe__Capture__c = true;
        } else {
            btTransaction.bt_stripe__Description__c = 'Payment Request for ' + invoice.aforza__Order__r.OrderNumber;
            btTransaction.bt_stripe__Transaction_Type__c = 'Normal';
            btTransaction.Order__c = invoice.aforza__Order__c;
            btTransaction.bt_stripe__Related_Contact__c = invoice.aforza__Account__r.aforza__Primary_Contact__c;
            btTransaction.bt_stripe__Related_Account__c = invoice.aforza__Account__c;
        }

        return btTransaction;
    }

    private static void updateInvoiceWithPayLink(List<aforza__Invoice__c> invoiceList, Set<Id> invoiceIds) {
        // get the payments with links
        Map<Id, String> invoiceIdToItsPaymentLink = getPaymentLinks(invoiceIds);

        for (aforza__Invoice__c invoice : invoiceList) {
            invoice.PaymentLink__c = invoiceIdToItsPaymentLink.get(invoice.Id);
        }

        update invoiceList;
    }

    private static Map<Id, String> getPaymentLinks(Set<Id> invoiceIds) {
        Map<Id, String> invoiceIdToItsPaymentLink = new Map<Id, String>();
        for (bt_stripe__Transaction__c btTransaction : [SELECT Id, Invoice__c, bt_paylink__PayLink__c FROM bt_stripe__Transaction__c WHERE Invoice__c IN :invoiceIds]) {
            invoiceIdToItsPaymentLink.put(btTransaction.Invoice__c, btTransaction.bt_paylink__PayLink__c);
        }
        return invoiceIdToItsPaymentLink;
    }

    private static List<aforza__Invoice__c> getInvoicesWithNeededData(Set<Id> invoicesIds) {
        return [
            SELECT Id, aforza__Order__r.PaymentMethod__c, aforza__Order__r.PreAuthCaptured__c,
                aforza__Order__r.RecordType.DeveloperName, Gross__c, aforza__Account__r.aforza__Primary_Contact__c,
                aforza__Account__c, aforza__Order__c, aforza__Order__r.OrderNumber, PaymentLink__c,
                aforza__Order__r.aforza__Original_Order__r.PaymentMethod__c, aforza__Order__r.aforza__Original_Order__c
            FROM aforza__Invoice__c
            WHERE Id IN :invoicesIds
        ];
    }

    public static void updateFailedInvoices(List<aforza__Invoice__c> newInvoices, Map<Id, aforza__Invoice__c> oldInvoices) {
        List<aforza__Invoice__c> failedInvoicesToUpdate = new List<aforza__Invoice__c>();
        for(aforza__Invoice__c newInvoice: newInvoices){
            aforza__Invoice__c oldInvoice = oldInvoices?.get(newInvoice.Id);
            if(oldInvoice != null  && oldInvoice.aforza__Status__c == PAID_INVOICE_STATUS && newInvoice.aforza__Status__c  == APPROVE_INVOICE_STATUS) {
                newInvoice.aforza__Status__c = UNSUCCESSFUL_INVOICE_STATUS;
            }
        }
    }

    public static void updatePaymentTransactionsForInvoices(List<aforza__Invoice__c> newInvoices, Map<Id, aforza__Invoice__c> oldInvoices) {
        Set<Id> invoiceIds = new Set<Id>();
        for(aforza__Invoice__c newInvoice: newInvoices){
            aforza__Invoice__c oldInvoice = oldInvoices?.get(newInvoice.Id);
            Boolean isStatusChanged = oldInvoice != null && newInvoice.aforza__Status__c != oldInvoice.aforza__Status__c;
            if( isStatusChanged && (newInvoice.aforza__Status__c == PAID_INVOICE_STATUS || newInvoice.aforza__Status__c  == UNSUCCESSFUL_INVOICE_STATUS)) {
                invoiceIds.add(newInvoice.Id);
            }
        }
        if(!invoiceIds.isEmpty()) {
            PaymentTransactionService.updatePaymentTransactionStatusForInvoices(invoiceIds);
        }
    }
    
    private static List<bt_stripe__Transaction__c> handleRefundInvoices(Set<Id> ordersToGetTransactionsFor, List<aforza__Invoice__c> refundInvoices) {
        // get transactions to order Map, we expect only one transaction per order, so we disregard any other
        Map<Id, bt_stripe__Transaction__c> orderToTransactionMap = fetchOrdersWithTransactions(ordersToGetTransactionsFor);
        List<bt_stripe__Transaction__c> transactionsToCreate = new List<bt_stripe__Transaction__c>();
        for (aforza__Invoice__c invoice : refundInvoices) {
            Id originalOrderId = invoice.aforza__Order__r.aforza__Original_Order__c;
            if (orderToTransactionMap.containsKey(originalOrderId)) {
                transactionsToCreate.add(createTransactionRecord(invoice, orderToTransactionMap.get(originalOrderId)));
            }
        }
        return transactionsToCreate;
    }

    private static Map<Id, bt_stripe__Transaction__c> fetchOrdersWithTransactions(Set<Id> ordersToGetTransactionsFor) {
        Map<Id, bt_stripe__Transaction__c> orderToTransactionMap = new Map<Id, bt_stripe__Transaction__c>();
        for (Order order : [
            SELECT Id, (
                SELECT Id, bt_stripe__Payment_Method_Billing_Email__c, bt_stripe__Stripe_Customer__c,
                    bt_stripe__Related_Contact__c, bt_stripe__Related_Account__c, bt_stripe__Payment_Method__c
                FROM Transactions__r
                LIMIT 1
            )
            FROM Order
            WHERE Id IN :ordersToGetTransactionsFor
        ]) {
            orderToTransactionMap.put(order.Id, order.Transactions__r[0]);
        }
        return orderToTransactionMap;
    }
}