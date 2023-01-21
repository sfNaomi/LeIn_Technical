/**
 * Created by svatopluk.sejkora on 01.10.2022.
 */

public with sharing class AccountTeamMemberTriggerHandler {
    private static final String TAM_ROLE_NAME = 'TAM';
    private static final String FIELD_SALES_REP_ROLE_NAME = 'Field Sales Rep';
    private static final String DRIVER_ROLE_NAME = 'Driver';

    private static final String EDIT_ACCESS_LEVEL = 'Edit';

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

        List<RecurringRecordService.AccountToTamDto> accountsToTamToHandleRecurringRecordFor = new List<RecurringRecordService.AccountToTamDto>();
        if (relatedAccounts.size() > 0) {
            for (Account acc : fetchValidAccountsForTeamRoles(relatedAccounts)) {
                RecurringRecordService.AccountToTamDto accountToTamDto = new RecurringRecordService.AccountToTamDto(acc, teamMemberAccountIdToUserIdMap.get(acc.Id));
                accountsToTamToHandleRecurringRecordFor.add(accountToTamDto);
            }
        }

        if (accountTeamMembersForDeletion.size() > 0) {
            deleteReoccurrenceRecord(accountTeamMembersForDeletion);
        }

        RecurringRecordService.upsertRecurringRecords(accountsToTamToHandleRecurringRecordFor);
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
     * @description checks that only one user with a specified role can be added to the account team of an account
     *
     * @param newAccountTeamMembers list with new team members
     *
     * @author Svata Sejkora
     * @date 2022-10-01
     */
    public static void allowOnlyOneUserWithSpecifiedRolePerAccount(List<AccountTeamMember> newAccountTeamMembers) {
        // roles for which only one account team member is allowed
        final Set<String> UNIQUE_ROLES = new Set<String>{TAM_ROLE_NAME, DRIVER_ROLE_NAME};

        // accounts ids to team roles by count
        Map<Id, Map<String, Integer>> accountIdsInCurrentOperation = buildRolesCountMapForAccounts(newAccountTeamMembers, UNIQUE_ROLES);

        // get existing team members for verified roles
        Map<Id, Account> accountWithTeamMembers = getAccountsWithTeamMembersHavingSpecifiedRoles(accountIdsInCurrentOperation.keySet(), UNIQUE_ROLES);

        // build helper maps
        Map<Id, Map<String, AccountTeamMember>> accountIdsWithExistingUserRoles = new Map<Id, Map<String, AccountTeamMember>>();
        for (Account newAccount : accountWithTeamMembers.values()) {
            Map<String, AccountTeamMember> existingUserRoles = new Map<String, AccountTeamMember>();
            for (AccountTeamMember member : newAccount.AccountTeamMembers) {
                existingUserRoles.put(member.TeamMemberRole, member);
            }
            accountIdsWithExistingUserRoles.put(newAccount.Id, existingUserRoles);
        }

        Map<Id, AccountTeamMember> newAccountTeamMembersMap = new Map<Id, AccountTeamMember>();
        for (AccountTeamMember accountTeamMember : newAccountTeamMembers) {
            if (accountTeamMember.Id != null) {
                newAccountTeamMembersMap.put(accountTeamMember.Id, accountTeamMember);
            }
        }

        // check if multiple users with the same role have been inserted/updated for an account
        for (AccountTeamMember accountTeamMember : newAccountTeamMembers) {
            Id accountId = accountTeamMember.AccountId;
            String userRole = accountTeamMember.TeamMemberRole;

            if (!UNIQUE_ROLES.contains(userRole)) {
                continue;
            }

            String errorMessage = String.format(Label.DuplicateTeamMemberRole, new List<String>{userRole});

            if (accountIdsInCurrentOperation.get(accountId).get(userRole) > 1) {
                accountTeamMember.addError(errorMessage);
            }

            // check for following edge case: we have a field sales rep account team member and in one transaction, we
            // update the role of the existing field sales rep to field sales rep manager + insert a new fields sales rep
            // no error should be thrown, as in the end, the account will only have one field sales rep
            AccountTeamMember existingMemberWithSameRole = accountIdsWithExistingUserRoles?.get(accountId)?.get(userRole);
            if (existingMemberWithSameRole != null && existingMemberWithSameRole.Id != accountTeamMember.Id) {
                AccountTeamMember existingMemberInCurrentTransaction = newAccountTeamMembersMap?.get(existingMemberWithSameRole.Id);

                if (existingMemberInCurrentTransaction == null ||
                    (existingMemberInCurrentTransaction != null && existingMemberInCurrentTransaction.TeamMemberRole == existingMemberWithSameRole.TeamMemberRole)
                ) {
                    accountTeamMember.addError(errorMessage);
                }
            }
        }
    }

    /**
    * @description copy information from team members with relevant roles (e.g. driver, field sales rep) to accounts
    *
    * @param modifiedTeamMembers list of modified account team members (inserted/updated/deleted)
    *
    * @author Magdalena Stanciu
    * @date 2022-11-15
    */
	public static void copyInformationFromAccountTeamMemberToAccount(List<AccountTeamMember> modifiedTeamMembers){
        // relevant roles
        final Set<String> ROLES_TO_UPDATE_ACCOUNTS = new Set<String>{FIELD_SALES_REP_ROLE_NAME, DRIVER_ROLE_NAME};

        // get accounts ids to query existing data
        Set<Id> accountIdsInCurrentOperation = new Set<Id>();
        for (AccountTeamMember newAccountTeamMember : modifiedTeamMembers) {
            accountIdsInCurrentOperation.add(newAccountTeamMember.AccountId);
        }

        // get existing team members for verified roles
        Map<Id, Account> accountWithTeamMembers = getAccountsWithTeamMembersHavingSpecifiedRoles(accountIdsInCurrentOperation, ROLES_TO_UPDATE_ACCOUNTS);

        // build helper maps
        Map<Account, Map<String, List<AccountTeamMember>>> accountIdsWithExistingUserRoles = buildAccountTeamMembersByAccountIdsAndRoles(accountWithTeamMembers.values());

        // copy information from account team members to accounts and update accounts (where needed)
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        for (Account newAccount : accountIdsWithExistingUserRoles.keySet()) {
            // driver name
            List<AccountTeamMember> drivers = accountIdsWithExistingUserRoles.get(newAccount).get(DRIVER_ROLE_NAME);
            String driverName = '';
            if (drivers != null) {
                driverName = drivers.get(0).User.Name;
            }

            // field sales rep ids
            List<AccountTeamMember> fieldSalesReps = accountIdsWithExistingUserRoles.get(newAccount).get(FIELD_SALES_REP_ROLE_NAME);
            String fieldSalesRepIds = '';
            if (fieldSalesReps != null) {
                for (AccountTeamMember teamMember : fieldSalesReps) {
                    if (teamMember.AccountAccessLevel == EDIT_ACCESS_LEVEL) {
                        fieldSalesRepIds += teamMember.UserId + ';';
                    }
                }
            }

            if (newAccount.DriverName__c != driverName || newAccount.FieldSalesRepId__c != fieldSalesRepIds) {
                Account accountToUpdate = accountsToUpdate.get(newAccount.Id);
                if (accountToUpdate == null) {
                    accountToUpdate = new Account(Id = newAccount.Id);
                }

                accountToUpdate.DriverName__c = driverName;
                accountToUpdate.FieldSalesRepId__c = fieldSalesRepIds;

                accountsToUpdate.put(accountToUpdate.Id, accountToUpdate);
            }
        }

        update accountsToUpdate.values();
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
            SELECT Id, OwnerId, Frequency__c, /*DeliveryPointReference__c,*/ PrimaryStartDate__c, SecondaryStartDate__c,
                    CallPriority__c, PrimaryCallDay__c, SecondaryCallDay__c, PrimaryGridNumber__c, SecondaryGridNumber__c,
                    CreateCalls__c, AccountStatus__c, RecordTypeId, PreferredCallTimeTelesales__c
            FROM Account
            WHERE Id IN :accountIds
        ]) {
            if (account.CreateCalls__c && AccountTriggerHandler.VISIT_STATUSES.contains(account.AccountStatus__c) &&
                account.RecordTypeId == RecordTypes.ACCOUNT_OUTLET_ID && String.isNotEmpty(account.PrimaryGridNumber__c) &&
                account.PrimaryStartDate__c != null
            ) {
                validAccountsForTeams.add(account);
            }
        }
        return validAccountsForTeams;
    }

    /**
     * @description fetches accounts with their team members to a map (retrieves only members having roles which should be unique within the team)
     *
     * @param accountIds list with new team members
     * @param roles list pf roles
     *
     * @return map of Account IDs to team members
     *
     * @author Svata Sejkora
     * @date 2022-10-01
     */
    private static Map<Id, Account> getAccountsWithTeamMembersHavingSpecifiedRoles(Set<Id> accountIds, Set<String> roles) {
        Map<Id, Account> accountsWithTeamMembers = new Map<Id, Account>([
            SELECT Id, FieldSalesRepId__c, DriverName__c, (
                SELECT Id, TeamMemberRole, UserId, User.Name, AccountAccessLevel
                FROM AccountTeamMembers
                WHERE TeamMemberRole IN :roles
                ORDER BY UserId
            )
            FROM Account
            WHERE Id IN :accountIds
        ]);
        return accountsWithTeamMembers;
    }

    /**
    * @description builds a helper map from a list of account team members
    *
    * @param newAccounts list of accounts
    *
    * @return map of accounts with team members by roles
    *
    * @author Magdalena Stanciu
    * @date 2022-11-15
    */
    private static Map<Account, Map<String, List<AccountTeamMember>>> buildAccountTeamMembersByAccountIdsAndRoles(List<Account> newAccounts) {
        Map<Account, Map<String, List<AccountTeamMember>>> accountsWithTeamMembersByRoles = new Map<Account, Map<String, List<AccountTeamMember>>>();
        for (Account newAccount : newAccounts) {
            Map<String, List<AccountTeamMember>> teamMembersByRoles = new Map<String, List<AccountTeamMember>>();
            for (AccountTeamMember member : newAccount.AccountTeamMembers) {
                List<AccountTeamMember> teamMembers = teamMembersByRoles.get(member.TeamMemberRole);
                if (teamMembers == null) {
                    teamMembers = new List<AccountTeamMember>();
                }
                teamMembers.add(member);
                teamMembersByRoles.put(member.TeamMemberRole, teamMembers);
            }
            accountsWithTeamMembersByRoles.put(newAccount, teamMembersByRoles);
        }
        return accountsWithTeamMembersByRoles;
    }

    /**
    * @description builds a helper map from a list of account team members
    *
    * @param teamMembers list of team members
    * @param roles set of relevant roles
    *
    * @return map with accounts ids as keys to roles by count
    *
    * @author Magdalena Stanciu
    * @date 2022-11-15
    */
    private static Map<Id, Map<String, Integer>> buildRolesCountMapForAccounts(List<AccountTeamMember> teamMembers, Set<String> roles) {
        Map<Id, Map<String, Integer>> accountIdsInCurrentOperation = new Map<Id, Map<String, Integer>>();
        for (AccountTeamMember accountTeamMember : teamMembers) {
            if (roles.contains(accountTeamMember.TeamMemberRole)) {

                Id accountId = accountTeamMember.AccountId;
                String userRole = accountTeamMember.TeamMemberRole;

                Map<String, Integer> actualCountByRole = accountIdsInCurrentOperation.get(accountId);
                if (actualCountByRole == null) {
                    actualCountByRole = new Map<String, Integer>();
                }

                Integer actualCount = actualCountByRole.get(userRole) == null ? 0 : actualCountByRole.get(userRole);

                actualCountByRole.put(userRole, ++actualCount);
                accountIdsInCurrentOperation.put(accountId, actualCountByRole);
            }
        }
        return accountIdsInCurrentOperation;
    }
}