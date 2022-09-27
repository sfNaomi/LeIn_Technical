/**
 * @description       : Service class implementing account specific operations
 **/

public with sharing class AccountService {
    public static final AccountSetting__mdt ACCOUNT_SETTING {
        get {
            if (ACCOUNT_SETTING == null) {
                ACCOUNT_SETTING = AccountSetting__mdt.getInstance('OrgDefaultAccountSettings');
            }
            return ACCOUNT_SETTING;
        }
        set;
    }

    public static final List<String> ROLES_TO_BE_REMOVED_FROM_ACCOUNT_TEAM {
        get {
            if (ROLES_TO_BE_REMOVED_FROM_ACCOUNT_TEAM == null) {
                ROLES_TO_BE_REMOVED_FROM_ACCOUNT_TEAM = ACCOUNT_SETTING.RolesToBeRemovedFromAccountTeam__c.split(',');
            }
            return ROLES_TO_BE_REMOVED_FROM_ACCOUNT_TEAM;
        }
        set;
    }

    public static final List<String> STATUSES_TO_REM_ROLES_FROM_ACCOUNT_TEAM {
        get {
            if (STATUSES_TO_REM_ROLES_FROM_ACCOUNT_TEAM == null) {
                STATUSES_TO_REM_ROLES_FROM_ACCOUNT_TEAM = ACCOUNT_SETTING.StatusesToUpdateTeamMembership__c.split(',');
            }
            return STATUSES_TO_REM_ROLES_FROM_ACCOUNT_TEAM;
        }
        set;
    }

    public static final List<String> STATUSES_TO_UPDATE_WHEN_NO_RECENT_ORDERS {
        get {
            if (STATUSES_TO_REM_ROLES_FROM_ACCOUNT_TEAM == null) {
                STATUSES_TO_REM_ROLES_FROM_ACCOUNT_TEAM = ACCOUNT_SETTING.StatusesToUpdateWhenNoRecentOrders__c.split(',');
            }
            return STATUSES_TO_REM_ROLES_FROM_ACCOUNT_TEAM;
        }
        set;
    }

    public static final List<String> STATUSES_WHERE_ORDER_CREATION_ALLOWED {
        get {
            if (STATUSES_WHERE_ORDER_CREATION_ALLOWED == null) {
                STATUSES_WHERE_ORDER_CREATION_ALLOWED = ACCOUNT_SETTING.StatusesWhereOrderCreationAllowed__c .split(',');
            }
            return STATUSES_WHERE_ORDER_CREATION_ALLOWED;
        }
        set;
    }

    public static final Map<String, AccountStatusUpdateSetting__mdt> ACC_STATUS_UPDATE_SETTINGS {
        get {
            if (ACC_STATUS_UPDATE_SETTINGS == null) {
                ACC_STATUS_UPDATE_SETTINGS = new Map<String, AccountStatusUpdateSetting__mdt>();
                for (AccountStatusUpdateSetting__mdt setting : AccountStatusUpdateSetting__mdt.getAll().values()) {
                    ACC_STATUS_UPDATE_SETTINGS.put(setting.AccountFrequency__c, setting);
                }
            }
            return ACC_STATUS_UPDATE_SETTINGS;
        }
        set;
    }

    public static final Set<String> DEFAULT_PRICE_BOOKS {
        get {
            if (DEFAULT_PRICE_BOOKS == null) {
                DEFAULT_PRICE_BOOKS = new Set<String>(ACCOUNT_SETTING.DefaultPriceBookNames__c.split(','));
            }
            return DEFAULT_PRICE_BOOKS;
        }
        set;
    }

    public static void copyContactDetailsFromPrimaryContact(List<Account> newAccounts) {
        Set<Id> primaryContactIds = new Set<Id>();
        for (Account newAccount : newAccounts) {
            primaryContactIds.add(newAccount.aforza__Primary_Contact__c);
        }
        primaryContactIds.remove(null);

        Map<Id, Contact> primaryContacts = new Map<Id, Contact>([
                SELECT Id, Email, Phone
                FROM Contact
                WHERE Id IN :primaryContactIds
        ]);

        for (Account newAccount : newAccounts) {
            Contact primaryContact = primaryContacts.get(newAccount.aforza__Primary_Contact__c);
            newAccount.Phone = primaryContact?.Phone;
            newAccount.Email__c = primaryContact?.Email;
        }
    }

    public static void removeRolesFromAccountTeam(Set<Id> accountsIds, List<String> rolesToRemove) {
        List<AccountTeamMember> teamMembersToDelete = [
                SELECT Id
                FROM AccountTeamMember
                WHERE AccountId IN :accountsIds AND TeamMemberRole IN :rolesToRemove
        ];
        delete teamMembersToDelete;
    }

    public static void updateLastOrderDateAndAccountStatus(Set<Id> accountIds) {
        List<Account> accToUpdateLastOrderDate = getAccountsWithLastCompletedOrder(accountIds);

        List<Account> accountsWithUpdatedLastOrderDate = new List<Account>();
        for (Account newAccount :  accToUpdateLastOrderDate) {
            Order lastOrder = newAccount.Orders.isEmpty() ? null : newAccount.Orders.get(0);
            if (newAccount.LastOrderDate__c != lastOrder?.EffectiveDate) {
                newAccount.LastOrderDate__c = lastOrder?.EffectiveDate;
                accountsWithUpdatedLastOrderDate.add(newAccount);
            }
        }

        updateAccountStatusBasedOnLastOrderDate(accountsWithUpdatedLastOrderDate);

        update accountsWithUpdatedLastOrderDate;
    }

    public static List<Account> updateAccountStatusBasedOnLastOrderDate(List<Account> newAccounts) {
        List<Account> accountsWithUpdatedStatus = new List<Account>();

        for (Account newAccount : newAccounts) {
            AccountStatusUpdateSetting__mdt setting = ACC_STATUS_UPDATE_SETTINGS.get(newAccount.Frequency__c);

            if (setting == null) {
                continue;
            }

            if (newAccount.LastOrderDate__c == null) {
                continue;
            }

            if (CommonUtility.isMoreThanXWeeksAgo(newAccount.LastOrderDate__c, Integer.valueOf(setting.NoOfWeeksNoOrdersUpperLimit__c)) &&
                newAccount.AccountStatus__c != setting.UpdatedAccountStatusUpperLimit__c) {
                    newAccount.AccountStatus__c = setting.UpdatedAccountStatusUpperLimit__c;
                    accountsWithUpdatedStatus.add(newAccount);
                    continue;
            }

            if (CommonUtility.isMoreThanXWeeksAgo(newAccount.LastOrderDate__c, Integer.valueOf(setting.NoOfWeeksNoOrdersMidLimit__c)) &&
                newAccount.AccountStatus__c != setting.UpdatedAccountStatusMidLimit__c) {
                    newAccount.AccountStatus__c = setting.UpdatedAccountStatusMidLimit__c;
                    accountsWithUpdatedStatus.add(newAccount);
                    continue;
            }

            if (CommonUtility.isMoreThanXWeeksAgo(newAccount.LastOrderDate__c, Integer.valueOf(setting.NoOfWeeksNoOrdersLowerLimit__c)) &&
                newAccount.AccountStatus__c != setting.UpdatedAccountStatusLowerLimit__c) {
                    newAccount.AccountStatus__c = setting.UpdatedAccountStatusLowerLimit__c;
                    accountsWithUpdatedStatus.add(newAccount);
                    continue;
            }

            newAccount.AccountStatus__c = setting.UpdatedAccountStatusRecentOrders__c;
            accountsWithUpdatedStatus.add(newAccount);
        }

        return accountsWithUpdatedStatus;
    }

    private static List<Account> getAccountsWithLastCompletedOrder(Set<Id> accountIds) {
        List<Account> accountsWithLastOrder = [
                SELECT Id, LastOrderDate__c, Frequency__c, AccountStatus__c,
                (
                        SELECT Id, EffectiveDate
                        FROM Orders
                        WHERE Status IN :OrderService.COMPLETED_ORDER_STATUSES AND RecordType.DeveloperName IN :OrderService.RECORD_TYPES_TO_UPDATE_ACCOUNT_ON_ORDER_COMPLETION
                        ORDER BY EffectiveDate DESC
                        LIMIT 1
                )
                FROM Account
                WHERE Id IN :accountIds
        ];

        return accountsWithLastOrder;
    }

    public static Boolean accountStatusRequiresAccountTeamMembershipUpdate(String status) {
        return STATUSES_TO_REM_ROLES_FROM_ACCOUNT_TEAM.contains(status);
    }
}