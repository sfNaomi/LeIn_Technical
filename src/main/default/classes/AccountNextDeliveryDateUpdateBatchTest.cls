/**
 * Created by magdalena.stanciu on 04.01.2023.
 */
@IsTest
private with sharing class AccountNextDeliveryDateUpdateBatchTest {
    @IsTest
    private static void testBatchExecution_ExistingTradersAccounts() {
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MO1', PrimaryStartDate__c = Date.newInstance(2022, 1, 1),
                NextDeliveryDate__c = null)
        );

        Test.startTest();
        Database.executeBatch(new AccountNextDeliveryDateUpdateBatch());
        Test.stopTest();

        Account updatedAccount = [
            SELECT Id, NextDeliveryDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Assert.isNotNull(updatedAccount.NextDeliveryDate__c);
    }

    @IsTest
    private static void testBatchExecution_NoExistingTradersAccounts() {
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Prospect',
                PrimaryGridNumber__c = '3C7201MO1', PrimaryStartDate__c = Date.newInstance(2022, 1, 1),
                NextDeliveryDate__c = null)
        );

        Test.startTest();
        Database.executeBatch(new AccountNextDeliveryDateUpdateBatch());
        Test.stopTest();

        Account updatedAccount = [
            SELECT Id, NextDeliveryDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Assert.isNull(updatedAccount.NextDeliveryDate__c);
    }
}