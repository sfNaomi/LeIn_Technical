/**
 * @description       : Service class implementing account specific operations
 **/

public with sharing class AccountService {
    public static final AccountStatusUpdateSetting__mdt STATUS_UPDATE_SETTING {
        get {
            if (STATUS_UPDATE_SETTING == null) {
                STATUS_UPDATE_SETTING = AccountStatusUpdateSetting__mdt.getInstance('ORG_DEFAULT');
            }
            return STATUS_UPDATE_SETTING;
        }
        set;
    }

    public static final List<String> ROLES_TO_BE_REMOVED_FROM_ACCOUNT_TEAM {
        get {
            if (ROLES_TO_BE_REMOVED_FROM_ACCOUNT_TEAM == null) {
                ROLES_TO_BE_REMOVED_FROM_ACCOUNT_TEAM = STATUS_UPDATE_SETTING.RolesToBeRemovedFromAccountTeam__c.split(',');
            }
            return ROLES_TO_BE_REMOVED_FROM_ACCOUNT_TEAM;
        }
        set;
    }

    public static final List<String> ACC_STATUSES_TO_REM_ROLES_FROM_ACCOUNT_TEAM {
        get {
            if (ACC_STATUSES_TO_REM_ROLES_FROM_ACCOUNT_TEAM == null) {
                ACC_STATUSES_TO_REM_ROLES_FROM_ACCOUNT_TEAM = STATUS_UPDATE_SETTING.AccStatusesToRemRolesFromAcctTeam__c.split(',');
            }
            return ACC_STATUSES_TO_REM_ROLES_FROM_ACCOUNT_TEAM;
        }
        set;
    }

    public static final List<String> ACC_STATUSES_TO_UPDATE_ON_NEW_ORDER {
        get {
            if (ACC_STATUSES_TO_UPDATE_ON_NEW_ORDER == null) {
                ACC_STATUSES_TO_UPDATE_ON_NEW_ORDER = STATUS_UPDATE_SETTING.AccStatusesToUpdateOnNewOrder__c.split(',');
            }
            return ACC_STATUSES_TO_UPDATE_ON_NEW_ORDER;
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

    public static List<Account> getAccountsWhichRequireStatusUpdateOnOrderCreation(Set<Id> accIds) {
        List<Account> accountsToUpdateStatusAfterOrderCreation = [
                SELECT Id, Accountstatus__c
                FROM Account
                WHERE Id IN :accIds AND AccountStatus__c IN :ACC_STATUSES_TO_UPDATE_ON_NEW_ORDER
        ];
        updateStatus(accountsToUpdateStatusAfterOrderCreation, STATUS_UPDATE_SETTING.NewAccStatusOnNewOrder__c);
        return accountsToUpdateStatusAfterOrderCreation;
    }

    private static void updateStatus(List<Account> newAccounts, String newStatus) {
        for (Account newAccount : newAccounts) {
            newAccount.AccountStatus__c = newStatus;
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
}