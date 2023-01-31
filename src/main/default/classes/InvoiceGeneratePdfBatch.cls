/**
 * Created by svatopluk.sejkora on 27.01.2023.
 */

public with sharing class InvoiceGeneratePdfBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    private Set<Id> invoiceIds = new Set<Id>();

    public InvoiceGeneratePdfBatch(Set<Id> invoiceIds) {
        this.invoiceIds = invoiceIds;
    }

    public Iterable<SObject> start(Database.BatchableContext batchableContext) {
        Set<Id> bindInvoiceIds = this.invoiceIds;
        String query = 'SELECT Id FROM aforza__Invoice__c WHERE Id IN :bindInvoiceIds';
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext batchableContext, List<aforza__Invoice__c> invoices) {
        Set<Id> invoiceIdsRetrieved = new Set<Id>();
        for (aforza__Invoice__c invoice : invoices) {
            invoiceIdsRetrieved.add(invoice.Id);
        }
        InvoiceService.generateInvoiceDocumentSync(invoiceIdsRetrieved);
    }

    public void finish(Database.BatchableContext param1) {

    }
}