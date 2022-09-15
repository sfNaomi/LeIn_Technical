/**
 * Created by magdalena.stanciu on 14.09.2022.
 */

@IsTest
private with sharing class AccountStatusUpdateBatchTest {
    @IsTest
    private static void testWeeklyFrequencyNoOrders() {
        // create new dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WEW',
                AccountStatus__c = 'Traders'
        ));

        // run batch to update account status
        Test.startTest();
        Database.executeBatch(new AccountStatusUpdateBatch());
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
    private static void testWeeklyFrequencyRecentOrders() {
        // create dp account and related order
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WEW',
                AccountStatus__c = 'Traders'
        ));
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
                AccountId = dpAccount.Id
        ));

        // run batch to update account status
        Test.startTest();
        Database.executeBatch(new AccountStatusUpdateBatch());
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
    private static void testWeeklyFrequencyOrderNoOrdersInLast5Weeks() {
        // create dp account and related order
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WEW',
                AccountStatus__c = 'Traders'
        ));
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
                AccountId = dpAccount.Id
        ));
        Test.setCreatedDate(newOrder.Id, System.Now().addDays(-(5*7+1)));

        // run batch to update account status
        Test.startTest();
        Database.executeBatch(new AccountStatusUpdateBatch());
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
                SELECT Id, AccountStatus__c
                FROM Account
                WHERE Id = :dpAccount.Id
        ];

        // check results
        System.assertEquals('At Risk', updatedDPAccount.AccountStatus__c, 'Expecting a different account status.');
    }

    @IsTest
    private static void testWeeklyFrequencyOrderNoOrdersInLast9Weeks() {
        // create dp account and related order
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WEW',
                AccountStatus__c = 'Traders'
        ));
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
                AccountId = dpAccount.Id
        ));
        Test.setCreatedDate(newOrder.Id, System.Now().addDays(-(9*7+1)));

        // run batch to update account status
        Test.startTest();
        Database.executeBatch(new AccountStatusUpdateBatch());
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
                SELECT Id, AccountStatus__c
                FROM Account
                WHERE Id = :dpAccount.Id
        ];

        // check results
        System.assertEquals('Win Back', updatedDPAccount.AccountStatus__c, 'Expecting a different account status.');
    }

    @IsTest
    private static void testWeeklyFrequencyOrderNoOrdersInLast13Weeks() {
        // create dp account and related order
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WEW',
                AccountStatus__c = 'Traders'
        ));
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
                AccountId = dpAccount.Id
        ));
        Test.setCreatedDate(newOrder.Id, System.Now().addDays(-(13*7+1)));

        // run batch to update account status
        Test.startTest();
        Database.executeBatch(new AccountStatusUpdateBatch());
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
                SELECT Id, AccountStatus__c
                FROM Account
                WHERE Id = :dpAccount.Id
        ];

        // check results
        System.assertEquals('Lapsed', updatedDPAccount.AccountStatus__c, 'Expecting a different account status.');
    }

    @IsTest
    private static void testFortnightlyFrequencyNoOrders() {
        // create new dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WE1',
                AccountStatus__c = 'Traders'
        ));

        // run batch to update account status
        Test.startTest();
        Database.executeBatch(new AccountStatusUpdateBatch());
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
    private static void testFortnightlyFrequencyRecentOrders() {
        // create dp account and related order
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WE1',
                AccountStatus__c = 'Traders'
        ));
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
                AccountId = dpAccount.Id
        ));

        // run batch to update account status
        Test.startTest();
        Database.executeBatch(new AccountStatusUpdateBatch());
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
    private static void testFortnightlyFrequencyOrderNoOrdersInLast10Weeks() {
        // create dp account and related order
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WE1',
                AccountStatus__c = 'Traders'
        ));
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
                AccountId = dpAccount.Id
        ));
        Test.setCreatedDate(newOrder.Id, System.Now().addDays(-(10*7+1)));

        // run batch to update account status
        Test.startTest();
        Database.executeBatch(new AccountStatusUpdateBatch());
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
                SELECT Id, AccountStatus__c
                FROM Account
                WHERE Id = :dpAccount.Id
        ];

        // check results
        System.assertEquals('At Risk', updatedDPAccount.AccountStatus__c, 'Expecting a different account status.');
    }

    @IsTest
    private static void testFortnightlyFrequencyOrderNoOrdersInLast18Weeks() {
        // create dp account and related order
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WE1',
                AccountStatus__c = 'Traders'
        ));
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
                AccountId = dpAccount.Id
        ));
        Test.setCreatedDate(newOrder.Id, System.Now().addDays(-(18*7+1)));

        // run batch to update account status
        Test.startTest();
        Database.executeBatch(new AccountStatusUpdateBatch());
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
                SELECT Id, AccountStatus__c
                FROM Account
                WHERE Id = :dpAccount.Id
        ];

        // check results
        System.assertEquals('Win Back', updatedDPAccount.AccountStatus__c, 'Expecting a different account status.');
    }

    @IsTest
    private static void testFortnightlyFrequencyOrderNoOrdersInLast26Weeks() {
        // create dp account and related order
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WE1',
                AccountStatus__c = 'Traders'
        ));
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
                AccountId = dpAccount.Id
        ));
        Test.setCreatedDate(newOrder.Id, System.Now().addDays(-(26*7+1)));

        // run batch to update account status
        Test.startTest();
        Database.executeBatch(new AccountStatusUpdateBatch());
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
                SELECT Id, AccountStatus__c
                FROM Account
                WHERE Id = :dpAccount.Id
        ];

        // check results
        System.assertEquals('Lapsed', updatedDPAccount.AccountStatus__c, 'Expecting a different account status.');
    }

    @IsTest
    private static void testMonthlyFrequencyRecentOrders() {
        // create dp account and related order
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WEM',
                AccountStatus__c = 'Traders'
        ));
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
                AccountId = dpAccount.Id
        ));

        // run batch to update account status
        Test.startTest();
        Database.executeBatch(new AccountStatusUpdateBatch());
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
    private static void testMonthlyFrequencyOrderNoOrdersInLast20Weeks() {
        // create dp account and related order
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WEM',
                AccountStatus__c = 'Traders'
        ));
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
                AccountId = dpAccount.Id
        ));
        Test.setCreatedDate(newOrder.Id, System.Now().addDays(-(20*7+1)));

        // run batch to update account status
        Test.startTest();
        Database.executeBatch(new AccountStatusUpdateBatch());
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
                SELECT Id, AccountStatus__c
                FROM Account
                WHERE Id = :dpAccount.Id
        ];

        // check results
        System.assertEquals('At Risk', updatedDPAccount.AccountStatus__c, 'Expecting a different account status.');
    }

    @IsTest
    private static void testMonthlyFrequencyOrderNoOrdersInLast36Weeks() {
        // create dp account and related order
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WEM',
                AccountStatus__c = 'Traders'
        ));
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
                AccountId = dpAccount.Id
        ));
        Test.setCreatedDate(newOrder.Id, System.Now().addDays(-(36*7+1)));

        // run batch to update account status
        Test.startTest();
        Database.executeBatch(new AccountStatusUpdateBatch());
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
                SELECT Id, AccountStatus__c
                FROM Account
                WHERE Id = :dpAccount.Id
        ];

        // check results
        System.assertEquals('Win Back', updatedDPAccount.AccountStatus__c, 'Expecting a different account status.');
    }

    @IsTest
    private static void testMonthlyFrequencyOrderNoOrdersInLast52Weeks() {
        // create dp account and related order
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WEM',
                AccountStatus__c = 'Traders'
        ));
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(
                RecordTypeId = RecordTypes.ORDER_FIELD_DIRECT_ID,
                AccountId = dpAccount.Id
        ));
        Test.setCreatedDate(newOrder.Id, System.Now().addDays(-(52*7+1)));

        // run batch to update account status
        Test.startTest();
        Database.executeBatch(new AccountStatusUpdateBatch());
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
                SELECT Id, AccountStatus__c
                FROM Account
                WHERE Id = :dpAccount.Id
        ];

        // check results
        System.assertEquals('Lapsed', updatedDPAccount.AccountStatus__c, 'Expecting a different account status.');
    }
}