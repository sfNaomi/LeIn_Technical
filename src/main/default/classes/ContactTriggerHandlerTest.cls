/**
 * Created by magdalena.stanciu on 05.09.2022.
 */

@IsTest
public with sharing class ContactTriggerHandlerTest {
    @IsTest
    public static void testPrimaryContactAutomation_UpdateContactDetailsForPrimaryContact() {
        Id outletRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Outlet').getRecordTypeId();

        // create new contact to be set as primary
        Account primaryContactParentAccount = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = outletRTId));
        Contact primaryContact = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = primaryContactParentAccount.Id));

        // create new DP account and set primary contact
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = outletRTId, aforza__Primary_Contact__c = primaryContact.Id)
        );

        // update contact details
        primaryContact.Email = 'newemail@test.com';
        primaryContact.Phone = '+4043423423423424';
        update primaryContact;

        // retrieve updated account
        Account updatedDPAccount = [
                SELECT Id, Phone, Email__c
                FROM Account
                WHERE Id = :dpAccount.Id
        ];

        // check results
        System.assertEquals(primaryContact.Phone, updatedDPAccount.Phone, 'Expecting a different phone number.');
        System.assertEquals(primaryContact.Email, updatedDPAccount.Email__c, 'Expecting a different email.');
    }
}