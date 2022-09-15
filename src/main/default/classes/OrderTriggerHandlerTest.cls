/**
 * Created by magdalena.stanciu on 14.09.2022.
 */

@IsTest
private with sharing class OrderTriggerHandlerTest {
    @IsTest
    private static void testActiveProspectAccountNewFieldDirectOrder() {
        // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                AccountStatus__c = 'Active Prospect'
        ));

        // create order
        Test.startTest();
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
                AccountId = dpAccount.Id
        ));
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
                SELECT Id, AccountStatus__c
                FROM Account
                WHERE Id = :dpAccount.Id
        ];

        // check results
        System.assertEquals('Traders', updatedDPAccount.AccountStatus__c, 'Expecting a different account status.');
    }

    @IsTest
    private static void testActiveTradersAccountNewFieldDirectOrder() {
        // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                AccountStatus__c = 'Traders'
        ));

        // create order
        Test.startTest();
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
                AccountId = dpAccount.Id
        ));
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
                SELECT Id, AccountStatus__c
                FROM Account
                WHERE Id = :dpAccount.Id
        ];

        // check results
        System.assertEquals('Traders', updatedDPAccount.AccountStatus__c, 'Expecting a different account status.');
    }

    @IsTest
    private static void testActiveActiveProspectAccountNewTelesalesOrder() {
        // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                AccountStatus__c = 'Active Prospect'
        ));

        // create order
        Test.startTest();
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID,
                AccountId = dpAccount.Id
        ));
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
                SELECT Id, AccountStatus__c
                FROM Account
                WHERE Id = :dpAccount.Id
        ];

        // check results
        System.assertEquals('Active Prospect', updatedDPAccount.AccountStatus__c, 'Expecting a different account status.');
    }

    @IsTest
    private static void testActiveTradersAccountNewTelesalesOrder() {
        // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                AccountStatus__c = 'Traders'
        ));

        // create order
        Test.startTest();
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(
                RecordTypeId = RecordTypes.ORDER_TELESALES_ID,
                AccountId = dpAccount.Id
        ));
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
                SELECT Id, AccountStatus__c
                FROM Account
                WHERE Id = :dpAccount.Id
        ];

        // check results
        System.assertEquals('Traders', updatedDPAccount.AccountStatus__c, 'Expecting a different account status.');
    }
}