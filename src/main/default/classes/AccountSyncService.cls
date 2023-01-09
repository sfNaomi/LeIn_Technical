/**
 * Created by magdalena.stanciu on 05.10.2022.
 */

public with sharing class AccountSyncService {
    public enum SyncOperation {
        PUSH,
        PULL
    }

    public enum AccountType {
        CHILD,
        PARENT
    }

    @TestVisible
    private static final List<AccountSyncMapping__mdt> MAPPINGS {
        get {
            if (MAPPINGS == null) {
                MAPPINGS = AccountSyncMapping__mdt.getAll().values();
            }
            return MAPPINGS;
        }
        set;
    }

    @TestVisible
    private static final List<String> FIELDS {
        get {
            if (FIELDS == null) {
                Set<String> newFields = new Set<String>();
                for (AccountSyncMapping__mdt mapping : MAPPINGS) {
                    newFields.add(mapping.FieldAPIName__c);
                    newFields.add(mapping.ConditionalField__c);
                }
                newFields.remove(null);
                FIELDS = new List<String>(newFields);
            }
            return FIELDS;
        }
        set;
    }

    @TestVisible
    private static Boolean fieldsRelevantForSyncAreChanged(Account newAccount, Account oldAccount) {
        for (String fieldName : FIELDS) {
            if (newAccount.get(fieldName) != oldAccount.get(fieldName)) {
                return true;
            }
        }
        return false;
    }

    public static void syncAccounts(List<Account> updatedAccounts, SyncOperation operation) {
        switch on operation {
            when PULL {
                List<Account> parentAccounts = getRelatedAccounts(updatedAccounts, AccountType.CHILD);
                syncAccounts(new Map<Id, Account>(parentAccounts), updatedAccounts);
            }
            when PUSH {
                if (updatedAccounts.size() > 0) {
                    Database.executeBatch(new CopyAccountValuesToChildrenBatch(updatedAccounts));
                }
            }
        }
    }

    public static List<Account> syncAccounts(Map<Id, Account> parentAccounts, List<Account> childAccounts) {
        for (Account childAccount : childAccounts) {
            if (childAccount.ParentId == null) {
                updateFieldToDefaults(childAccount);
                continue;
            }
            Account parentAccount = parentAccounts?.get(childAccount.ParentId);
            updateChildFromParent(parentAccount, childAccount);
        }
        return childAccounts;
    }

    @TestVisible
    private static void updateFieldToDefaults(Account newAccount) {
        for (AccountSyncMapping__mdt mapping : MAPPINGS) {
            setFieldToDefaultValue(newAccount, mapping.FieldAPIName__c, mapping.FieldDefaultValue__c);
        }
    }

    @TestVisible
    private static void setFieldToDefaultValue(Account newAccount, String fieldName, String defaultValue) {
        Schema.DisplayType targetFieldType =
            Schema.SObjectType.Account.fields.getMap().get(fieldName)?.getDescribe().getType();

        Object newValue = null;
        switch on targetFieldType {
            when BOOLEAN {
                newValue = Boolean.valueOf(defaultValue);
            }
            when INTEGER {
                newValue = Integer.valueOf(defaultValue);
            }
            when PERCENT, DOUBLE, CURRENCY {
                newValue = Decimal.valueOf(defaultValue);
            }
            when DATETIME {
                newValue = Datetime.valueOf(defaultValue);
            }
            when DATE {
                newValue = Date.valueOf(defaultValue);
            }
            when else {
                newValue = defaultValue;
            }
        }

        newAccount.put(fieldName, newValue);
    }

    @TestVisible
    private static void updateChildFromParent(Account parentAccount, Account childAccount) {
        for (AccountSyncMapping__mdt mapping : MAPPINGS) {
            if (mapping.ConditionalField__c == null && mapping.ConditionalValue__c == null) {
                childAccount.put(mapping.FieldAPIName__c, parentAccount.get(mapping.FieldAPIName__c));
                continue;
            }

            if (mapping.ConditionalField__c != null && mapping.ConditionalValue__c != null &&
                String.valueOf(parentAccount.get(mapping.ConditionalField__c)) == mapping.ConditionalValue__c) {
                childAccount.put(mapping.FieldAPIName__c, parentAccount.get(mapping.FieldAPIName__c));
            } else {
                setFieldToDefaultValue(childAccount, mapping.FieldAPIName__c, mapping.FieldDefaultValue__c);
            }
        }
    }

    public static List<Account> getRelatedAccounts(List<Account> newAccounts, AccountType inputAccType) {
        String whereField = null;
        String inField = null;
        switch on inputAccType {
            when CHILD {
                whereField = 'Id';
                inField = 'ParentId';
            }
            when PARENT {
                whereField = 'ParentId';
                inField = 'Id';
            }
        }

        Set<Id> accountIds = new Set<Id>();
        for (Account newAccount : newAccounts) {
            accountIds.add((Id) newAccount.get(inField));
        }
        accountIds.remove(null);

        String queryString = 'SELECT Id,ParentId,' + String.join(FIELDS, ',') +
            ' FROM Account WHERE ' + whereField + ' IN :accountIds';
        return Database.query(queryString);
    }

    public static Boolean accountRequiresSync(Account newAccount, Account oldAccount, AccountSyncService.SyncOperation operation) {
        switch on operation {
            when PULL {
                if (newAccount.RecordTypeId == RecordTypes.ACCOUNT_OUTLET_ID) {
                    if (
                        (oldAccount == null && newAccount.ParentId != null) ||
                            (oldAccount != null && newAccount.ParentId != oldAccount.ParentId)
                    ) {
                        return true;
                    }
                }
            }
            when PUSH {
                if (newAccount.RecordTypeId == RecordTypes.ACCOUNT_CUSTOMER_ID) {
                    if (AccountSyncService.fieldsRelevantForSyncAreChanged(newAccount, oldAccount)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }
}