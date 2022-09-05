/**
 * @description       : Handler class for AccountTrigger
 **/

public with sharing class AccountTriggerHandler {
    public static void copyContactDetailsFromPrimaryContact(List<Account> newAccounts) {
        List<Account> accountsWithPrimaryContact = new List<Account>();
        for (Account newAccount : newAccounts) {
            if (newAccount.aforza__Primary_Contact__c != null) {
                accountsWithPrimaryContact.add(newAccount);
            }
        }

        AccountService.copyContactDetailsFromPrimaryContact(accountsWithPrimaryContact);
    }

    public static void copyContactDetailsFromPrimaryContact(List<Account> newAccounts, List<Account> oldAccounts) {
        List<Account> accountsWithPrimaryContactUpdated = new List<Account>();
        for (Integer index = 0; index < newAccounts.size(); index++) {
            if (newAccounts[index].aforza__Primary_Contact__c != oldAccounts[index].aforza__Primary_Contact__c) {
                accountsWithPrimaryContactUpdated.add(newAccounts[index]);
            }
        }
        AccountService.copyContactDetailsFromPrimaryContact(accountsWithPrimaryContactUpdated);
    }
}