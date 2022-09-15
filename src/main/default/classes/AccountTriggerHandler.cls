/**
 * @description       : Handler class for AccountTrigger
 **/

public with sharing class AccountTriggerHandler {
    private static final Set<String> VISIT_STATUSES {
        get {
            if (VISIT_STATUSES == null) {
                VISIT_STATUSES = new Set<String>(CallRecurrenceSetting__mdt.getInstance('OrgDefaultCallSettings').AllowedStatuses__c.split(','));
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

    public static void determineIfAccountTeamMembersMustBeRemoved(List<Account> newAccounts, Map<Id, Account> oldAccounts) {
        Set<Id> nonCoverageAccountIdsMovedToTraders = new Set<Id>();
        for (Account newAccount : newAccounts) {
            // Non-coverage accounts moved to "Traders" -> should not be visible for Field Sales users
            if (!newAccount.IsCoverage__c &&
                newAccount.AccountStatus__c != oldAccounts.get(newAccount.Id).AccountStatus__c &&
                AccountService.ACC_STATUSES_TO_REM_ROLES_FROM_ACCOUNT_TEAM.contains(newAccount.AccountStatus__c)) {
                nonCoverageAccountIdsMovedToTraders.add(newAccount.Id);
            }
        }
        AccountService.removeRolesFromAccountTeam(nonCoverageAccountIdsMovedToTraders, AccountService.ROLES_TO_BE_REMOVED_FROM_ACCOUNT_TEAM);
    }
}