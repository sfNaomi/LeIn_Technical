/**
 * Created by magdalena.stanciu on 09.11.2022.
 */

public with sharing class GeneratePdfButtonController {
    @AuraEnabled
    public static void attachPdf(Id recordId) {
        try {
            String sObjName = DescriptionSobjectService.getSObjectName(recordId);

            switch on sObjName {
                when 'aforza__Invoice__c' {
                    InvoiceService.generateInvoiceDocuments(new Set<Id>{recordId});
                }
                when 'Order' {
                    DeliveryNoteService.generateOrderAttachmentsAndSendDeliveryEmails(new Set<Id>{recordId});
                }
            }
        } catch (Exception e) {
            throw PopulateAuraHandledException.newMessageException(e.getMessage());
        }
    }
}