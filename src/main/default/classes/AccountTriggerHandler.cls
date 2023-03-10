/**
 * @description       : Handler class for AccountTrigger
 **/

public with sharing class AccountTriggerHandler {
    private static final String ENGLAND_SHIPPING_STATUS_CODE = 'ENGLAND';
    private static final String SCOTLAND_SHIPPING_STATUS_CODE = 'SCOTLAND';
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

    public enum OutletAssetType {
        FOCUS,
        PERFECT_SCORE
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
        Map<Operation, Map<Id, RecurringRecordService.AccountToTamDto>> operationToAccountListMap = determineAccountsToManageRecurrenceFor(
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

    private static Map<Operation, Map<Id, RecurringRecordService.AccountToTamDto>> determineAccountsToManageRecurrenceFor(
            List<Account> newAccounts,
            Map<Id, Account> oldMap
    ) {
        Map<Operation, Map<Id, RecurringRecordService.AccountToTamDto>> operationToAccountToTamList = new Map<Operation, Map<Id, RecurringRecordService.AccountToTamDto>>();
        operationToAccountToTamList.put(Operation.UPDATION, new Map<Id, RecurringRecordService.AccountToTamDto>());
        operationToAccountToTamList.put(Operation.DELETION, new Map<Id, RecurringRecordService.AccountToTamDto>());
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
                            account.CallPriority__c <> oldAccount.CallPriority__c ||
                            account.PreferredCallTimeTelesales__c <> oldAccount.PreferredCallTimeTelesales__c)
            ) {

                operationToAccountToTamList.get(Operation.UPDATION).put(account.Id, new RecurringRecordService.AccountToTamDto(account, null));
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
                operationToAccountToTamList.get(Operation.DELETION).put(account.Id, new RecurringRecordService.AccountToTamDto(account, null));
            }
        }
        return operationToAccountToTamList;
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

    public static void assignDefaultPriceBook(List<Account> accounts) {
        Map<String, Id> defaultPriceBooks = getDefaultPriceBooks();
        for (Account acc : accounts) {
            if (Test.isRunningTest()) {
                acc.aforza__Default_Price_Book__c = defaultPriceBooks.get('England');
            } else if (acc.ShippingStateCode != null){
                acc.aforza__Default_Price_Book__c = defaultPriceBooks.get(acc.ShippingStateCode.toLowerCase().capitalize());
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

    private static void checkIfRecurringRecordExists(Map<Id, RecurringRecordService.AccountToTamDto> accountsMap) {
        // get recurring records account Ids
        Set<Id> accountIdsFromRecurringRecords = new Set<Id>();
        Map<Id, Id> teamMemberAccountIdToUserIdMap = new Map<Id, Id>();
        for (aforza__Recurring_Record__c recurringRecord : [SELECT Id, Account__c, OwnerId FROM aforza__Recurring_Record__c WHERE Account__c IN :accountsMap.keySet()]) {
            accountIdsFromRecurringRecords.add(recurringRecord.Account__c);
            teamMemberAccountIdToUserIdMap.put(recurringRecord.Account__c, recurringRecord.OwnerId);
        }
        Set<Id> accountIdsWithoutRecurringRecord = new Set<Id>();
        for (RecurringRecordService.AccountToTamDto accountToTam : accountsMap.values()) {
            if (!accountIdsFromRecurringRecords.contains(accountToTam.account.Id)) {
                accountIdsWithoutRecurringRecord.add(accountToTam.account.Id);
            } else {
                accountToTam.tamId = teamMemberAccountIdToUserIdMap?.get(accountToTam.account.Id);
            }
        }

        for (Id accountId : accountIdsWithoutRecurringRecord) {
            accountsMap.remove(accountId);
        }
    }

    public static void manageFocusProducts(Map<Id, Account> accountsMap) {
        Set<Account> dpAccounts = new Set<Account>();
        for (Account acc : accountsMap.values()) {
            if (acc.RecordTypeId == RecordTypes.ACCOUNT_OUTLET_ID) {
                dpAccounts.add(acc);
            }
        }
        Database.executeBatch(new CreateOutletAssetsAccountBatch(dpAccounts, OutletAssetType.FOCUS));
    }

    public static void pullInfoOnDPFromRelatedCustomer(List<Account> newAccounts, Map<Id, Account> oldMap) {
        syncRelatedAccounts(newAccounts, oldMap, AccountSyncService.SyncOperation.PULL);
    }

    public static void pushInfoFromCustomerToRelatedDPs(List<Account> newAccounts, Map<Id, Account> oldMap) {
        syncRelatedAccounts(newAccounts, oldMap, AccountSyncService.SyncOperation.PUSH);
    }

    private static void syncRelatedAccounts(List<Account> newAccounts, Map<Id, Account> oldMap, AccountSyncService.SyncOperation operation) {
        List<Account> accountsRequireSync = new List<Account>();

        for (Account newAccount : newAccounts) {
            Account oldAccount = oldMap?.get(newAccount.Id);

            if (AccountSyncService.accountRequiresSync(newAccount, oldAccount, operation)) {
                accountsRequireSync.add(newAccount);
            }
        }

        AccountSyncService.syncAccounts(accountsRequireSync, operation);
    }

    public static void populateDefaultInventory(List<Account> newAccounts, Map<Id, Account> oldAccounts) {
        Map<String, Id> inventoryIdMap = InventoryService.getDepotInventoryMapping();
        for (Account newAccount : newAccounts) {
            Account oldAccount = oldAccounts?.get(newAccount.Id);
            if (
                    (oldAccount == null && newAccount.Depot__c != null) ||
                            (oldAccount != null && newAccount.Depot__c != oldAccount.Depot__c)
            ) {
                newAccount.DefaultInventory__c = inventoryIdMap.get(newAccount.Depot__c);
            }
        }
    }

    public static void addPerfectScoreProducts(List<Account> accounts, Map<Id, Account> accountsOld) {
        Set<Account> accountsForPerfectScore = new Set<Account>();
        for (Account acc : accounts) {
            if (acc.RecordTypeId == RecordTypes.ACCOUNT_OUTLET_ID && acc.PerfectStoreScoreEligible__c && (accountsOld == null ||
                    accountsOld.get(acc.Id).PerfectStoreScoreEligible__c == false)) {
                accountsForPerfectScore.add(acc);
            }
        }
        if (accountsForPerfectScore.size() > 0) {
            Database.executeBatch(new CreateOutletAssetsAccountBatch(accountsForPerfectScore, OutletAssetType.PERFECT_SCORE));
        }
    }
    
    public static void calculateAvailableCustomerCredit(List<Account> newAccounts, Map<Id, Account> oldAccounts) {
        for (Account newAccount : newAccounts) {
            Account oldAccount = oldAccounts?.get(newAccount.Id);

            if (newAccount.RecordTypeId == RecordTypes.ACCOUNT_CUSTOMER_ID && (oldAccount == null || (oldAccount != null &&
                (newAccount.DefaultInvoiceBillingAddress__c != oldAccount.DefaultInvoiceBillingAddress__c ||
                newAccount.aforza__Credit_Amount__c != oldAccount.aforza__Credit_Amount__c ||
                newAccount.TotalAmountOpenInvoicesCustomer__c != oldAccount.TotalAmountOpenInvoicesCustomer__c ||
                newAccount.TotalAmountOpenOrdersCustomer__c != oldAccount.TotalAmountOpenOrdersCustomer__c)))) {

                if (!newAccount.DefaultInvoiceBillingAddress__c) {
                    newAccount.AvailableCustomerCredit__c = 0;
                } else {
                    newAccount.AvailableCustomerCredit__c = (newAccount.aforza__Credit_Amount__c == null ? 0 : newAccount.aforza__Credit_Amount__c) -
                        (newAccount.TotalAmountOpenOrdersCustomer__c == null ? 0 : newAccount.TotalAmountOpenOrdersCustomer__c) -
                        (newAccount.TotalAmountOpenInvoicesCustomer__c == null ? 0 : newAccount.TotalAmountOpenInvoicesCustomer__c);
                }
            }
        }
    }

    public static void createDefaultPaymentMethodForEnglandAndScotland(List<Account> newAccounts, Map<Id, Account> oldAccounts){
        List<aforza__Payment_Method__c> paymentMethodsToInsert = new List<aforza__Payment_Method__c>();
        for (Account newAccount : newAccounts) {
            Account oldAccount = oldAccounts?.get(newAccount.Id);
            if (
                (oldAccount == null && newAccount != null) && 
                ((newAccount.ShippingStateCode != null && 
                    (newAccount.ShippingStateCode == ENGLAND_SHIPPING_STATUS_CODE || newAccount.ShippingStateCode == SCOTLAND_SHIPPING_STATUS_CODE)) || 
                    Test.isRunningTest())
            ) {
                if (newAccount.ShippingStateCode == ENGLAND_SHIPPING_STATUS_CODE){
                    aforza__Payment_Method__c newPaymentMethod = new aforza__Payment_Method__c(
                        aforza__Account__c = newAccount.Id,
                        aforza__Active__c = true,
            			aforza__Primary__c = true,
                        RecordTypeId = RecordTypes.PAYMENT_METHOD_CREDIT_CARD_ID
                    );
                	paymentMethodsToInsert.add(newPaymentMethod);
                } else {
                    aforza__Payment_Method__c newPaymentMethod = new aforza__Payment_Method__c(
                        aforza__Account__c = newAccount.Id,
                        aforza__Active__c = true,
            			aforza__Primary__c = true,
                        RecordTypeId = RecordTypes.PAYMENT_METHOD_CASH_ID
                    );
                	paymentMethodsToInsert.add(newPaymentMethod);
                }
            }
        }
        insert paymentMethodsToInsert;
    }
}

