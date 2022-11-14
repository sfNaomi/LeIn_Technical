/**
 * Created by magdalena.stanciu on 10.11.2022.
 */

@IsTest
private class GeneratePdfButtonControllerTest {
    @IsTest
    private static void testAttachPdf_DeliveryNote() {
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                AccountStatus__c = 'Traders',
                InvoiceType__c = 'Email',
                DeliveryNoteEmail__c = 'test@test.com'
            )
        );

        Contact newContact = (Contact) TdfSObjectFactory.insertSObject(
            new Contact(AccountId = dpAccount.Id, Email = 'test@test.com')
        );

        dpAccount.aforza__Primary_Contact__c = newContact.Id;
        update dpAccount;

        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(AccountId = dpAccount.Id, RecordTypeId = RecordTypes.ORDER_TELESALES_ID)
        );

        Test.startTest();
        GeneratePdfButtonController.attachPdf(newOrder.Id);
        Test.stopTest();

        List<ContentDocumentLink> relatedFiles = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :newOrder.Id];
        Assert.areEqual(1, relatedFiles.size());
    }

    @IsTest
    private static void testAttachPdf_Invoice() {
        aforza__Invoice__c newInvoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(new aforza__Invoice__c());

        Test.startTest();
        GeneratePdfButtonController.attachPdf(newInvoice.Id);
        Test.stopTest();

        List<ContentDocumentLink> relatedFiles = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :newInvoice.Id];
        Assert.areEqual(1, relatedFiles.size());
    }
}