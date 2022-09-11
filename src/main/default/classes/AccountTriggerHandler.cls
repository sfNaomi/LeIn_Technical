/**
 * @description       : Handler class for AccountTrigger
 **/

public with sharing class AccountTriggerHandler {
    private static final Set<String> VISIT_STATUSES {
        get {
            if (VISIT_STATUSES == null) {
                VISIT_STATUSES = new Set<String>(CallCreationSettings__c.getOrgDefaults().AllowedStatuses__c.split(','));
            }
            return VISIT_STATUSES;
        }
        set;
    }
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

    public static void manageReoccurrenceRecord(List<Account> newAccounts, Map<Id, Account> oldMap) {
        List<Account> accountsToUpsertRecurringRecord = new List<Account>();
        for (Account account : newAccounts) {
            //TODO add proper checks and logic for update
            if (account.CreateCalls__c && VISIT_STATUSES.contains(account.AccountStatus__c) && account.RecordTypeId == RecordTypes.ACCOUNT_OUTLET_ID) {
                accountsToUpsertRecurringRecord.add(account);
            }
        }
        if (accountsToUpsertRecurringRecord.size() > 0) {
            RecurringRecordService.manageRecurringRecords(accountsToUpsertRecurringRecord);
        }
    }
}