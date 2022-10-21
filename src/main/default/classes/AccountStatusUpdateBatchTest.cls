/**
 * Created by magdalena.stanciu on 14.09.2022.
 */

@IsTest
private with sharing class AccountStatusUpdateBatchTest {
    private static final AccountStatusUpdateSetting__mdt weeklyFreqSetting = AccountService.ACC_STATUS_UPDATE_SETTINGS.get('W');
    private static final AccountStatusUpdateSetting__mdt fortnightlyFreqSetting = AccountService.ACC_STATUS_UPDATE_SETTINGS.get('F');
    private static final AccountStatusUpdateSetting__mdt monthlyFreqSetting = AccountService.ACC_STATUS_UPDATE_SETTINGS.get('M');

    @IsTest
    private static void testWeeklyFrequencyNoOrders() {
        // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WEW',
                LastOrderDate__c = null,
                AccountStatus__c = weeklyFreqSetting.UpdatedAccountStatusRecentOrders__c
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
        System.assertEquals(
                weeklyFreqSetting.UpdatedAccountStatusRecentOrders__c,
                updatedDPAccount.AccountStatus__c,
                'Expecting a different account status.'
        );
    }

    @IsTest
    private static void testWeeklyFrequencyRecentOrders() {
        // create dp account
        Date lastOrderDate = System.today();
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WEW',
                LastOrderDate__c = lastOrderDate,
                AccountStatus__c = weeklyFreqSetting.UpdatedAccountStatusRecentOrders__c
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
        System.assertEquals(
                weeklyFreqSetting.UpdatedAccountStatusRecentOrders__c,
                updatedDPAccount.AccountStatus__c,
                'Expecting a different account status.'
        );
    }

    @IsTest
    private static void testWeeklyFrequencyNoOrdersInLowerLimitNoOfWeeks() {
        // create dp account
        Date lastOrderDate = System.today().addDays(- (7 * Integer.ValueOf(weeklyFreqSetting.NoOfWeeksNoOrdersLowerLimit__c) + 2));
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WEW',
                LastOrderDate__c = lastOrderDate,
                AccountStatus__c = weeklyFreqSetting.UpdatedAccountStatusRecentOrders__c
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
        System.assertEquals(
                weeklyFreqSetting.UpdatedAccountStatusLowerLimit__c,
                updatedDPAccount.AccountStatus__c,
                'Expecting a different account status.'
        );
    }

    @IsTest
    private static void testWeeklyFrequencyNoOrdersInMidLimitNoOfWeeks() {
        // create dp account
        Date lastOrderDate = System.today().addDays(- (7 * Integer.ValueOf(weeklyFreqSetting.NoOfWeeksNoOrdersMidLimit__c) + 2));
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WEW',
                LastOrderDate__c = lastOrderDate,
                AccountStatus__c = weeklyFreqSetting.UpdatedAccountStatusRecentOrders__c
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
        System.assertEquals(
                weeklyFreqSetting.UpdatedAccountStatusMidLimit__c,
                updatedDPAccount.AccountStatus__c,
                'Expecting a different account status.'
        );
    }

    @IsTest
    private static void testWeeklyFrequencyNoOrdersInUpperLimitNoOfWeeks() {
        // create dp account
        Date lastOrderDate = System.today().addDays(- (7 * Integer.ValueOf(weeklyFreqSetting.NoOfWeeksNoOrdersUpperLimit__c) + 2));
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WEW',
                LastOrderDate__c = lastOrderDate,
                AccountStatus__c = weeklyFreqSetting.UpdatedAccountStatusRecentOrders__c
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
        System.assertEquals(
                weeklyFreqSetting.UpdatedAccountStatusUpperLimit__c,
                updatedDPAccount.AccountStatus__c,
                'Expecting a different account status.'
        );
    }

    @IsTest
    private static void testFortnightlyFrequencyNoOrders() {
        // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WE1',
                LastOrderDate__c = null,
                AccountStatus__c = fortnightlyFreqSetting.UpdatedAccountStatusRecentOrders__c
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
        System.assertEquals(
                fortnightlyFreqSetting.UpdatedAccountStatusRecentOrders__c,
                updatedDPAccount.AccountStatus__c,
                'Expecting a different account status.'
        );
    }

    @IsTest
    private static void testFortnightlyFrequencyRecentOrders() {
        // create dp account
        Date lastOrderDate = System.today();
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WE1',
                LastOrderDate__c = lastOrderDate,
                AccountStatus__c = fortnightlyFreqSetting.UpdatedAccountStatusRecentOrders__c
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
        System.assertEquals(
                fortnightlyFreqSetting.UpdatedAccountStatusRecentOrders__c,
                updatedDPAccount.AccountStatus__c,
                'Expecting a different account status.'
        );
    }

    @IsTest
    private static void testFortnightlyFrequencyNoOrdersInLowerLimitNoOfWeeks() {
        // create dp account
        Date lastOrderDate = System.today().addDays(- (7 * Integer.ValueOf(fortnightlyFreqSetting.NoOfWeeksNoOrdersLowerLimit__c) + 2));
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WE1',
                LastOrderDate__c = lastOrderDate,
                AccountStatus__c = fortnightlyFreqSetting.UpdatedAccountStatusRecentOrders__c
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
        System.assertEquals(
                fortnightlyFreqSetting.UpdatedAccountStatusLowerLimit__c,
                updatedDPAccount.AccountStatus__c,
                'Expecting a different account status.'
        );
    }

    @IsTest
    private static void testFortnightlyFrequencyNoOrdersInMidLimitNoOfWeeks() {
        // create dp account
        Date lastOrderDate = System.today().addDays(- (7 * Integer.ValueOf(fortnightlyFreqSetting.NoOfWeeksNoOrdersMidLimit__c) + 2));
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WE1',
                LastOrderDate__c = lastOrderDate,
                AccountStatus__c = fortnightlyFreqSetting.UpdatedAccountStatusRecentOrders__c
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
        System.assertEquals(
                fortnightlyFreqSetting.UpdatedAccountStatusMidLimit__c,
                updatedDPAccount.AccountStatus__c,
                'Expecting a different account status.'
        );
    }

    @IsTest
    private static void testFortnightlyFrequencyNoOrdersInUpperLimitNoOfWeeks() {
        // create dp account
        Date lastOrderDate = System.today().addDays(- (7 * Integer.ValueOf(fortnightlyFreqSetting.NoOfWeeksNoOrdersUpperLimit__c) + 2));
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WE1',
                LastOrderDate__c = lastOrderDate,
                AccountStatus__c = fortnightlyFreqSetting.UpdatedAccountStatusRecentOrders__c
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
        System.assertEquals(
                fortnightlyFreqSetting.UpdatedAccountStatusUpperLimit__c,
                updatedDPAccount.AccountStatus__c,
                'Expecting a different account status.'
        );
    }

    @IsTest
    private static void testMonthlyFrequencyNoOrders() {
        // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WEM',
                LastOrderDate__c = null,
                AccountStatus__c = monthlyFreqSetting.UpdatedAccountStatusRecentOrders__c
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
        System.assertEquals(
                monthlyFreqSetting.UpdatedAccountStatusRecentOrders__c,
                updatedDPAccount.AccountStatus__c,
                'Expecting a different account status.'
        );
    }

    @IsTest
    private static void testMonthlyFrequencyRecentOrders() {
        // create dp account
        Date lastOrderDate = System.today();
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WEM',
                LastOrderDate__c = lastOrderDate,
                AccountStatus__c = monthlyFreqSetting.UpdatedAccountStatusRecentOrders__c
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
        System.assertEquals(
                monthlyFreqSetting.UpdatedAccountStatusRecentOrders__c,
                updatedDPAccount.AccountStatus__c,
                'Expecting a different account status.'
        );
    }

    @IsTest
    private static void testMonthlyFrequencyNoOrdersInLowerLimitNoOfWeeks() {
        // create dp account
        Date lastOrderDate = System.today().addDays(- (7 * Integer.ValueOf(monthlyFreqSetting.NoOfWeeksNoOrdersLowerLimit__c) + 2));
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WEM',
                LastOrderDate__c = lastOrderDate,
                AccountStatus__c = monthlyFreqSetting.UpdatedAccountStatusRecentOrders__c
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
        System.assertEquals(
                monthlyFreqSetting.UpdatedAccountStatusLowerLimit__c,
                updatedDPAccount.AccountStatus__c,
                'Expecting a different account status.'
        );
    }

    @IsTest
    private static void testMonthlyFrequencyNoOrdersInMidLimitNoOfWeeks() {
        // create dp account
        Date lastOrderDate = System.today().addDays(- (7 * Integer.ValueOf(monthlyFreqSetting.NoOfWeeksNoOrdersMidLimit__c) + 2));
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WEM',
                LastOrderDate__c = lastOrderDate,
                AccountStatus__c = monthlyFreqSetting.UpdatedAccountStatusRecentOrders__c
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
        System.assertEquals(
                monthlyFreqSetting.UpdatedAccountStatusMidLimit__c,
                updatedDPAccount.AccountStatus__c,
                'Expecting a different account status.'
        );
    }

    @IsTest
    private static void testMonthlyFrequencyNoOrdersInUpperLimitNoOfWeeks() {
        // create dp account
        Date lastOrderDate = System.today().addDays(- (7 * Integer.ValueOf(monthlyFreqSetting.NoOfWeeksNoOrdersUpperLimit__c) + 2));
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                PrimaryGridNumber__c = '3C7201WEM',
                LastOrderDate__c = lastOrderDate,
                AccountStatus__c = monthlyFreqSetting.UpdatedAccountStatusRecentOrders__c
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
        System.assertEquals(
                monthlyFreqSetting.UpdatedAccountStatusUpperLimit__c,
                updatedDPAccount.AccountStatus__c,
                'Expecting a different account status.'
        );
    }
}