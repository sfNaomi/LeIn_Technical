/**
 * @description       : Handler class for AccountTrigger
 **/

public with sharing class AccountTriggerHandler {
    public static void copyContactDetailsFromPrimaryContact(List<Account> newAccounts, List<Account> oldAccounts) {
        List<Account> accountsToUpdateContactDetails = new List<Account>();
        for (Integer index = 0; index < newAccounts.size(); index++) {
            if (newAccounts.get(index).aforza__Primary_Contact__c != null ||
                    newAccounts.get(index).aforza__Primary_Contact__c != oldAccounts?.get(index).aforza__Primary_Contact__c) {
                accountsToUpdateContactDetails.add(newAccounts.get(index));
            }
        }
        AccountService.copyContactDetailsFromPrimaryContact(accountsToUpdateContactDetails);
    }
}