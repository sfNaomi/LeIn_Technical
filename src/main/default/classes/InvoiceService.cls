/**
 * @description       : Service class for invoice generation
 **/

public with sharing class InvoiceService {
    private static final String INVOICE_EMAIL_TEMPLATE_NAME = 'AGBarrInvoiceEmailTemplate';

    private static final String DD_PAYMENT_METHOD = 'Direct Debit';
    private static final String PAID_INVOICE_STATUS = 'Paid in Full';
    private static final String CREDIT_CARD_PAYMENT_METHOD = 'Credit Card';
    private static final String PENDING_PAYMENT_INVOICE_STATUS = 'Pending Payment';

    private static final Id INVOICE_EMAIL_TEMPLATE_ID {
        get {
            if (INVOICE_EMAIL_TEMPLATE_ID == null) {
                List<EmailTemplate> templates = new List<EmailTemplate>([
                    SELECT Id
                    FROM EmailTemplate
                    WHERE DeveloperName = :INVOICE_EMAIL_TEMPLATE_NAME
                    LIMIT 1
                ]);
                INVOICE_EMAIL_TEMPLATE_ID = templates.isEmpty() ? null : templates[0].Id;
            }
            return INVOICE_EMAIL_TEMPLATE_ID;
        }
        set;
    }

    private static final FieldMapping__mdt ORDER_TO_INVOICE_MAPPING {
        get {
            if (ORDER_TO_INVOICE_MAPPING == null) {
                ORDER_TO_INVOICE_MAPPING = CommonUtility.getFieldMapping('ORDER_TO_INVOICE');
            }
            return ORDER_TO_INVOICE_MAPPING;
        }
        set;
    }

    private static final FieldMapping__mdt ORDER_ITEM_TO_INVOICE_ITEM_MAPPING {
        get {
            if (ORDER_ITEM_TO_INVOICE_ITEM_MAPPING == null) {
                ORDER_ITEM_TO_INVOICE_ITEM_MAPPING = CommonUtility.getFieldMapping('ORDER_ITEM_TO_INVOICE_ITEM');
            }
            return ORDER_ITEM_TO_INVOICE_ITEM_MAPPING;
        }
        set;
    }

    /**
     * @description creates invoice for orders (invoice with related invoice line items, relates existing payments to the
     * 				invoice and generated the invoice documents and sends it via email)
     *
     * @param orderIdsToCreateInvoices ids of orders for which invoices must be created
     *
     *
     * @author Magdalena Stanciu
     * @date 2022-10-10
     */
    public static void createInvoicesFromOrders(Set<Id> orderIdsToCreateInvoices) {
        List<Order> ordersToBeProcessed = getOrders(orderIdsToCreateInvoices);
        List<aforza__Invoice__c> existingInvoices = getInvoices(orderIdsToCreateInvoices);

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

            generateInvoiceFromOrder(newInvoice, existingOrder);
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

        // link aforza payments
        List<aforza__Payment_Transaction__c> transactions = getPaymentTransactions(orderIdsToCreateInvoices);
        for (aforza__Payment_Transaction__c newTransaction : transactions) {
            Id invoiceId = invoicesByOriginalOrderId?.get(newTransaction.OrderNumber__c)?.Id;
            Decimal amount = invoicesByOriginalOrderId?.get(newTransaction.OrderNumber__c)?.Gross__c;
            newTransaction.aforza__Invoice__c = invoiceId;
            newTransaction.aforza__Amount__c = amount;
        }
        update transactions;

        // link bt payments
        List<bt_stripe__Transaction__c> btTransactions = getBtTransactions(orderIdsToCreateInvoices);
        for (bt_stripe__Transaction__c newTransaction : btTransactions) {
            Id invoiceId = invoicesByOriginalOrderId?.get(newTransaction.Order__c)?.Id;
            Decimal amount = invoicesByOriginalOrderId?.get(newTransaction.Order__c)?.Gross__c;
            newTransaction.Invoice__c = invoiceId;
            newTransaction.bt_stripe__Amount_To_Capture__c = amount;
            newTransaction.bt_stripe__Capture__c = true;
        }
        update btTransactions;

        // update invoice lookup on orders
        Set<Id> invoiceIdsToGenerateFilesAndSendThemViaEmail = new Set<Id>();
        List<Order> ordersToUpdate = new List<Order>();
        for (Id orderId : invoicesByOriginalOrderId.keySet()) {
            Id invoiceId = invoicesByOriginalOrderId.get(orderId)?.Id;
            if (invoiceId != null) {
                invoiceIdsToGenerateFilesAndSendThemViaEmail.add(invoiceId);
                ordersToUpdate.add(new Order(Id = orderId, Invoice__c = invoiceId));
            }
        }
        update ordersToUpdate;

        // generate invoice documents and send them via email
        generateInvoiceDocumentsAndSendFilesViaEmail(invoiceIdsToGenerateFilesAndSendThemViaEmail);
    }

    /**
     * @description get existing payment transactions related to orders
     *
     * @param orderIds ids of orders for which transactions will be retrieved
     *
     * @return list of transactions
     *
     * @author Magdalena Stanciu
     * @date 2022-10-10
     */
    @TestVisible
    private static List<aforza__Payment_Transaction__c> getPaymentTransactions(Set<Id> orderIds) {
        List<aforza__Payment_Transaction__c> transactions = [
            SELECT Id, OrderNumber__c, aforza__Invoice__c
            FROM aforza__Payment_Transaction__c
            WHERE OrderNumber__c IN :orderIds
        ];
        return transactions;
    }

    /**
     * @description get existing BT transactions related to orders
     *
     * @param orderIds ids of orders for which transactions will be retrievedasdasd
     *
     * @return list of BT transactions
     *
     * @author Svata Sejkora
     * @date 2022-11-14
     */
    @TestVisible
    private static List<bt_stripe__Transaction__c> getBtTransactions(Set<Id> orderIds) {
        return [
            SELECT Id, Order__c, Invoice__c, bt_stripe__Payment_Status__c, bt_stripe__Transaction_Status__c
            FROM bt_stripe__Transaction__c
            WHERE Order__c IN :orderIds
        ];
    }

    /**
     * @description enriches the inbound invoice record with data from the inbound order (based on mapping stored in CMD)
     *
     * @param newInvoice invoice record to be enriched with order information
     * @param existingOrder order record based on which the invoice is enriched
     *
     *
     * @author Magdalena Stanciu
     * @date 2022-10-10
     */
    @TestVisible
    private static void generateInvoiceFromOrder(aforza__Invoice__c newInvoice, Order existingOrder) {
        // set fixed fields
        newInvoice.aforza__Issued_Date__c = computeInvoiceIssuedDate(newInvoice.aforza__Issued_Date__c);
        newInvoice.aforza__Due_Date__c = calculateInvoiceDueDate(existingOrder.Account.PaymentTerms__c, newInvoice.aforza__Issued_Date__c);
        newInvoice.aforza__Status__c = computeInvoiceStatus(existingOrder.Account.PrimaryPaymentMethod__c, newInvoice.aforza__Status__c);

        // populate fields on the new invoice based on mapping
        CommonUtility.populateTargetSObjectFromSourceSObjectBasedOnMapping(newInvoice, existingOrder, ORDER_TO_INVOICE_MAPPING);
    }

    /**
     * @description calculates invoice issued date
     *
     * @param currentIssuedDate current invoice issued date
     *
     * @return invoice issued date
     *
     * @author Magdalena Stanciu
     * @date 2022-11-10
     */
    @TestVisible
    private static Date computeInvoiceIssuedDate(Date currentIssuedDate) {
        return currentIssuedDate != null ? currentIssuedDate : System.today();
    }

    /**
     * @description computes invoice status based on the payment method of the related account
     *
     * @param paymentMethod payment method of related account
     * @param currentStatus current invoice status
     *
     * @return invoice status
     *
     * @author Magdalena Stanciu
     * @date 2022-11-10
     */
    @TestVisible
    private static String computeInvoiceStatus(String paymentMethod, String currentStatus) {
        return paymentMethod == DD_PAYMENT_METHOD ? PAID_INVOICE_STATUS : paymentMethod == CREDIT_CARD_PAYMENT_METHOD ? PENDING_PAYMENT_INVOICE_STATUS : currentStatus;
    }

    /**
     * @description calculates invoice due date based on invoice issued date and payment terms
     *
     * @param paymentTerms payment terms of the related dp
     * @param issuedDate date when invoice was issued
     *
     * @return invoice due date
     *
     * @author Magdalena Stanciu
     * @date 2022-11-10
     */
    @TestVisible
    private static Date calculateInvoiceDueDate(String paymentTerms, Date issuedDate) {
        Date dueDate = issuedDate;
        switch on paymentTerms {
            when 'STD' {
                dueDate = toEndOfTheMonth(issuedDate.addMonths(1)).addDays(30);
            }
            when 'TMA' {
                dueDate = toEndOfTheMonth(issuedDate.addMonths(2));
            }
            when 'TWA' {
                Date endOfSecondMonth = toEndOfTheMonth(issuedDate.addMonths(2));
                dueDate = Date.newInstance(endOfSecondMonth.year(), endOfSecondMonth.month(), 15);
            }
            when '50D' {
                dueDate = issuedDate.addDays(50);
            }
            when '21D' {
                dueDate = issuedDate.addDays(21);
            }
        }
        return dueDate;
    }

    /**
     * @description returns the date corresponding to the end of the month for provided date
     *
     * @param newDate date to calculate end of the month for
     *
     * @return end of the month for provided date
     *
     * @author Magdalena Stanciu
     * @date 2022-11-10
     */
    private static Date toEndOfTheMonth(Date newDate) {
        return newDate.addMonths(1).toStartOfMonth().addDays(-1);
    }

    /**
     * @description creates invoice lines items based on order line items and related the invoice line item to the invoice
     *
     * @param existingOrderItem order item record to generate an invoice line item from it
     * @param existingInvoice invoice to relate the generate invoice line item to it
     *
     * @return aforza__Invoice_Line_Item__c new invoice line item record
     *
     * @author Magdalena Stanciu
     * @date 2022-10-10
     */
    @TestVisible
    private static aforza__Invoice_Line_Item__c generateInvoiceLineItem(OrderItem existingOrderItem, aforza__Invoice__c existingInvoice) {
        // create invoice line item
        aforza__Invoice_Line_Item__c newInvoiceLineItem = new aforza__Invoice_Line_Item__c();

        // add fixed fields - fields may be overwritten, if mappings exist for these fields
        newInvoiceLineItem.aforza__Invoice__c = existingInvoice.Id;

        // populate fields on the new invoice based on mapping
        CommonUtility.populateTargetSObjectFromSourceSObjectBasedOnMapping(
            newInvoiceLineItem, existingOrderItem, ORDER_ITEM_TO_INVOICE_ITEM_MAPPING
        );

        return newInvoiceLineItem;
    }

    /**
     * @description retrieves orders with all the fields needed for invoice generation
     * 				(taken dynamically based on mapping stored in CMD)
     *
     * @param orderIds ids of orders to be retrieved
     *
     * @return List<Order> retrieved orders
     *
     * @author Magdalena Stanciu
     * @date 2022-10-10
     */
    @TestVisible
    private static List<Order> getOrders(Set<Id> orderIds) {
        List<String> orderFields = new List<String>(
            CommonUtility.getFieldsToQueryFromMapping(ORDER_TO_INVOICE_MAPPING, CommonUtility.QueryFieldType.SOURCE)
        );
        List<String> orderItemFields = new List<String>(
            CommonUtility.getFieldsToQueryFromMapping(ORDER_ITEM_TO_INVOICE_ITEM_MAPPING, CommonUtility.QueryFieldType.SOURCE)
        );

        String queryString =
            'SELECT ' + String.join(orderFields, ',') + ', ' +
                '(SELECT ' + String.join(orderItemFields, ',') + ' FROM OrderItems) ' +
                'FROM Order WHERE Id IN :orderIds';
        List<Order> orders = Database.query(queryString);

        return orders;
    }

    /**
     * @description retrieves existing invoices for orders
     *
     * @param orderIds ids of orders to retrieve the invoice for them
     *
     * @return List<aforza__Invoice__c> retrieved invoices
     *
     * @author Magdalena Stanciu
     * @date 2022-10-10
     */
    @TestVisible
    private static List<aforza__Invoice__c> getInvoices(Set<Id> orderIds) {
        Set<String> invoiceFields = CommonUtility.getFieldsToQueryFromMapping(
            ORDER_TO_INVOICE_MAPPING, CommonUtility.QueryFieldType.TARGET
        );

        // fields set to fixed values in code - not based on mapping
        Set<String> FIXED_INVOICE_FIELDS = new Set<String>{
            'aforza__Issued_Date__c', 'aforza__Due_Date__c'
        };
        invoiceFields.addAll(FIXED_INVOICE_FIELDS);

        List<String> allQueryFields = new List<String>(invoiceFields);

        String queryString = 'SELECT ' + String.join(allQueryFields, ',') + ' FROM aforza__Invoice__c WHERE aforza__Order__c IN :orderIds';
        List<aforza__Invoice__c> invoices = Database.query(queryString);

        return invoices;
    }

    /**
     * @description generates invoice documents, saves them as files related to invoices and sends them via email
     *
     * @param invoiceIds ids of invoices to generate files for and send them via email
     *
     *
     * @author Magdalena Stanciu
     * @date 2022-10-10
     */
    @Future(Callout=true)
    public static void generateInvoiceDocumentsAndSendFilesViaEmail(Set<Id> invoiceIds) {
        if (invoiceIds.isEmpty() || INVOICE_EMAIL_TEMPLATE_ID == null) {
            return;
        }

        // get invoices with completed details
        Map<Id, aforza__Invoice__c> invoicesToGenerateDocuments = getInvoicesWhichRequireInvoiceSendingViaEmail(invoiceIds);

        // generate files and send them via email
        Map<Id, ContentVersion> contentVersionsByInvoiceId = generateInvoiceDocuments(invoicesToGenerateDocuments.keySet());
        sendInvoiceDocumentsViaEmail(invoicesToGenerateDocuments, contentVersionsByInvoiceId);
    }

    /**
     * @description retrieves invoices with complete details
     *
     * @param invoiceIds ids of invoices
     *
     * @return Map<Id, aforza__Invoice__c> invoices with additional details
     *
     * @author Magdalena Stanciu
     * @date 2022-10-10
     */
    public static Map<Id, aforza__Invoice__c> getInvoicesWhichRequireInvoiceSendingViaEmail(Set<Id> invoiceIds) {
        Map<Id, aforza__Invoice__c> invoices = new Map<Id, aforza__Invoice__c>([
            SELECT
                Id,
                aforza__Account__r.aforza__Invoice_Email_Address__c,
                aforza__Account__r.aforza__Primary_Contact__c
            FROM aforza__Invoice__c
            WHERE
                Id IN :invoiceIds
                AND aforza__Account__r.InvoiceType__c = 'Email'
                AND aforza__Account__r.aforza__Invoice_Email_Address__c != NULL
                AND aforza__Account__r.aforza__Primary_Contact__c != NULL
        ]);
        return invoices;
    }

    /**
     * @description generates invoice documents and saves them as files related to invoices
     *
     * @param invoiceIds ids of invoices to generate files for
     *
     * @return Map<Id, ContentVersion> map with invoice id as key, generated content version as value
     *
     * @author Magdalena Stanciu
     * @date 2022-10-10
     */
    public static Map<Id, ContentVersion> generateInvoiceDocuments(Set<Id> invoiceIds) {
        Map<Id, ContentVersion> contentVersionsByInvoiceId = FileGenerationService.generateDocuments(
            FileGenerationService.documentType.INVOICE, invoiceIds
        );
        return contentVersionsByInvoiceId;
    }

    /**
     * @description send invoice documents via email
     *
     * @param invoices map of invoices to send documents for via email
     * @param contentVersionsByInvoiceId map with invoice ids as keys and generated invoice documents as values
     *
     * @author Magdalena Stanciu
     * @date 2022-10-10
     */
    public static void sendInvoiceDocumentsViaEmail(Map<Id, aforza__Invoice__c> invoices, Map<Id, ContentVersion> contentVersionsByInvoiceId) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Id invoiceId : invoices.keySet()) {
            aforza__Invoice__c invoice = invoices.get(invoiceId);
            ContentVersion invoiceDocument = contentVersionsByInvoiceId.get(invoice.Id);
            Messaging.SingleEmailMessage message = EmailService.buildEmailMessage(
                INVOICE_EMAIL_TEMPLATE_ID,
                false,
                true,
                invoice.Id,
                invoice?.aforza__Account__r?.aforza__Primary_Contact__c,
                new List<String>{
                    invoice?.aforza__Account__r?.aforza__Invoice_Email_Address__c
                },
                new List<String>{
                    invoiceDocument?.Id
                }
            );
            emails.add(message);
        }
        Messaging.sendEmail(emails);
    }
}