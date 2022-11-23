/**
 * Created by svatopluk.sejkora on 16.11.2022.
 */

public with sharing class InvoiceTriggerHandler {

    private static final Boolean CREATE_PAYMENT = InvoiceSettings__c.getOrgDefaults().CreatePaymentWhenInvoiceIsCreated__c;
    private static final Boolean CREATE_PAYMENT_COMMERCE = InvoiceSettings__c.getOrgDefaults().PaymentCommerceOnInvoice__c;
    private static final Set<String> ORDER_RECORD_TYPES_TO_ALLOW_PAYMENT = new Set<String>{
        'EDIOrder', 'FieldDirectOrder', 'TelesalesOrder', 'VanSalesOrder'
    };
    private static final String ORDER_RECORD_TYPE_COMMERCE = 'ECommerceOrder';

    //'ReturnOrder','StraightToJDEOrder' - yet unused order record types

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
        for (aforza__Invoice__c invoice : invoicesWithRelatedData) {
            if (invoice.aforza__Order__r.PrimaryPaymentMethod__c == 'Card Payment' && invoice.aforza__Order__r.PreAuthCaptured__c == false
                && (CREATE_PAYMENT == true && ORDER_RECORD_TYPES_TO_ALLOW_PAYMENT.contains(invoice.aforza__Order__r.RecordType.DeveloperName)
                || CREATE_PAYMENT_COMMERCE == true && invoice.aforza__Order__r.RecordType.DeveloperName == ORDER_RECORD_TYPE_COMMERCE)) {
                    transactionsToCreate.add(createTransactionRecord(invoice));
                    invoiceIds.add(invoice.Id);
            }
        }

        insert transactionsToCreate;
        if (transactionsToCreate.size() > 0) {
            updateInvoiceWithPayLink(invoicesWithRelatedData, invoiceIds);
        }
    }

    public static void evaluateAndSendEmailToCustomer(List<aforza__Invoice__c> invoices) {
        Set<Id> invoiceToSendEmailForIds = new Set<Id>();
        for (aforza__Invoice__c invoice :invoices) {
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
     *
     * @return mapped BT transaction
     *
     *
     * @author Svatopluk Sejkora, BearingPoint
     * @date 2022-11-14
     */
    @TestVisible
    private static bt_stripe__Transaction__c createTransactionRecord(aforza__Invoice__c invoice) {
        bt_stripe__Transaction__c btTransaction = new bt_stripe__Transaction__c();
        btTransaction.RecordTypeId = RecordTypes.BT_TRANSACTION_CHARGE_ID;
        btTransaction.bt_stripe__Amount__c = invoice.Gross__c;
        btTransaction.bt_stripe__Description__c = 'Payment Request for ' + invoice.aforza__Order__r.OrderNumber;
        btTransaction.bt_stripe__Transaction_Type__c = 'Normal';
        btTransaction.bt_stripe__Transaction_Status__c = 'Open';
        btTransaction.bt_stripe__Related_Contact__c = invoice.aforza__Account__r.aforza__Primary_Contact__c;
        btTransaction.bt_stripe__Related_Account__c = invoice.aforza__Account__c;
        btTransaction.bt_stripe__Processed_Date__c = System.now();
        btTransaction.Order__c = invoice.aforza__Order__c;
        btTransaction.Invoice__c = invoice.Id;

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
            SELECT Id, aforza__Order__r.PrimaryPaymentMethod__c, aforza__Order__r.PreAuthCaptured__c,
                aforza__Order__r.RecordType.DeveloperName, Gross__c, aforza__Account__r.aforza__Primary_Contact__c,
                aforza__Account__c, aforza__Order__c, aforza__Order__r.OrderNumber, PaymentLink__c
            FROM aforza__Invoice__c
            WHERE Id IN :invoicesIds
        ];
    }
}