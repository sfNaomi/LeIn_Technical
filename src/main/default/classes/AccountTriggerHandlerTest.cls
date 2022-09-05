/**
 * Created by magdalena.stanciu on 03.09.2022.
 */

@IsTest
public with sharing class AccountTriggerHandlerTest {
    @IsTest
    public static void testPrimaryContactAutomation_InsertAccountWithPrimaryContact() {
        Id outletRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Outlet').getRecordTypeId();

        // create new contact to be set as primary
        Account primaryContactParentAccount = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = outletRTId));
        Contact primaryContact  = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = primaryContactParentAccount.Id));

        // create new DP account and set primary contact
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = outletRTId, aforza__Primary_Contact__c = primaryContact.Id)
        );

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

    @IsTest
    public static void testPrimaryContactAutomation_UpdateAccountPrimaryContact() {
        Id outletRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Outlet').getRecordTypeId();

        // create new contact to be set as primary
        Account primaryContactParentAccount = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = outletRTId));
        Contact primaryContact  = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = primaryContactParentAccount.Id));

        // create new DP account and set primary contact
        Account testDPAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = outletRTId, Phone = '+404234234234', Email__c = 'test@test.com')
        );

        // update the primary contact of the DP account
        testDPAccount.aforza__Primary_Contact__c = primaryContact.Id;
        update testDPAccount;

        // retrieve updated account
        Account updatedDPAccount = [
                SELECT Id, Phone, Email__c
                FROM Account
                WHERE Id = :testDPAccount.Id
        ];

        // check results
        System.assertEquals(primaryContact.Phone, updatedDPAccount.Phone, 'Expecting a different phone number.');
        System.assertEquals(primaryContact.Email, updatedDPAccount.Email__c, 'Expecting a different email.');
    }

    @IsTest
    public static void testPrimaryContactAutomation_RemovePrimaryContact() {
        Id outletRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Outlet').getRecordTypeId();

        // create new contact to be set as primary
        Account primaryContactParentAccount = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = outletRTId));
        Contact primaryContact  = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = primaryContactParentAccount.Id));

        // create new DP account and set primary contact
        Account testDPAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = outletRTId, aforza__Primary_Contact__c = primaryContact.Id)
        );

        // update the primary contact of the DP account
        testDPAccount.aforza__Primary_Contact__c = null;
        update testDPAccount;

        // retrieve updated account
        Account updatedDPAccount = [
                SELECT Id, Phone, Email__c
                FROM Account
                WHERE Id = :testDPAccount.Id
        ];

        // check results
        System.assertEquals(null, updatedDPAccount.Phone, 'Expecting a different phone number.');
        System.assertEquals(null, updatedDPAccount.Email__c, 'Expecting a different email.');
    }
}