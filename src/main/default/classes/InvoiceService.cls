/**
 * Created by magdalena.stanciu on 06.10.2022.
 */

public with sharing class InvoiceService {
    public static final FieldMapping__mdt ORDER_TO_INVOICE_MAPPING {
        get {
            if (ORDER_TO_INVOICE_MAPPING == null) {
                ORDER_TO_INVOICE_MAPPING = CommonUtility.getFieldMapping('ORDER_TO_INVOICE');
            }
            return ORDER_TO_INVOICE_MAPPING;
        }
        set;
    }

    public static final FieldMapping__mdt ORDER_ITEM_TO_INVOICE_ITEM_MAPPING {
        get {
            if (ORDER_ITEM_TO_INVOICE_ITEM_MAPPING == null) {
                ORDER_ITEM_TO_INVOICE_ITEM_MAPPING = CommonUtility.getFieldMapping('ORDER_ITEM_TO_INVOICE_ITEM');
            }
            return ORDER_ITEM_TO_INVOICE_ITEM_MAPPING;
        }
        set;
    }

    public static void createInvoicesForOrders(Set<Id> orderIdsToCreateInvoiceFor) {
        List<Order> ordersToBeProcessed = getOrders(orderIdsToCreateInvoiceFor);
        List<aforza__Invoice__c> existingInvoices = getInvoices(orderIdsToCreateInvoiceFor);

        Map<Id, aforza__Invoice__c> orderIdExistingInvoice = new Map<Id, aforza__Invoice__c>();
        for (aforza__Invoice__c existingInvoice : existingInvoices) {
            orderIdExistingInvoice.put(existingInvoice.aforza__Order__c, existingInvoice);
        }

        // generate invoices
        Map<Id, aforza__Invoice__c> invoicesByOriginalOrderId = new Map<Id, aforza__Invoice__c>();
        for (Order existingOrder : ordersToBeProcessed) {
            aforza__Invoice__c newInvoice = orderIdExistingInvoice.get(existingOrder.Id);

            if (newInvoice == null) {
                newInvoice = new aforza__Invoice__c();
            }

            populateInvoiceFromOrder(newInvoice, existingOrder);
            invoicesByOriginalOrderId.put(existingOrder.Id, newInvoice);
        }
        upsert invoicesByOriginalOrderId.values();

        // generate invoice line items
        List<aforza__Invoice_Line_Item__c> invoiceLineItems = new List<aforza__Invoice_Line_Item__c>();
        for (Order existingOrder : ordersToBeProcessed) {
            aforza__Invoice__c existingInvoice = invoicesByOriginalOrderId.get(existingOrder.Id);
            for (OrderItem existingOrderItem : existingOrder.OrderItems) {
                aforza__Invoice_Line_Item__c newInvoiceLineItem = generateInvoiceLineItem(existingOrderItem, existingInvoice);

                invoiceLineItems.add(newInvoiceLineItem);
            }
        }
        insert invoiceLineItems;

        // link payments
        List<aforza__Payment_Transaction__c> transactions = getPaymentTransactions(orderIdsToCreateInvoiceFor);
        for (aforza__Payment_Transaction__c newTransaction : transactions) {
            Id invoiceId = invoicesByOriginalOrderId?.get(newTransaction.OrderNumber__c)?.Id;
            newTransaction.aforza__Invoice__c = invoiceId;
        }
        update transactions;
    }

    @TestVisible
    private static List<aforza__Payment_Transaction__c> getPaymentTransactions(Set<Id> orderIds) {
        List<aforza__Payment_Transaction__c> transactions = [
                SELECT Id, OrderNumber__c, aforza__Invoice__c
                FROM aforza__Payment_Transaction__c
                WHERE OrderNumber__c IN :orderIds
        ];
        return transactions;
    }

    @TestVisible
    private static aforza__Invoice__c populateInvoiceFromOrder(aforza__Invoice__c newInvoice, Order existingOrder) {
        // set fixed fields
        newInvoice.aforza__Issued_Date__c = newInvoice.aforza__Issued_Date__c != null ? newInvoice.aforza__Issued_Date__c : System.today();
        newInvoice.aforza__Due_Date__c = newInvoice.aforza__Issued_Date__c + 28;

        // populate fields on the new invoice based on mapping
        CommonUtility.populateTargetSObjectFromSourceSObjectBasedOnMapping(
                newInvoice,
                existingOrder,
                ORDER_TO_INVOICE_MAPPING
        );

        return newInvoice;
    }

    @TestVisible
    private static aforza__Invoice_Line_Item__c generateInvoiceLineItem(OrderItem existingOrderItem, aforza__Invoice__c existingInvoice) {
        // create invoice line item
        aforza__Invoice_Line_Item__c newInvoiceLineItem = new aforza__Invoice_Line_Item__c();

        // add fixed fields - fields may be overwritten, if mappings exist for these fields
        newInvoiceLineItem.aforza__Invoice__c = existingInvoice.Id;

        // populate fields on the new invoice based on mapping
        CommonUtility.populateTargetSObjectFromSourceSObjectBasedOnMapping(
                newInvoiceLineItem,
                existingOrderItem,
                ORDER_ITEM_TO_INVOICE_ITEM_MAPPING
        );

        return newInvoiceLineItem;
    }

    @TestVisible
    private static List<Order> getOrders(Set<Id> orderIds) {
        List<String> orderFields = new List<String>(CommonUtility.getFieldsToQueryFromMapping(
                ORDER_TO_INVOICE_MAPPING, CommonUtility.QueryFieldType.SOURCE
        ));
        List<String> orderItemFields = new List<String>(CommonUtility.getFieldsToQueryFromMapping(
                ORDER_ITEM_TO_INVOICE_ITEM_MAPPING, CommonUtility.QueryFieldType.SOURCE
        ));

        String queryString = 'SELECT ' + String.join(orderFields, ',') + ', ' +
                '(SELECT ' + String.join(orderItemFields, ',') + ' FROM OrderItems) ' +
                'FROM Order WHERE Id IN :orderIds';
        List<Order> orders = Database.query(queryString);

        return orders;
    }

    @TestVisible
    private static List<aforza__Invoice__c> getInvoices(Set<Id> orderIds) {
        Set<String> invoiceFields = CommonUtility.getFieldsToQueryFromMapping(
                ORDER_TO_INVOICE_MAPPING, CommonUtility.QueryFieldType.TARGET
        );

        // fields set to fixed values in code - not based on mapping
        Set<String> FIXED_INVOICE_FIELDS = new Set<String>{'aforza__Issued_Date__c', 'aforza__Due_Date__c'};
        invoiceFields.addAll(FIXED_INVOICE_FIELDS);

        List<String> allQueryFields = new List<String>(invoiceFields);

        String queryString = 'SELECT ' + String.join(allQueryFields, ',') + ' FROM aforza__Invoice__c WHERE aforza__Order__c IN :orderIds';
        List<aforza__Invoice__c> invoices = Database.query(queryString);

        return invoices;
    }
}