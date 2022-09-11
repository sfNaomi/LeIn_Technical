/**
 * Created by magdalena.stanciu on 03.09.2022.
 */

@IsTest
private with sharing class AccountTriggerHandlerTest {
    @IsTest
    private static void testPrimaryContactAutomation_InsertAccountWithPrimaryContact() {
        // create new contact to be set as primary
        Account primaryContactParentAccount = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Contact primaryContact  = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = primaryContactParentAccount.Id));

        // create new DP account and set primary contact
        Test.startTest();
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Primary_Contact__c = primaryContact.Id)
        );
        Test.stopTest();

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
    private static void testPrimaryContactAutomation_UpdateAccountPrimaryContact() {
        // create new contact to be set as primary
        Account primaryContactParentAccount = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Contact primaryContact  = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = primaryContactParentAccount.Id));

        // create new DP account
        Account testDPAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, Phone = '+404234234234', Email__c = 'test@test.com')
        );

        // update the primary contact of the DP account
        Test.startTest();
        testDPAccount.aforza__Primary_Contact__c = primaryContact.Id;
        update testDPAccount;
        Test.stopTest();

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
    private static void testPrimaryContactAutomation_RemovePrimaryContact() {
        // create new contact to be set as primary
        Account primaryContactParentAccount = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Contact primaryContact  = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = primaryContactParentAccount.Id));

        // create new DP account and set primary contact; update account by removing primary contact
        Test.startTest();
        // create new DP account and set primary contact
        Account testDPAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Primary_Contact__c = primaryContact.Id)
        );

        testDPAccount.aforza__Primary_Contact__c = null;
        update testDPAccount;
        Test.stopTest();

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

    @IsTest
    private static void testPrimaryContactAutomation_PrimaryContactMisingContactDetails() {
        // create new contact to be set as primary
        Account primaryContactParentAccount = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Contact primaryContact  = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = primaryContactParentAccount.Id, Phone = null, Email = null));

        // create new DP account and set primary contact
        Test.startTest();
        Account testDPAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Primary_Contact__c = primaryContact.Id)
        );
        Test.stopTest();

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