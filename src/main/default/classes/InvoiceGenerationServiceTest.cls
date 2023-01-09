/**
 * Created by magdalena.stanciu on 10.11.2022.
 */

@IsTest
private class InvoiceGenerationServiceTest {
    @IsTest
    static void testConstructor() {
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
        );
        aforza__Invoice__c newInvoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(
            new aforza__Invoice__c(aforza__Account__c = dpAccount.Id, aforza__Order__c = newOrder.Id, aforza__Reference__c = '10')
        );
        TdfSObjectFactory.insertSObject(
            new aforza__Invoice_Line_Item__c(aforza__Invoice__c = newInvoice.Id)
        );
        ContentVersion signature = (ContentVersion) TdfSObjectFactory.insertSObject(
            new ContentVersion(Title = 'Signature Test', PathOnClient = 'Test', VersionData = EncodingUtil.base64Decode('Body'))
        );
        String signatureDocId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :signature.Id].ContentDocumentId;
        TdfSObjectFactory.insertSObject(
            new ContentDocumentLink(ContentDocumentId = signatureDocId, LinkedEntityId = newOrder.Id, ShareType = 'V')
        );

        Test.startTest();
        InvoiceGenerationService service = new InvoiceGenerationService(new List<String>{newInvoice.Id});
        Test.stopTest();

        Assert.areEqual(1, InvoiceGenerationService.retrievedInvoices.size());
        Assert.areEqual(1, InvoiceGenerationService.orderIdSignatureDocumentId.size());
    }

    @IsTest
    static void testGenerateData() {
        // create product
        Product2 newProduct1 = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        Product2 newProduct2 = (Product2) TdfSObjectFactory.insertSObject(new Product2());

        // add new product to standard PB
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct1.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );
        TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct2.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
        );

        // create custom pricebook and add product to pricebook
        Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
        PricebookEntry product1PricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct1.Id, Pricebook2Id = newPricebook.Id, aforza__Tax_Percent__c = 10)
        );
        PricebookEntry product2PricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
            new PricebookEntry(Product2Id = newProduct2.Id, Pricebook2Id = newPricebook.Id, aforza__Tax_Percent__c = 15)
        );

        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
            aforza__Default_Price_Book__c = newPricebook.Id,
            RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
            PrimaryGridNumber__c = '3C7201MOW',
            PaymentTerms__c = 'STD',
            aforza__Credit_Amount__c = 200
        ));

        // create orders and add products to it
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(
            RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
            AccountId = dpAccount.Id,
            Grid__c = '3C7201MOW',
            Pricebook2Id = newPricebook.Id
        ));
        TdfSObjectFactory.insertSObject(new OrderItem(
            OrderId = newOrder.Id,
            Product2Id = newProduct1.Id,
            Quantity = 10,
            PricebookEntryId = product1PricebookEntry.Id
        ));
        TdfSObjectFactory.insertSObject(new OrderItem(
            OrderId = newOrder.Id,
            Product2Id = newProduct2.Id,
            Quantity = 10,
            PricebookEntryId = product2PricebookEntry.Id
        ));

        // mark order as receipted
        newOrder.Status = 'Receipted';
        update newOrder;

        Order updatedOrder = [SELECT Id, Invoice__c FROM Order WHERE Id = :newOrder.Id];

        Test.startTest();
        InvoiceGenerationService service = new InvoiceGenerationService(new List<String>{updatedOrder.Invoice__c});
        List<InvoiceGenerationService.Invoice> generatedInvoices = service.generateData();
        Test.stopTest();

        aforza__Invoice__c existingInvoice = [
            SELECT
                Id, Name, CreatedDate, PaymentTerms__c, aforza__Due_Date__c, PoNumber__c, PaymentInstruction__c, PrintName__c,
                aforza__Order__c, aforza__Order__r.OrderNumber, CustomerShopNumber__c, NetTotal__c, Vat__c, Gross__c, DiscountTotal__c,
                DpReference__c, DpName__c, DpAddress__c, DpArea__c, DpTown__c, DpCountry__c, DpPostCode__c,
                BillToReference__c, BillToName__c, BillToAddress__c, BillToArea__c, BillToTown__c, BillToCountry__c, BillToPostCode__c,
                (
                    SELECT Id, SkuCode__c, SkuName__c, Quantity__c, UnitPrice__c, VatRate__c, Vat__c, NetPrice__c
                    FROM aforza__Billing_Statement_Line_Items__r
                    WHERE SkuName__c != 'Tax' AND SkuName__c != 'Discount'
                )
            FROM aforza__Invoice__c
            WHERE Id = :updatedOrder.Invoice__c
        ];

        // results
        Assert.areEqual(1, generatedInvoices.size());

        Assert.areEqual(existingInvoice.BillToName__c, generatedInvoices[0].billToName);
        Assert.areEqual(existingInvoice.BillToReference__c, generatedInvoices[0].billToReference);
        Assert.areEqual(existingInvoice.BillToCountry__c, generatedInvoices[0].billToCountry);
        Assert.areEqual(existingInvoice.BillToAddress__c, generatedInvoices[0].billToStreet);
        Assert.areEqual(existingInvoice.BillToArea__c, generatedInvoices[0].billToState);
        Assert.areEqual(existingInvoice.BillToTown__c, generatedInvoices[0].billToCity);
        Assert.areEqual(existingInvoice.BillToPostcode__c, generatedInvoices[0].billToPostalCode);

        Assert.areEqual(existingInvoice.DpName__c, generatedInvoices[0].shipToName);
        Assert.areEqual(existingInvoice.DpReference__c, generatedInvoices[0].shipToReference);
        Assert.areEqual(existingInvoice.DpCountry__c, generatedInvoices[0].shipToCountry);
        Assert.areEqual(existingInvoice.DpAddress__c, generatedInvoices[0].shipToStreet);
        Assert.areEqual(existingInvoice.DpArea__c, generatedInvoices[0].shipToState);
        Assert.areEqual(existingInvoice.DpTown__c, generatedInvoices[0].shipToCity);
        Assert.areEqual(existingInvoice.DpPostcode__c, generatedInvoices[0].shipToPostalCode);

        Assert.areEqual(existingInvoice.aforza__Order__r.OrderNumber, generatedInvoices[0].invoiceNumber);
        Assert.areEqual(existingInvoice.CreatedDate, generatedInvoices[0].createdDate);
        Assert.areEqual(existingInvoice.aforza__Due_Date__c, generatedInvoices[0].dueDate);
        Assert.areEqual(existingInvoice.PoNumber__c, generatedInvoices[0].poNumber);
        Assert.areEqual(existingInvoice.CustomerShopNumber__c, generatedInvoices[0].customerShopNumber);
        Assert.areEqual(existingInvoice.PaymentInstruction__c, generatedInvoices[0].paymentMethod);
        Assert.areEqual(existingInvoice.PaymentTerms__c, generatedInvoices[0].paymentTerms);
        Assert.areEqual(existingInvoice.PrintName__c, generatedInvoices[0].printName);

        Assert.areEqual(existingInvoice.NetTotal__c, generatedInvoices[0].netValue);
        Assert.areEqual(existingInvoice.Vat__c, generatedInvoices[0].vatValue);
        Assert.areEqual(existingInvoice.DiscountTotal__c, generatedInvoices[0].discountTotal);
        Assert.areEqual(existingInvoice.Gross__c, generatedInvoices[0].total);
    }
}