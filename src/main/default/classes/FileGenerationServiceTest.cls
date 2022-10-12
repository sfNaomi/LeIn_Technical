/**
 * Created by magdalena.stanciu on 10.10.2022.
 */

@IsTest
public with sharing class FileGenerationServiceTest {
    @IsTest
    public static void testGenerateDocuments_Invoice() {
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );

        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product'));

        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
                new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
        );
        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
                new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id)
        );

        aforza__Invoice__c newInvoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(
                new aforza__Invoice__c(aforza__Account__c = dpAccount.Id, aforza__Order__c = newOrder.Id, aforza__Reference__c = '10')
        );
        aforza__Invoice_Line_Item__c newInvoiceLineItem = (aforza__Invoice_Line_Item__c) TdfSObjectFactory.insertSObject(
                new aforza__Invoice_Line_Item__c(aforza__Invoice__c = newInvoice.Id)
        );

        Test.startTest();
        FileGenerationService.generateDocuments(FileGenerationService.DocumentType.INVOICE, new Set<Id>{newInvoice.Id});
        Test.stopTest();

        List<ContentVersion> generatedFiles = [SELECT Id FROM ContentVersion WHERE DocumentType__c = 'Invoice'];
        System.assertEquals(1, generatedFiles.size(), 'The invoice file was not generated');

        List<ContentDocumentLink> linkedFiles = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :newInvoice.Id];
        System.assertEquals(1, linkedFiles.size(), 'The file was not related to the invoice');
    }

    @IsTest
    public static void testGenerateDocuments_InvalidInput() {
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );

        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product'));

        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
                new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
        );
        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
                new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id)
        );

        aforza__Invoice__c newInvoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(
                new aforza__Invoice__c(aforza__Account__c = dpAccount.Id, aforza__Order__c = newOrder.Id, aforza__Reference__c = '10')
        );
        aforza__Invoice_Line_Item__c newInvoiceLineItem = (aforza__Invoice_Line_Item__c) TdfSObjectFactory.insertSObject(
                new aforza__Invoice_Line_Item__c(aforza__Invoice__c = newInvoice.Id)
        );

        Test.startTest();
        try {
            FileGenerationService.generateDocuments(null, new Set<Id>{newInvoice.Id});
        } catch (FileGenerationService.FileGenerationException ex) {
            System.assertEquals('Invalid document type', ex.getMessage(), 'Incorrect error returned.');
        }
        Test.stopTest();
    }

    @IsTest
    public static void testGenerateContentVersion() {
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );
        aforza__Invoice__c newInvoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(
                new aforza__Invoice__c(aforza__Account__c = dpAccount.Id)
        );
        aforza__Invoice__c insertedInvoice = [SELECT Id, Name FROM aforza__Invoice__c WHERE Id = :newInvoice.Id];

        Test.startTest();
        ContentVersion generatedFile = FileGenerationService.generateContentVersion(
                FileGenerationService.DocumentType.INVOICE,
                insertedInvoice
        );
        Test.stopTest();

        System.assertEquals('S', generatedFile.ContentLocation);
        System.assertEquals('C', generatedFile.Origin);
        System.assertEquals(UserInfo.getUserId(), generatedFile.OwnerId);
        System.assertEquals(FileGenerationService.getContentAsBlob(newInvoice.Id, Page.AGBarrInvoice), generatedFile.VersionData);
        System.assertEquals('Invoice ' + insertedInvoice.get('Name') + ' ' + System.today().format() + '.pdf', generatedFile.PathOnClient);
        System.assertEquals('Invoice ' + insertedInvoice.get('Name') + ' ' + System.today().format() + '.pdf', generatedFile.Title);
        System.assertEquals('Invoice', generatedFile.DocumentType__c);
    }
}