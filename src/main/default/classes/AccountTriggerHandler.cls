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
                            account.CallPriority__c <> oldAccount.CallPriority__c ||
                            account.PreferredCallTimeTelesales__c <> oldAccount.PreferredCallTimeTelesales__c)
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
    
    public static void createAforzaPaymentMethodForBottomLineDdMandate(List<Account> newAccounts, Map<Id,Account> oldAccounts){
        Set<Id> newAccountIds = new Set<Id>();
        List<aforza__Payment_Method__c> aforzaPaymentMethodsToCreate = new List<aforza__Payment_Method__c>();
        for (Account newAccount : newAccounts){
            Account oldAccount = oldAccounts?.get(newAccount.Id);
            if (((oldAccount == null && newAccount != null) || 
                (oldAccount != null && 
                 (
                    (oldAccount.BottomlineRefNumber__c != newAccount.BottomlineRefNumber__c) || 
                 	(oldAccount.DirectDebitMandateRef__c != newAccount.DirectDebitMandateRef__c) ||
                 	(oldAccount.DdActive__c != newAccount.DdActive__c)
                 )
                )) &&
                 (newAccount.BottomlineRefNumber__c != null && newAccount.DirectDebitMandateRef__c != null &&
                 newAccount.DdActive__c == true)) 
                {
                    newAccountIds.add(newAccount.Id);
            }
        }
        if(newAccountIds.size() > 0){
        	for(Id accountId : newAccountIds){
            	aforzaPaymentMethodsToCreate.add(createNewAforzaPaymentMethodAndPopulateNecessaryFields(accountId));
        	}
        }                                            
        insert aforzaPaymentMethodsToCreate;
    }

    private static aforza__Payment_Method__c createNewAforzaPaymentMethodAndPopulateNecessaryFields(Id parentAccountId){
        	aforza__Payment_Method__c newAforzaPaymentMethod = new aforza__Payment_Method__c();
            newAforzaPaymentMethod.RecordTypeId=RecordTypes.PAYMENT_METHOD_DIRECT_CARD_ID;
            newAforzaPaymentMethod.aforza__Account__c = parentAccountId;
            newAforzaPaymentMethod.aforza__Active__c = true;
            newAforzaPaymentMethod.aforza__Primary__c = true;
        	
            return newAforzaPaymentMethod;    
	}

    public static void calculateAvailableCustomerCredit(List<Account> newAccounts, Map<Id,Account> oldAccounts) {
        Map<Id, Decimal> parentAccountIdToNewAvailableCredit = new Map<Id, Decimal>();
        for (Account newAccount : newAccounts){
            Account oldAccount = oldAccounts?.get(newAccount.Id);
            Boolean isAmountChanged = newAccount.AvailableCredit__c != oldAccount.AvailableCredit__c;
            Boolean isOldParentBlank = oldAccount.ParentId == null;
            Boolean isNewParentBlank = newAccount.ParentId == null;
            Boolean isParentUpdated = newAccount.ParentId != oldAccount.ParentId;
            Boolean isAccountStatusChanged = newAccount.AccountStatus__c != oldAccount.AccountStatus__c;
            Boolean isAccountClosed = newAccount.AccountStatus__c == 'Closed';

            if (newAccount.RecordTypeId == RecordTypes.ACCOUNT_OUTLET_ID && (isAmountChanged || isParentUpdated)) {
                Decimal newValue = 0;
                if(!isNewParentBlank) {
                    getUpdatedParentAccountIdToNewAvailableCreditMap(
                        parentAccountIdToNewAvailableCredit, 
                        newAccount, 
                        newAccount.AvailableCredit__c
                    );
                }
                if(!isOldParentBlank) {
                    getUpdatedParentAccountIdToNewAvailableCreditMap(
                        parentAccountIdToNewAvailableCredit, 
                        oldAccount, 
                        -oldAccount.AvailableCredit__c
                    );
                }
            }
            if(newAccount.RecordTypeId == RecordTypes.ACCOUNT_OUTLET_ID && isAccountStatusChanged && isAccountClosed) {
                getUpdatedParentAccountIdToNewAvailableCreditMap(
                    parentAccountIdToNewAvailableCredit, 
                    newAccount, 
                    -newAccount.AvailableCredit__c
                );
            }
        }
        List<Account> parentAccountsToUpdate = new List<Account>();
        if(parentAccountIdToNewAvailableCredit.size() > 0) {
            for(Account acc: [SELECT DefaultInvoiceBillingAddress__c, AvailableCustomerCredit__c FROM Account WHERE ID IN :parentAccountIdToNewAvailableCredit.keySet()]) {
                acc.AvailableCustomerCredit__c = acc.AvailableCustomerCredit__c == null ? 0 : acc.AvailableCustomerCredit__c;
                if(acc.DefaultInvoiceBillingAddress__c == true) {
                    acc.AvailableCustomerCredit__c += parentAccountIdToNewAvailableCredit.get(acc.Id);
                    parentAccountsToUpdate.add(acc);
                }
            }
        }
        update parentAccountsToUpdate;
    }

    private static void getUpdatedParentAccountIdToNewAvailableCreditMap(
        Map<Id, Decimal> parentAccountIdToNewAvailableCredit,
        Account acc,
        Decimal value
    ) {
        Decimal newValue = 0;
        if( !parentAccountIdToNewAvailableCredit.containsKey(acc.ParentId) ) {
            parentAccountIdToNewAvailableCredit.put(acc.ParentId, 0);
        }
        newValue = parentAccountIdToNewAvailableCredit.get(acc.ParentId) + value;
        parentAccountIdToNewAvailableCredit.put(acc.ParentId, newValue);
    }
}

