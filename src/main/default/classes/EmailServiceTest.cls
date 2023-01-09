/**
 * Created by magdalena.stanciu on 11.10.2022.
 */

@IsTest
private with sharing class EmailServiceTest {

    @IsTest
    private static void testBuildEmailMessage() {
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );
        Contact newContact = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = dpAccount.Id, LastName = 'Test'));
        aforza__Invoice__c newInvoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(
                new aforza__Invoice__c(aforza__Account__c = dpAccount.Id)
        );

        Id emailTemplateId = [SELECT Id FROM EmailTemplate LIMIT 1].Id;

        Test.startTest();
        Messaging.SingleEmailMessage message = EmailService.buildEmailMessage(
                emailTemplateId,
                false,
                false,
                newInvoice.Id,
                newContact.Id,
                new List<String>{'test@test.com'},
                new List<String>()
        );
        Test.stopTest();

        System.assertEquals(emailTemplateId, message.getTemplateId());
        System.assertEquals(false, message.treatTargetObjectAsRecipient);
        System.assertEquals(false, message.saveAsActivity);
        System.assertEquals(newInvoice.Id, message.getWhatId());
        System.assertEquals(newContact.Id, message.getTargetObjectId());
        System.assertEquals(1, message.getToAddresses().size());
        System.assertEquals(0, message.getEntityAttachments().size());
        System.assertEquals(EmailService.ORG_WIDE_EMAIL_ADDRESS_ID, message.getOrgWideEmailAddressId());
    }
}