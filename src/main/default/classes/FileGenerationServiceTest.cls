/**
 * Created by magdalena.stanciu on 10.10.2022.
 */

@IsTest
public with sharing class FileGenerationServiceTest {
    @IsTest
    public static void testGenerateDocuments_ValidDocumentTypeInput() {
        // create product
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(
            new Product2(Name = 'Test Product', ProductCode = 'SKU1')
        );

        // add new product to standard PB
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add products to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                AccountStatus__c = 'Traders',
                aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID,
                AccountId = dpAccount.Id,
                Status = 'Draft',
                Pricebook2Id = newPricebook.Id
            )
        );
        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(
                OrderId = newOrder.Id,
                Product2Id = newProduct.Id,
                PricebookEntryId = newPricebookEntry.Id
            )
        );

        // create invoice with line items
        aforza__Invoice__c newInvoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(
            new aforza__Invoice__c(
                aforza__Account__c = dpAccount.Id,
                aforza__Order__c = newOrder.Id,
                aforza__Reference__c = '10'
            )
        );
        aforza__Invoice_Line_Item__c newInvoiceLineItem = (aforza__Invoice_Line_Item__c) TdfSObjectFactory.insertSObject(
            new aforza__Invoice_Line_Item__c(
                aforza__Invoice__c = newInvoice.Id,
                OrderProduct__c = newOrderItem.Id
            )
        );

        Test.startTest();
        FileGenerationService.generateDocuments(FileGenerationService.documentType.INVOICE, new Set<Id>{
            newInvoice.Id
        });
        Test.stopTest();

        List<ContentVersion> generatedFiles = [SELECT Id FROM ContentVersion WHERE DocumentType__c = 'Invoice'];
        System.assertEquals(1, generatedFiles.size(), 'The invoice file was not generated');

        List<ContentDocumentLink> linkedFiles = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :newInvoice.Id];
        System.assertEquals(1, linkedFiles.size(), 'The file was not related to the invoice');
    }

    @IsTest
    public static void testGenerateDocuments_InvalidDocumentTypeInput() {
        // create product
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product', ProductCode = 'SKU1'));

        // add new product to standard PB
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create pricebook and add products to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                AccountStatus__c = 'Traders',
                aforza__Default_Price_Book__c = newPricebook.Id
            )
        );

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID,
                AccountId = dpAccount.Id,
                Status = 'Draft',
                Pricebook2Id = newPricebook.Id
            )
        );
        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(
                OrderId = newOrder.Id,
                Product2Id = newProduct.Id,
                PricebookEntryId = newPricebookEntry.Id
            )
        );

        // create invoice with line items
        aforza__Invoice__c newInvoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(
            new aforza__Invoice__c(
                aforza__Account__c = dpAccount.Id,
                aforza__Order__c = newOrder.Id,
                aforza__Reference__c = '10'
            )
        );
        aforza__Invoice_Line_Item__c newInvoiceLineItem = (aforza__Invoice_Line_Item__c) TdfSObjectFactory.insertSObject(
            new aforza__Invoice_Line_Item__c(
                aforza__Invoice__c = newInvoice.Id,
                OrderProduct__c = newOrderItem.Id
            )
        );

        Test.startTest();
        try {
            FileGenerationService.generateDocuments(null, new Set<Id>{
                newInvoice.Id
            });
        } catch (FileGenerationService.FileGenerationException ex) {
            System.assertEquals('Invalid document type', ex.getMessage(), 'Incorrect error returned.');
        }
        Test.stopTest();
    }

    @IsTest
    public static void testGenerateContentVersion_Invoice() {
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );
        aforza__Invoice__c newInvoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(
            new aforza__Invoice__c(aforza__Account__c = dpAccount.Id)
        );
        aforza__Invoice__c insertedInvoice = [SELECT Id, aforza__Order__r.OrderNumber FROM aforza__Invoice__c WHERE Id = :newInvoice.Id];

        Test.startTest();
        ContentVersion generatedFile = FileGenerationService.generateContentVersion(
            FileGenerationService.documentType.INVOICE,
            insertedInvoice
        );
        Test.stopTest();

        String expectedContentLocation = 'S';
        String expectedOrigin = 'C';
        String expectedFileOwner = UserInfo.getUserId();
        Blob expectedVersionData = FileGenerationService.getContentAsBlob(newInvoice.Id, Page.AGBarrInvoice);
        String expectedFileName = 'Invoice ' + insertedInvoice?.aforza__Order__r?.OrderNumber + ' ' + System.today().format() + '.pdf';
        String expectedDocumentType = 'Invoice';

        System.assertEquals(expectedContentLocation, generatedFile.ContentLocation);
        System.assertEquals(expectedOrigin, generatedFile.Origin);
        System.assertEquals(expectedFileOwner, generatedFile.OwnerId);
        System.assertEquals(expectedVersionData, generatedFile.VersionData);
        System.assertEquals(expectedFileName, generatedFile.PathOnClient);
        System.assertEquals(expectedFileName, generatedFile.Title);
        System.assertEquals(expectedDocumentType, generatedFile.DocumentType__c);
    }

    @IsTest
    public static void testGenerateContentVersion_DeliveryNote() {
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID)
        );
        Order insertedOrder = [SELECT Id, OrderNumber FROM Order WHERE Id = :newOrder.Id];

        Test.startTest();
        ContentVersion generatedFile = FileGenerationService.generateContentVersion(
            FileGenerationService.documentType.DELIVERY_NOTE,
            insertedOrder
        );
        Test.stopTest();

        String expectedContentLocation = 'S';
        String expectedOrigin = 'C';
        String expectedFileOwner = UserInfo.getUserId();
        Blob expectedVersionData = FileGenerationService.getContentAsBlob(newOrder.Id, Page.DeliveryNotePDF);
        String expectedFileName = 'Delivery Note ' + insertedOrder.get('OrderNumber') + ' ' + System.today().format() + '.pdf';
        String expectedDocumentType = 'Delivery Note';

        System.assertEquals(expectedContentLocation, generatedFile.ContentLocation);
        System.assertEquals(expectedOrigin, generatedFile.Origin);
        System.assertEquals(expectedFileOwner, generatedFile.OwnerId);
        System.assertEquals(expectedVersionData, generatedFile.VersionData);
        System.assertEquals(expectedFileName, generatedFile.PathOnClient);
        System.assertEquals(expectedFileName, generatedFile.Title);
        System.assertEquals(expectedDocumentType, generatedFile.DocumentType__c);
    }
}