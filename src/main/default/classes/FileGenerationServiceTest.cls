/**
 * Created by magdalena.stanciu on 10.10.2022.
 */

@IsTest
private with sharing class FileGenerationServiceTest {
    @IsTest
    private static void testGenerateDocuments_ValidDocumentTypeInput() {
        // create product
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());

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
        Assert.areEqual(1, generatedFiles.size(), 'The invoice file was not generated');

        List<ContentDocumentLink> linkedFiles = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :newInvoice.Id];
        Assert.areEqual(1, linkedFiles.size(), 'The file was not related to the invoice');
    }

    @IsTest
    private static void testGenerateDocuments_InvalidDocumentTypeInput() {
        // create product
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2());

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
            Assert.isTrue(false, 'Expecting error to be thrown.');
        } catch (FileGenerationService.FileGenerationException ex) {
            Assert.areEqual('Invalid document type', ex.getMessage(), 'Incorrect error returned.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testGenerateContentVersion_Invoice() {
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );
        Contact newContact = (Contact) TdfSObjectFactory.insertSObject(
            new Contact(AccountId = dpAccount.Id, Email = 'test@test.com')
        );

        dpAccount.aforza__Primary_Contact__c = newContact.Id;
        update dpAccount;

        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id)
        );
        
        aforza__Invoice__c newInvoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(
            new aforza__Invoice__c(aforza__Account__c = dpAccount.Id, aforza__Order__c = newOrder.Id)
        );
        aforza__Invoice__c insertedInvoice = [SELECT Id, Name, InvoiceType__c, aforza__Order__r.OrderNumber FROM aforza__Invoice__c WHERE Id = :newInvoice.Id];

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

        Assert.areEqual(expectedContentLocation, generatedFile.ContentLocation);
        Assert.areEqual(expectedOrigin, generatedFile.Origin);
        Assert.areEqual(expectedFileOwner, generatedFile.OwnerId);
        Assert.areEqual(expectedVersionData, generatedFile.VersionData);
        Assert.areEqual(expectedFileName, generatedFile.PathOnClient);
        Assert.areEqual(expectedFileName, generatedFile.Title);
        Assert.areEqual(expectedDocumentType, generatedFile.DocumentType__c);
    }

    @IsTest
    private static void testGenerateContentVersion_CreditNote() {
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );
        Contact newContact = (Contact) TdfSObjectFactory.insertSObject(
            new Contact(AccountId = dpAccount.Id, Email = 'test@test.com')
        );

        dpAccount.aforza__Primary_Contact__c = newContact.Id;
        update dpAccount;

        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id)
        );

        aforza__Invoice__c newInvoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(
            new aforza__Invoice__c(aforza__Account__c = dpAccount.Id, aforza__Order__c = newOrder.Id, InvoiceType__c = 'Credit Note')
        );
        aforza__Invoice__c insertedInvoice = [SELECT Id, Name, InvoiceType__c, aforza__Order__r.OrderNumber FROM aforza__Invoice__c WHERE Id = :newInvoice.Id];

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
        String expectedFileName = 'Credit Note ' + insertedInvoice?.aforza__Order__r?.OrderNumber + ' ' + System.today().format() + '.pdf';
        String expectedDocumentType = 'Credit Note';

        Assert.areEqual(expectedContentLocation, generatedFile.ContentLocation);
        Assert.areEqual(expectedOrigin, generatedFile.Origin);
        Assert.areEqual(expectedFileOwner, generatedFile.OwnerId);
        Assert.areEqual(expectedVersionData, generatedFile.VersionData);
        Assert.areEqual(expectedFileName, generatedFile.PathOnClient);
        Assert.areEqual(expectedFileName, generatedFile.Title);
        Assert.areEqual(expectedDocumentType, generatedFile.DocumentType__c);
    }

    @IsTest
    private static void testGenerateContentVersion_DeliveryNote() {
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

        Assert.areEqual(expectedContentLocation, generatedFile.ContentLocation);
        Assert.areEqual(expectedOrigin, generatedFile.Origin);
        Assert.areEqual(expectedFileOwner, generatedFile.OwnerId);
        Assert.areEqual(expectedVersionData, generatedFile.VersionData);
        Assert.areEqual(expectedFileName, generatedFile.PathOnClient);
        Assert.areEqual(expectedFileName, generatedFile.Title);
        Assert.areEqual(expectedDocumentType, generatedFile.DocumentType__c);
    }
}