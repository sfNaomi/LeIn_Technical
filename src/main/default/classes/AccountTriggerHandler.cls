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
    private enum Operation {
        UPSERTION,
        DELETION
    }

    private static final Set<String> DEFAULT_PRICE_BOOKS {
        get {
            if (DEFAULT_PRICE_BOOKS == null) {
                DEFAULT_PRICE_BOOKS = new Set<String>(
                    AccountSetting__mdt.getInstance('OrgDefaultAccountSettings').DefaultPriceBookNames__c.split(',')
                );
            }
            return DEFAULT_PRICE_BOOKS;
        }
        set;
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
        Map<Operation, List<Account>> operationToAccountListMap = determineAccountsToManageRecurrenceFor(newAccounts, oldMap);

        if (operationToAccountListMap.get(Operation.UPSERTION).size() > 0) {
            RecurringRecordService.upsertRecurringRecords(operationToAccountListMap.get(Operation.UPSERTION));
        }

        if (operationToAccountListMap.get(Operation.DELETION).size() > 0) {
            Set<Id> accountIds = new Set<Id>();
            for (Account acc : operationToAccountListMap.get(Operation.DELETION)) {
                accountIds.add(acc.Id);
            }
            RecurringRecordService.deleteRecurringAndVisitRecords(accountIds);
        }
    }

    private static Map<Operation, List<Account>> determineAccountsToManageRecurrenceFor(List<Account> newAccounts, Map<Id, Account> oldMap) {
        Map<Operation, List<Account>> operationToAccountListMap = new Map<Operation, List<Account>>();
        operationToAccountListMap.put(Operation.UPSERTION, new List<Account>());
        operationToAccountListMap.put(Operation.DELETION, new List<Account>());
        for (Account account : newAccounts) {
            // check for creation after insert context
            if (
                oldMap == null &&
                account.CreateCalls__c &&
                VISIT_STATUSES.contains(account.AccountStatus__c) &&
                account.RecordTypeId == RecordTypes.ACCOUNT_OUTLET_ID &&
                String.isNotEmpty(account.PrimaryGridNumber__c) &&
                account.PrimaryStartDate__c != null
            ) {
                operationToAccountListMap.get(Operation.UPSERTION).add(account);
                continue;
            }

            if (oldMap != null) {
                Account oldAccount = oldMap.get(account.Id);
                // check for update after update context
                if (
                    account.CreateCalls__c &&
                    VISIT_STATUSES.contains(account.AccountStatus__c) &&
                    account.RecordTypeId == RecordTypes.ACCOUNT_OUTLET_ID &&
                    String.isNotEmpty(account.PrimaryGridNumber__c) &&
                    account.PrimaryStartDate__c != null &&
                    (account.PrimaryStartDate__c <> oldAccount.PrimaryStartDate__c ||
                    account.PrimaryGridNumber__c <> oldAccount.PrimaryGridNumber__c ||
                            account.AccountStatus__c <> oldAccount.AccountStatus__c)
                ) {
                    operationToAccountListMap.get(Operation.UPSERTION).add(account);
                    continue;
                }
                // check for delete after update context
                if (
                    (oldAccount.CreateCalls__c && account.CreateCalls__c == false) ||
                    (VISIT_STATUSES.contains(oldAccount.AccountStatus__c) && !VISIT_STATUSES.contains(account.AccountStatus__c)) ||
                    (String.isNotEmpty(oldAccount.PrimaryGridNumber__c) && String.isEmpty(account.PrimaryGridNumber__c)) ||
                    (oldAccount.PrimaryStartDate__c != null &&
                    account.PrimaryStartDate__c == null)
                ) {
                    operationToAccountListMap.get(Operation.DELETION).add(account);
                }
            }
        }
        return operationToAccountListMap;
    }

    public static void determineIfAccountTeamMembersMustBeRemoved(List<Account> newAccounts, Map<Id, Account> oldAccounts) {
        Set<Id> nonCoverageAccountIdsMovedToTraders = new Set<Id>();
        for (Account newAccount : newAccounts) {
            // Non-coverage accounts moved to "Traders" -> should not be visible for Field Sales users
            if (
                !newAccount.IsCoverage__c &&
                newAccount.AccountStatus__c != oldAccounts.get(newAccount.Id).AccountStatus__c &&
                AccountService.ACC_STATUSES_TO_REM_ROLES_FROM_ACCOUNT_TEAM.contains(newAccount.AccountStatus__c)
            ) {
                nonCoverageAccountIdsMovedToTraders.add(newAccount.Id);
            }
        }
        AccountService.removeRolesFromAccountTeam(nonCoverageAccountIdsMovedToTraders, AccountService.ROLES_TO_BE_REMOVED_FROM_ACCOUNT_TEAM);
    }

    public static void updatePORequiredStartingWithCustomerAccs(List<Account> newAccounts, Map<Id, Account> oldMap) {
        List<Id> customerAccountsWithPOReq = new List<Id>();
        for (Account account : newAccounts) {
            if (
                oldMap != null &&
                account.RecordTypeId == RecordTypes.ACCOUNT_CUSTOMER_ID &&
                account.PORequired__c == true &&
                oldMap.get(account.Id).PORequired__c != true
            ) {
                customerAccountsWithPOReq.add(account.Id);
            }
        }
        List<Account> dpAccountsToUpdate = [SELECT PORequired__c, ParentId FROM Account WHERE ParentId IN :customerAccountsWithPOReq];
        for (Account account : dpAccountsToUpdate) {
            account.PORequired__c = true;
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

    public static void addChildrenDPsToParentCustomerAcc(Account newAccount, Map<Id, List<Account>> customerAccountIdsToDPAccounts) {
        if (customerAccountIdsToDPAccounts.containsKey(newAccount.ParentId)) {
            customerAccountIdsToDPAccounts.get(newAccount.ParentId).add(newAccount);
        } else {
            customerAccountIdsToDPAccounts.put(newAccount.ParentId, new List<Account>{ newAccount });
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
            System.debug(priceBook);
            for (String defaultName : DEFAULT_PRICE_BOOKS) {
                System.debug(defaultName);
                if (priceBook.Name.contains(defaultName)) {
                    priceBookNameToId.put(defaultName.substring(defaultName.lastIndexOf(' ') + 1), priceBook.Id);
                }
            }
        }
        return priceBookNameToId;
    }
}
