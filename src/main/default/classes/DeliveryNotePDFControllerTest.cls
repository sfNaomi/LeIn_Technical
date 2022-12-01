@IsTest
private with sharing class DeliveryNotePDFControllerTest {
    @IsTest
    private static void testDeliveryNotePDFController() {
        // create account
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
            new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
        );
        TdfSObjectFactory.insertSObject(new OrderItem(OrderId = newOrder.Id));

        Test.startTest();
        PageReference testPage = Page.DeliveryNotePDF;
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('p', newOrder.Id);
        DeliveryNotePDFController ctrl = new DeliveryNotePDFController();
        Test.stopTest();

        Assert.areEqual(1, ctrl.mapIdOrder.size());
    }
}