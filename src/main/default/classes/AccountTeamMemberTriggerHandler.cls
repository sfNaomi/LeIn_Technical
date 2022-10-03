/**
 * Created by svatopluk.sejkora on 01.10.2022.
 */

public with sharing class AccountTeamMemberTriggerHandler {

    private static final String TAM_ROLE_NAME = 'TAM';


    /**
     * @description prepares data and checks them if the recurring record should be updated. On account team a user cannot be changed,
     * so we are not checking that option.
     *
     * @param newMembers list of new or updated account team members
     * @param oldMembersMap map with old values
     *
     * @author Svata Sejkora
     * @date 2022-10-01
     */
    public static void manageReoccurrenceRecord(List<AccountTeamMember> newMembers, Map<Id, AccountTeamMember> oldMembersMap) {
        // determine context of the trigger and check for conditions
        Set<Id> relatedAccounts = new Set<Id>();
        Map<Id, Id> teamMemberAccountIdToUserIdMap = new Map<Id, Id>();
        Map<Id, AccountTeamMember> accountTeamMembersForDeletion = new Map<Id, AccountTeamMember>();
        for (AccountTeamMember teamMember : newMembers) {
            if (teamMember.TeamMemberRole == TAM_ROLE_NAME && oldMembersMap == null || teamMember.TeamMemberRole == TAM_ROLE_NAME &&
                    teamMember.TeamMemberRole <> oldMembersMap.get(teamMember.Id).TeamMemberRole) {
                relatedAccounts.add(teamMember.AccountId);
                teamMemberAccountIdToUserIdMap.put(teamMember.AccountId, teamMember.UserId);
                // if the role was TAM role but is not any more
            } else if (oldMembersMap <> null && teamMember.TeamMemberRole <> TAM_ROLE_NAME && oldMembersMap.get(teamMember.Id).TeamMemberRole == TAM_ROLE_NAME) {
                accountTeamMembersForDeletion.put(teamMember.Id, teamMember);
            }
        }

        List<Account> accountsToHandleRecurringRecordFor = new List<Account>();
        if (relatedAccounts.size() > 0) {
            for (Account acc : fetchValidAccountsForTeamRoles(relatedAccounts)) {
                acc.OwnerId = teamMemberAccountIdToUserIdMap.get(acc.Id);
                accountsToHandleRecurringRecordFor.add(acc);
            }
        }
        if (accountTeamMembersForDeletion.size() > 0) {
            deleteReoccurrenceRecord(accountTeamMembersForDeletion);
        }

        RecurringRecordService.upsertRecurringRecords(accountsToHandleRecurringRecordFor);
    }

    /**
     * @description prepares data and checks them if the recurring record should be updated with no TAM name.
     *
     * @param oldMembersMap map with old values
     *
     * @author Svata Sejkora
     * @date 2022-10-01
     */
    public static void deleteReoccurrenceRecord(Map<Id, AccountTeamMember> oldMembersMap) {
        Set<Id> accountIds = new Set<Id>();
        for (AccountTeamMember accountTeamMember : oldMembersMap.values()) {
            accountIds.add(accountTeamMember.AccountId);
        }

        RecurringRecordService.deleteRecurringAndVisitRecords(accountIds);
    }

    /**
     * @description checks that only one team member would be allowed to be created for any one record
     *
     * @param newAccountTeamMembers list with new team members
     *
     * @author Svata Sejkora
     * @date 2022-10-01
     */
    public static void allowOnlyOneTamUserPerAccount(List<AccountTeamMember> newAccountTeamMembers) {
        Map<Id, Integer> accountIdsInCurrentOperation = new Map<Id, Integer>();

        for (AccountTeamMember accountTeamMember : newAccountTeamMembers) {
            if (accountTeamMember.TeamMemberRole == TAM_ROLE_NAME) {
                Id accountId = accountTeamMember.AccountId;
                //checking for adding multiple tams within single operation
                if (accountIdsInCurrentOperation.containsKey(accountId)) {
                    Integer actualCount = accountIdsInCurrentOperation.get(accountId) + 1;
                    accountIdsInCurrentOperation.put(accountId, actualCount);
                } else {
                    accountIdsInCurrentOperation.put(accountId, 1);
                }
            }
        }
        // get accounts for current team members and check if there are any TAMs already
        Map<Id, Account> accountsWithTeamMembers = new Map<Id, Account>();
        if (accountIdsInCurrentOperation.size() > 0) {
            accountsWithTeamMembers = getAccountsWithTamTeamMembers(accountIdsInCurrentOperation.keySet());
        }

        if (accountIdsInCurrentOperation.size() > 0) {
            for (AccountTeamMember accountTeamMember : newAccountTeamMembers) {
                Id accountId = accountTeamMember.AccountId;
                if (accountIdsInCurrentOperation.get(accountId) > 1 || accountsWithTeamMembers.get(accountId).AccountTeamMembers.size() > 0) {
                    accountTeamMember.addError(Label.DuplicateTamRoleError);
                }
            }
        }
    }

    /**
     * @description fetches accounts with their tea members to a map. Only gets Team member when the role is TAM
     *
     * @param accountIds list with new team members
     *
     * @return map of Account IDs to Accounts
     *
     * @author Svata Sejkora
     * @date 2022-10-01
     */
    private static Map<Id, Account> getAccountsWithTamTeamMembers(Set<Id> accountIds) {
        Map<Id, Account> accountsByIds = new Map<Id, Account>([
                SELECT Id, (
                        SELECT Id
                        FROM AccountTeamMembers
                        WHERE TeamMemberRole = :TAM_ROLE_NAME
                )
                FROM Account
                WHERE Id IN :accountIds
        ]);
        return accountsByIds;
    }

    /**
     * @description fetches account for triggered team members. Gets only Accounts that are valid for recurring record creation.
     *
     * @param accountIds set of account Ids to get info for
     *
     * @return accounts - list of accounts based on conditions
     *
     * @author Svata Sejkora
     * @date 2022-10-01
     */
    private static List<Account> fetchValidAccountsForTeamRoles(Set<Id> accountIds) {
        List<Account> validAccountsForTeams = new List<Account>();
        for (Account account : [
                SELECT Id, OwnerId, Frequency__c, DeliveryPointReference__c, PrimaryStartDate__c, SecondaryStartDate__c,
                        CallPriority__c, PrimaryCallDay__c, SecondaryCallDay__c, PrimaryGridNumber__c, SecondaryGridNumber__c,
                        CreateCalls__c, AccountStatus__c, RecordTypeId
                FROM Account
                WHERE Id IN :accountIds
        ]) {
            if (account.CreateCalls__c &&
                    AccountTriggerHandler.VISIT_STATUSES.contains(account.AccountStatus__c) &&
                    account.RecordTypeId == RecordTypes.ACCOUNT_OUTLET_ID &&
                    String.isNotEmpty(account.PrimaryGridNumber__c) &&
                    account.PrimaryStartDate__c != null
            ) {
                validAccountsForTeams.add(account);
            }
        }
        return validAccountsForTeams;
    }
}