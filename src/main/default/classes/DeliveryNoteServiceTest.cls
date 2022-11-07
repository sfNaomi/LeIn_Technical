@IsTest
private with sharing class DeliveryNoteServiceTest {
    @IsTest
    private static void testGenerateOrderAttachmentsAndSendDeliveryEmails() {
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

        // create order and add items to the order
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(
            new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID,
                AccountId = dpAccount.Id
            )
        );
        OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
            new OrderItem(
                OrderId = newOrder.Id
            )
        );

        Test.startTest();
        DeliveryNoteService.generateOrderAttachmentsAndSendDeliveryEmails(new Set<Id>{
            newOrder.Id
        });
        Test.stopTest();

        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :newOrder.Id];
        System.assert(!docLinks.isEmpty());

    }
}