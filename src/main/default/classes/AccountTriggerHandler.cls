/**
 * @description       : Handler class for AccountTrigger
 **/

public with sharing class AccountTriggerHandler {
    public static final Set<String> VISIT_STATUSES {
        get {
            if (VISIT_STATUSES == null) {
                VISIT_STATUSES = new Set<String>(
                        CallRecurrenceSetting__mdt.getInstance('OrgDefaultCallSettings').AllowedStatuses__c.split(',')
                );
            }
            return VISIT_STATUSES;
        }
        set;
    }
    private enum Operation {
        UPDATION,
        DELETION
    }

    public static void copyContactDetailsFromPrimaryContact(List<Account> newAccounts, List<Account> oldAccounts) {
        List<Account> accountsToUpdateContactDetails = new List<Account>();
        for (Integer index = 0; index < newAccounts.size(); index++) {
            if (
                    newAccounts.get(index).aforza__Primary_Contact__c != null ||
                            newAccounts.get(index).aforza__Primary_Contact__c != oldAccounts?.get(index).aforza__Primary_Contact__c
            ) {
                accountsToUpdateContactDetails.add(newAccounts.get(index));
            }
        }
        AccountService.copyContactDetailsFromPrimaryContact(accountsToUpdateContactDetails);
    }

    public static void manageReoccurrenceRecord(List<Account> newAccounts, Map<Id, Account> oldMap) {
        Map<Operation, Map<Id, Account>> operationToAccountListMap = determineAccountsToManageRecurrenceFor(
                newAccounts,
                oldMap
        );

        if (operationToAccountListMap.get(Operation.UPDATION).size() > 0) {
            checkIfRecurringRecordExists(operationToAccountListMap.get(Operation.UPDATION));
            RecurringRecordService.upsertRecurringRecords(operationToAccountListMap.get(Operation.UPDATION).values());
        }

        if (operationToAccountListMap.get(Operation.DELETION).size() > 0) {
            RecurringRecordService.deleteRecurringAndVisitRecords(operationToAccountListMap.get(Operation.DELETION).keySet());
        }
    }

    private static Map<Operation, Map<Id, Account>> determineAccountsToManageRecurrenceFor(
            List<Account> newAccounts,
            Map<Id, Account> oldMap
    ) {
        Map<Operation, Map<Id, Account>> operationToAccountListMap = new Map<Operation, Map<Id, Account>>();
        operationToAccountListMap.put(Operation.UPDATION, new Map<Id, Account>());
        operationToAccountListMap.put(Operation.DELETION, new Map<Id, Account>());
        for (Account account : newAccounts) {
            Account oldAccount = oldMap.get(account.Id);
            // check for update after update context
            if (account.CreateCalls__c &&
                    VISIT_STATUSES.contains(account.AccountStatus__c) &&
                    account.RecordTypeId == RecordTypes.ACCOUNT_OUTLET_ID &&
                    String.isNotEmpty(account.PrimaryGridNumber__c) &&
                    account.PrimaryStartDate__c != null &&
                    (account.PrimaryStartDate__c <> oldAccount.PrimaryStartDate__c ||
                            account.PrimaryGridNumber__c <> oldAccount.PrimaryGridNumber__c ||
                            account.AccountStatus__c <> oldAccount.AccountStatus__c ||
                            account.CallPriority__c <> oldAccount.CallPriority__c)
            ) {
                operationToAccountListMap.get(Operation.UPDATION).put(account.Id, account);
                continue;
            }
            // check for delete after update context
            if (
                    (oldAccount.CreateCalls__c && account.CreateCalls__c == false) ||
                            (VISIT_STATUSES.contains(oldAccount.AccountStatus__c) &&
                                    !VISIT_STATUSES.contains(account.AccountStatus__c)) ||
                            (String.isNotEmpty(oldAccount.PrimaryGridNumber__c) &&
                                    String.isEmpty(account.PrimaryGridNumber__c)) ||
                            (oldAccount.PrimaryStartDate__c != null &&
                                    account.PrimaryStartDate__c == null)
            ) {
                operationToAccountListMap.get(Operation.DELETION).put(account.Id, account);
            }
        }
        return operationToAccountListMap;
    }

    public static void manageAccountTeamMembership(List<Account> newAccounts, Map<Id, Account> oldAccounts) {
        Set<Id> accountIdsWhichRequireAccountMembershipUpdate = new Set<Id>();
        for (Account newAccount : newAccounts) {
            Account oldAccount = oldAccounts.get(newAccount.Id);
            if (
                    !newAccount.IsCoverage__c &&
                            AccountService.accountStatusRequiresAccountTeamMembershipUpdate(newAccount.AccountStatus__c) &&
                            (newAccount.IsCoverage__c != oldAccount.IsCoverage__c ||
                                    (newAccount.AccountStatus__c != oldAccount.AccountStatus__c &&
                                            !AccountService.accountStatusRequiresAccountTeamMembershipUpdate(oldAccount.AccountStatus__c)))
            ) {
                accountIdsWhichRequireAccountMembershipUpdate.add(newAccount.Id);
            }
        }
        AccountService.removeRolesFromAccountTeam(
                accountIdsWhichRequireAccountMembershipUpdate,
                AccountService.ROLES_TO_BE_REMOVED_FROM_ACCOUNT_TEAM
        );
    }

    public static void updatePORequiredStartingWithCustomerAccs(List<Account> newAccounts, Map<Id, Account> oldMap) {
        List<Id> customerAccountsWithPOReq = new List<Id>();
        List<Id> customerAccountsWithoutPOReq = new List<Id>();
        for (Account account : newAccounts) {
            if (
                    oldMap != null &&
                            account.RecordTypeId == RecordTypes.ACCOUNT_CUSTOMER_ID &&
                            account.PORequired__c == true &&
                            oldMap.get(account.Id).PORequired__c != true
            ) {
                customerAccountsWithPOReq.add(account.Id);
            }
            if (
                    oldMap != null &&
                            account.RecordTypeId == RecordTypes.ACCOUNT_CUSTOMER_ID &&
                            account.PORequired__c == false &&
                            oldMap.get(account.Id).PORequired__c != false
            ) {
                customerAccountsWithoutPOReq.add(account.Id);
            }
        }
        if (!customerAccountsWithPOReq.isEmpty()) {
            updateDPsWithNewPORequiredValue(customerAccountsWithPOReq, true);
        }
        if (!customerAccountsWithoutPOReq.isEmpty()) {
            updateDPsWithNewPORequiredValue(customerAccountsWithoutPOReq, false);
        }
    }

    public static void updateDPsWithNewPORequiredValue(List<Id> customerAccounts, Boolean newValue) {
        List<Account> dpAccountsToUpdate = [
                SELECT PORequired__c, ParentId
                FROM Account
                WHERE ParentId IN :customerAccounts
        ];
        for (Account account : dpAccountsToUpdate) {
            account.PORequired__c = newValue;
        }
        update dpAccountsToUpdate;
    }

    public static void updatePORequiredStartingWithDPs(List<Account> newAccounts, Map<Id, Account> oldMap) {
        Map<Id, List<Account>> customerAccountIdsToDPAccounts = new Map<Id, List<Account>>();
        for (Account account : newAccounts) {
            if (oldMap == null && account.RecordTypeId == RecordTypes.ACCOUNT_OUTLET_ID && account.ParentId != null) {
                addChildrenDPsToParentCustomerAcc(account, customerAccountIdsToDPAccounts);
            }
            if (
                    oldMap != null &&
                            account.RecordTypeId == RecordTypes.ACCOUNT_OUTLET_ID &&
                            account.ParentId != oldMap.get(account.Id).ParentId &&
                            account.ParentId != null
            ) {
                addChildrenDPsToParentCustomerAcc(account, customerAccountIdsToDPAccounts);
            }
        }
        List<Account> verifiedAccountsWithPORequired = [
                SELECT Id, PORequired__c
                FROM Account
                WHERE Id IN :customerAccountIdsToDPAccounts.keySet() AND PORequired__c = TRUE
        ];
        Set<Id> customerAccountIdsWithPORequired = (new Map<Id, Account>(verifiedAccountsWithPORequired)).keySet();

        for (Id customerAccountId : customerAccountIdsWithPORequired) {
            if (customerAccountIdsToDPAccounts.containsKey(customerAccountId)) {
                for (Account dpAccount : customerAccountIdsToDPAccounts.get(customerAccountId)) {
                    dpAccount.PORequired__c = true;
                }
            }
        }
    }

    public static void addChildrenDPsToParentCustomerAcc(
            Account newAccount,
            Map<Id, List<Account>> customerAccountIdsToDPAccounts
    ) {
        if (customerAccountIdsToDPAccounts.containsKey(newAccount.ParentId)) {
            customerAccountIdsToDPAccounts.get(newAccount.ParentId).add(newAccount);
        } else {
            customerAccountIdsToDPAccounts.put(newAccount.ParentId, new List<Account>{
                    newAccount
            });
        }
    }

    public static void assignDefaultPriceBook(List<Account> accounts) {
        Map<String, Id> defaultPriceBooks = getDefaultPriceBooks();
        for (Account acc : accounts) {
            if (acc.FieldSalesRegion__c != null) {
                acc.aforza__Default_Price_Book__c = defaultPriceBooks.get(acc.FieldSalesRegion__c.substringBefore(' '));
            }
        }
    }

    @TestVisible
    private static Map<String, Id> getDefaultPriceBooks() {
        Map<String, Id> priceBookNameToId = new Map<String, Id>();
        for (Pricebook2 priceBook : [SELECT Id, Name FROM Pricebook2 WHERE IsActive = TRUE AND Name LIKE '%Default%']) {
            for (String defaultName : AccountService.DEFAULT_PRICE_BOOKS) {
                if (priceBook.Name.contains(defaultName)) {
                    priceBookNameToId.put(defaultName.substring(defaultName.lastIndexOf(' ') + 1), priceBook.Id);
                }
            }
        }
        return priceBookNameToId;
    }

    private static void checkIfRecurringRecordExists(Map<Id, Account> accountsMap) {
        // get recurring records account Ids
        Set<Id> accountIdsFromRecurringRecords = new Set<Id>();
        for (aforza__Recurring_Record__c recurringRecord : [SELECT Id, Account__c FROM aforza__Recurring_Record__c WHERE Account__c IN :accountsMap.keySet()]) {
            accountIdsFromRecurringRecords.add(recurringRecord.Account__c);
        }
        Set<Id> accountIdsWithoutRecurringRecord = new Set<Id>();
        for (Account account : accountsMap.values()) {
            if (!accountIdsFromRecurringRecords.contains(account.Id)) {
                accountIdsWithoutRecurringRecord.add(account.Id);
            }
        }

        for (Id accountId : accountIdsWithoutRecurringRecord) {
            accountsMap.remove(accountId);
        }
    }
}
