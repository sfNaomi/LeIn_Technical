/**
 * Created by svatopluk.sejkora on 21.11.2022.
 *
 * Class to held logic that will determine if the email with invoice should be send to the customer. This class is not
 * responsible for determining correct context and time. It will evaluate existing criteria, not the fact if the email was sent or not.
 * if the invoice Id is passed two times from different context and conditions are valid, 2 emails will be send.
 *
 * the class is without sharing to allow obtaining all needed information to determine conditions regardless of the access
 * of the triggering user
 */

public without sharing class InvoiceEmailService {
    private static final Set<String> NO_INVOICE_PAYMENT_METHODS = new Set<String>{'Cash', 'Cheque'};
    private static final Set<String> TO_INVOICE_PAYMENT_METHODS = new Set<String>{'Direct Debit', 'Bacs', 'JDE DD'};
    private static final String CARD_PAYMENT_METHOD = 'Card Payment';

    private static final String TYPE_CREDIT_NOTE = 'Credit Note';
    private static final String TYPE_INVOICE = 'Invoice';

    @TestVisible private static final String CREDIT_NOTE_EMAIL_NAME = 'AGBarrCreditNoteEmailTemplate';
    @TestVisible private static final String INVOICE_EMAIL_NO_PAYMENT_NAME = 'AGBarrInvoiceEmailTemplate';
    @TestVisible private static final String INVOICE_EMAIL_WITH_PAYMENT_NAME = 'AGBarrInvoiceEmailTemplateWithPaymentLink';

    private static final String ORDER_RECORD_TYPE_JDE = 'StraightToJDEOrder';

    private static final Map<String, Id> INVOICE_EMAIL_TEMPLATES {
        get {
            if (INVOICE_EMAIL_TEMPLATES == null) {
                INVOICE_EMAIL_TEMPLATES = getEmailTemplatesIds();
            }
            return INVOICE_EMAIL_TEMPLATES;
        }
        set;
    }

    /**
     * @description process invoice Ids to send their invoice documents to customers
     *
     * @param invoiceIds invoice Ids to process email sending for
     *
     * @author Svata Sejkora
     * @date 2022-11-21
     */
    public static void sendInvoiceToCustomers(Set<Id> invoiceIds) {
        // obtain invoices with needed data for the evaluation
        List<aforza__Invoice__c> invoicesWithData = getInvoicesWithRequiredParameters(invoiceIds);
        // run a test for each invoice what kind of email and if needs to be ran
        Map<Id, String> invoiceIdsToEmailTemplate = evaluateInvoiceIfToSendInvoice(invoicesWithData);
        if (invoiceIdsToEmailTemplate.size() > 0) {
            // obtain Invoice PDFs for selected items
            Map<Id, ContentVersion> invoicesToFiles = fetchInvoiceDocumentsToSend(invoiceIdsToEmailTemplate.keySet());
            // send the emails
            sendInvoiceDocumentsViaEmail(invoicesWithData, invoiceIdsToEmailTemplate, invoicesToFiles);
            updateInvoicesWithSend(invoicesWithData);
        }
    }

    private static void updateInvoicesWithSend(List<aforza__Invoice__c> invoices) {
        for (aforza__Invoice__c invoice : invoices) {
            invoice.InvoiceSentToCustomer__c = true;
        }
        update invoices;
    }

    /**
     * @description Obtain latest invoices linked to invoice document
     *
     * @param invoicesWithData list of invoices with relevant data
     * @return Map of the invoice ID and template developer name to be used
     *
     * @author Svata Sejkora
     * @date 2022-11-21
     */
    @TestVisible
    private static Map<Id, String> evaluateInvoiceIfToSendInvoice(List<aforza__Invoice__c> invoicesWithData) {
        Map<Id, String> invoiceIdsToEmailTemplate = new Map<Id, String>();
        for (aforza__Invoice__c invoice : invoicesWithData) {
            // check that pre-requisites for sending out the email
            // (there is an email address to send the invoice to and there is a primary contact on
            //  the account to be used as target object id for the template based email)
            if (invoice.aforza__Account__r.aforza__Invoice_Email_Address__c == null ||
                invoice.aforza__Account__r.aforza__Primary_Contact__c == null) {
                continue;
            }

            // check if the invoice record is an actual invoice or credit note
            // credit notes are sent if there is an email address on account
            // invoices are send depending on the payment method -> multiple use cases
            if (invoice.InvoiceType__c == TYPE_CREDIT_NOTE) {
                invoiceIdsToEmailTemplate.put(invoice.Id, CREDIT_NOTE_EMAIL_NAME);
                continue;
            }

            // DD, Bacs & JDE DD payment types -> send invoice if invoice type on account is set to email
            // second condition is to check for Card Payment, and there are two options in it
            // we expect only one of the scenarios to be active
            if (TO_INVOICE_PAYMENT_METHODS.contains(invoice.aforza__Order__r.PaymentMethod__c) &&
                invoice.aforza__Account__r.InvoiceType__c == 'Email') {
                invoiceIdsToEmailTemplate.put(invoice.Id, INVOICE_EMAIL_NO_PAYMENT_NAME);
                continue;
            }

            if (invoice.aforza__Order__r.PaymentMethod__c == CARD_PAYMENT_METHOD) {
                // check if it is pre auth from order or not
                if (invoice.aforza__Order__r.PreAuthCaptured__c == false && String.isNotEmpty(invoice.PaymentLink__c)) {
                    invoiceIdsToEmailTemplate.put(invoice.Id, INVOICE_EMAIL_WITH_PAYMENT_NAME);
                    // if pre auth from Order, it needs to be set to Invoice Type Email for us to send it
                } else if (invoice.aforza__Order__r.PreAuthCaptured__c == true && invoice.aforza__Account__r.InvoiceType__c == 'Email') {
                    invoiceIdsToEmailTemplate.put(invoice.Id, INVOICE_EMAIL_NO_PAYMENT_NAME);
                    // send email for StraightToJDEOrder
                } else if (invoice.aforza__Order__r.RecordType.DeveloperName == ORDER_RECORD_TYPE_JDE) {
                    invoiceIdsToEmailTemplate.put(invoice.Id, INVOICE_EMAIL_NO_PAYMENT_NAME);
                }
            }
        }

        return invoiceIdsToEmailTemplate;
    }


    /**
     * @description method to obtain needed fields for checks and data of invoice from all linked objects
     *
     * @param invoiceIds list of invoices for which we should get the invoice documents
     * @return Lists of invoices to work with
     *
     * @author Svata Sejkora
     * @date 2022-11-21
     */
    @TestVisible
    private static List<aforza__Invoice__c> getInvoicesWithRequiredParameters(Set<Id> invoiceIds) {
        return [
            SELECT Id, aforza__Order__r.PreAuthCaptured__c, InvoiceType__c,
                aforza__Order__r.RecordType.DeveloperName, Gross__c, aforza__Account__r.aforza__Primary_Contact__c,
                aforza__Account__c, aforza__Order__c, aforza__Order__r.OrderNumber, aforza__Account__r.InvoiceType__c,
                aforza__Account__r.aforza__Invoice_Email_Address__c, aforza__Order__r.PaymentMethod__c,
                InvoiceSentToCustomer__c, PaymentLink__c
            FROM aforza__Invoice__c
            WHERE Id IN :invoiceIds
        ];
    }

    /**
     * @description Obtain latest invoices/credit notes linked to invoice document
     *
     * @param invoiceIds list of invoices for which we should get the invoice documents
     * @return Map if the invoiceId to its latest invoice
     *
     * @author Svata Sejkora
     * @date 2022-11-21
     */
    private static Map<Id, ContentVersion> fetchInvoiceDocumentsToSend(Set<Id> invoiceIds) {
        Map<Id, Set<Id>> entityToContentDocuments = fetchContentDocumentLinks(invoiceIds);
        Set<String> docTypesToQuery = new Set<String>{TYPE_INVOICE, TYPE_CREDIT_NOTE};

        Map<Id, ContentVersion> invoicesToTheirFiles = new Map<Id, ContentVersion>();
        // get contentVersion for files
        for (ContentVersion version : [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId IN :entityToContentDocuments.keySet()
            AND ContentVersion.IsLatest = TRUE
            AND DocumentType__c IN :docTypesToQuery
            ORDER BY CreatedDate ASC
        ]) {
            for (Id linkedEntity : entityToContentDocuments.get(version.ContentDocumentId)) {
                invoicesToTheirFiles.put(linkedEntity, version);
            }
        }

        return invoicesToTheirFiles;
    }

    /**
     * @description obtain the links of documents for the invoice. Outcome will be used to get content versions
     *
     * @param invoiceIds list of invoices to get documents for
     * @return Map with content document id to linked entity
     *
     * @author Svata Sejkora
     * @date 2022-11-21
     */
    private static Map<Id, Set<Id>> fetchContentDocumentLinks(Set<Id> invoiceIds) {
        // get all documents attached to relevant Ids
        Map<Id, Set<Id>> entityToContentDocuments = new Map<Id, Set<Id>>();
        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :invoiceIds
        ];
        for (ContentDocumentLink link : contentDocumentLinks) {
            if (entityToContentDocuments.containsKey(link.ContentDocumentId)) {
                entityToContentDocuments.get(link.ContentDocumentId).add(link.LinkedEntityId);
            } else {
                entityToContentDocuments.put(link.ContentDocumentId, new Set<Id>{link.LinkedEntityId});
            }
        }
        return entityToContentDocuments;
    }

    /**
     * @description method to prepare email, set email template and facilitate sending of the email.
     *
     * @param invoices list of invoices for which the email should be sent
     * @param invoiceIdsToEmailTemplate - email template name for each invoice
     * @param contentVersionsByInvoiceId map with invoice ids as keys and generated invoice documents as values
     *
     * @author Svata Sejkora
     * @date 2022-11-21
     */
    private static void sendInvoiceDocumentsViaEmail(List<aforza__Invoice__c> invoices, Map<Id, String> invoiceIdsToEmailTemplate, Map<Id, ContentVersion> contentVersionsByInvoiceId) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (aforza__Invoice__c invoice : invoices) {
            ContentVersion invoiceDocument = contentVersionsByInvoiceId.get(invoice.Id);
            Id templateId = INVOICE_EMAIL_TEMPLATES?.get(invoiceIdsToEmailTemplate.get(invoice.Id));
            Messaging.SingleEmailMessage message = EmailService.buildEmailMessage(
                templateId,
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
        EmailService.send(emails);
    }

    /**
     * @description method to obtain email templates Ids
     *
     * @return map with Email unique name and its Id
     *
     * @author Svata Sejkora
     * @date 2022-11-21
     */
    private static Map<String, Id> getEmailTemplatesIds() {
        Map<String, Id> emailTemplateNameToId = new Map<String, Id>();
        for (EmailTemplate emailTemplate : [
            SELECT Id,DeveloperName
            FROM EmailTemplate
            WHERE DeveloperName = :INVOICE_EMAIL_NO_PAYMENT_NAME
            OR DeveloperName = :INVOICE_EMAIL_WITH_PAYMENT_NAME
            OR DeveloperName = :CREDIT_NOTE_EMAIL_NAME
        ]) {
            emailTemplateNameToId.put(emailTemplate.DeveloperName, emailTemplate.Id);
        }
        return emailTemplateNameToId;
    }
}