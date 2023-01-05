/**
 * @description       : Service class implementing account specific operations
 **/

public with sharing class AccountService {
    @TestVisible private static Date today = System.today();

    public static final AccountSetting__mdt ACCOUNT_SETTING {
      get {
        if (ACCOUNT_SETTING == null) {
          ACCOUNT_SETTING = AccountSetting__mdt.getInstance('OrgDefaultAccountSettings');
        }
        return ACCOUNT_SETTING;
      }
      set;
    }
  
    public static final List <String> ROLES_TO_BE_REMOVED_FROM_ACCOUNT_TEAM {
      get {
        if (ROLES_TO_BE_REMOVED_FROM_ACCOUNT_TEAM == null) {
          ROLES_TO_BE_REMOVED_FROM_ACCOUNT_TEAM = ACCOUNT_SETTING.RolesToBeRemovedFromAccountTeam__c.split(',');
        }
        return ROLES_TO_BE_REMOVED_FROM_ACCOUNT_TEAM;
      }
      set;
    }
  
    public static final List <String> STATUSES_TO_REM_ROLES_FROM_ACCOUNT_TEAM {
      get {
        if (STATUSES_TO_REM_ROLES_FROM_ACCOUNT_TEAM == null) {
          STATUSES_TO_REM_ROLES_FROM_ACCOUNT_TEAM = ACCOUNT_SETTING.StatusesToUpdateTeamMembership__c.split(',');
        }
        return STATUSES_TO_REM_ROLES_FROM_ACCOUNT_TEAM;
      }
      set;
    }
  
    public static final List <String> STATUSES_TO_UPDATE_WHEN_NO_RECENT_ORDERS {
      get {
        if (STATUSES_TO_REM_ROLES_FROM_ACCOUNT_TEAM == null) {
          STATUSES_TO_REM_ROLES_FROM_ACCOUNT_TEAM = ACCOUNT_SETTING.StatusesToUpdateWhenNoRecentOrders__c.split(',');
        }
        return STATUSES_TO_REM_ROLES_FROM_ACCOUNT_TEAM;
      }
      set;
    }
  
    public static final List <String> STATUSES_WHERE_ORDER_CREATION_ALLOWED {
      get {
        if (STATUSES_WHERE_ORDER_CREATION_ALLOWED == null) {
          STATUSES_WHERE_ORDER_CREATION_ALLOWED = ACCOUNT_SETTING.StatusesWhereOrderCreationAllowed__c.split(',');
        }
        return STATUSES_WHERE_ORDER_CREATION_ALLOWED;
      }
      set;
    }
  
    public static final String STATUSES_WHERE_ORDER_ACTIVATION_IS_NOT_ALLOWED {
      get {
        if (STATUSES_WHERE_ORDER_ACTIVATION_IS_NOT_ALLOWED == null) {
          STATUSES_WHERE_ORDER_ACTIVATION_IS_NOT_ALLOWED = ACCOUNT_SETTING.CreditStatusesOrderActiveNotAllowed__c;
        }
        return STATUSES_WHERE_ORDER_ACTIVATION_IS_NOT_ALLOWED;
      }
      set;
    }

    public static final List <String> STATUSES_TO_UPDATE_NEXT_DELIVERY_DATE {
        get {
            if (STATUSES_TO_UPDATE_NEXT_DELIVERY_DATE == null) {
                STATUSES_TO_UPDATE_NEXT_DELIVERY_DATE = ACCOUNT_SETTING.StatusesToUpdateNextDeliveryDate__c.split(',');
            }
            return STATUSES_TO_UPDATE_NEXT_DELIVERY_DATE;
        }
        set;
    }
  
    public static final Map <String, AccountStatusUpdateSetting__mdt> ACC_STATUS_UPDATE_SETTINGS {
      get {
        if (ACC_STATUS_UPDATE_SETTINGS == null) {
          ACC_STATUS_UPDATE_SETTINGS = new Map <String, AccountStatusUpdateSetting__mdt> ();
          for (AccountStatusUpdateSetting__mdt setting: AccountStatusUpdateSetting__mdt.getAll().values()) {
            ACC_STATUS_UPDATE_SETTINGS.put(setting.AccountFrequency__c, setting);
          }
        }
        return ACC_STATUS_UPDATE_SETTINGS;
      }
      set;
    }
  
    public static final Set <String> DEFAULT_PRICE_BOOKS {
      get {
        if (DEFAULT_PRICE_BOOKS == null) {
          DEFAULT_PRICE_BOOKS = new Set <String> (ACCOUNT_SETTING.DefaultPriceBookNames__c.split(','));
        }
        return DEFAULT_PRICE_BOOKS;
      }
      set;
    }
  
    /**
     * @description copies information on account from primary contact (email, phone)
     *
     * @param newAccounts list with new versions of the account records
     *
     * @return N/A
     *
     * @author Magdalena Stanciu
     * @date 2022-10-10
     */
    public static void copyContactDetailsFromPrimaryContact(List <Account> newAccounts) {
      Set <Id> primaryContactIds = new Set <Id> ();
      for (Account newAccount: newAccounts) {
        primaryContactIds.add(newAccount.aforza__Primary_Contact__c);
      }
      primaryContactIds.remove(null);
  
      Map <Id, Contact> primaryContacts = new Map <Id, Contact> ([
        SELECT Id, Email, Phone
        FROM Contact
        WHERE Id IN: primaryContactIds
      ]);
  
      for (Account newAccount: newAccounts) {
        Contact primaryContact = primaryContacts.get(newAccount.aforza__Primary_Contact__c);
        newAccount.Phone = primaryContact?.Phone;
        newAccount.Email__c = primaryContact?.Email;
      }
    }
  
    /**
     * @description removes users with specified roles from the account team of the specified accounts
     *
     * @param accountsIds ids of accounts to remove users from
     * @param rolesToRemove roles of users to be removed from the account teams
     *
     * @return N/A
     *
     * @author Magdalena Stanciu
     * @date 2022-10-10
     */
    public static void removeRolesFromAccountTeam(Set <Id> accountsIds, List <String> rolesToRemove) {
      List <AccountTeamMember> teamMembersToDelete = [
        SELECT Id
        FROM AccountTeamMember
        WHERE AccountId IN: accountsIds AND TeamMemberRole IN: rolesToRemove
      ];
      delete teamMembersToDelete;
    }
  
    /**
     * @description updates last order date and status on account
     *
     * @param accountsIds ids of accounts to be updated
     *
     * @return N/A
     *
     * @author Magdalena Stanciu
     * @date 2022-10-10
     */
    public static void updateLastOrderDateAndAccountStatus(Set <Id> accountIds) {
      List <Account> accToUpdateLastOrderDate = getAccountsWithLastCompletedOrder(accountIds);
  
      List <Account> accountsWithUpdatedLastOrderDate = new List <Account> ();
      for (Account newAccount: accToUpdateLastOrderDate) {
        Order lastOrder = newAccount.Orders.isEmpty() ? null : newAccount.Orders.get(0);
        if (newAccount.LastOrderDate__c != lastOrder?.EffectiveDate) {
          newAccount.LastOrderDate__c = lastOrder?.EffectiveDate;
          accountsWithUpdatedLastOrderDate.add(newAccount);
        }
      }
  
      updateAccountStatusBasedOnLastOrderDate(accountsWithUpdatedLastOrderDate);
  
      update accountsWithUpdatedLastOrderDate;
    }
  
    /**
     * @description updates status on account based on last order date
     *
     * @param newAccounts accounts to be updated
     *
     * @return List<Account> updated accounts
     *
     * @author Magdalena Stanciu
     * @date 2022-10-10
     */
    public static List <Account> updateAccountStatusBasedOnLastOrderDate(List <Account> newAccounts) {
      List <Account> accountsWithUpdatedStatus = new List <Account> ();
  
      for (Account newAccount: newAccounts) {
        AccountStatusUpdateSetting__mdt setting = ACC_STATUS_UPDATE_SETTINGS.get(newAccount.Frequency__c);
  
        if (setting == null) {
          continue;
        }
  
        if (newAccount.LastOrderDate__c == null) {
          continue;
        }
  
        if (CommonUtility.isMoreThanXWeeksAgo(newAccount.LastOrderDate__c, Integer.valueOf(setting.NoOfWeeksNoOrdersUpperLimit__c))) {
          if (newAccount.AccountStatus__c != setting.UpdatedAccountStatusUpperLimit__c) {
            newAccount.AccountStatus__c = setting.UpdatedAccountStatusUpperLimit__c;
            accountsWithUpdatedStatus.add(newAccount);
          }
          continue;
        }
  
        if (CommonUtility.isMoreThanXWeeksAgo(newAccount.LastOrderDate__c, Integer.valueOf(setting.NoOfWeeksNoOrdersMidLimit__c))) {
          if (newAccount.AccountStatus__c != setting.UpdatedAccountStatusMidLimit__c) {
            newAccount.AccountStatus__c = setting.UpdatedAccountStatusMidLimit__c;
            accountsWithUpdatedStatus.add(newAccount);
          }
          continue;
        }
  
        if (CommonUtility.isMoreThanXWeeksAgo(newAccount.LastOrderDate__c, Integer.valueOf(setting.NoOfWeeksNoOrdersLowerLimit__c))) {
          if (newAccount.AccountStatus__c != setting.UpdatedAccountStatusLowerLimit__c) {
            newAccount.AccountStatus__c = setting.UpdatedAccountStatusLowerLimit__c;
            accountsWithUpdatedStatus.add(newAccount);
          }
          continue;
        }
  
        newAccount.AccountStatus__c = setting.UpdatedAccountStatusRecentOrders__c;
        accountsWithUpdatedStatus.add(newAccount);
      }
  
      return accountsWithUpdatedStatus;
    }

    /**
     * @description computes next delivery date for an account
     *
     * @param newAccount account to compute next delivery date for
     *
     * @return Date updated delivery date
     *
     * @author Magdalena Stanciu
     * @date 2023-01-03
     */
    public static Date computeNextDeliveryDate(Account newAccount) {
        if (newAccount.PrimaryStartDate__c == null || newAccount.Frequency__c == null || newAccount.PrimaryDeliveryDay__c == null) {
            return null;
        }

        // frequency of deliveries
        Map<String, Integer> frequencyMap = new Map<String, Integer>{'W' => 7, 'F' => 14, 'M' => 28};
        Integer frequency = frequencyMap.get(newAccount.Frequency__c);

        // next delivery week day
        Integer deliveryWeekDay = getDeliveryWeekDay(newAccount);

        // reference date based on which the next delivery date is calculated
        Date referenceDate = newAccount.PrimaryStartDate__c;

        // calculate offset (number of weeks, multiplier of the frequency, between reference date and today)
        Integer daysOffset = 0;
        if (referenceDate < today) {
            Integer noOfDaysSinceReferenceDate = referenceDate.toStartOfWeek().daysBetween(today.toStartOfWeek());
            daysOffset = Integer.valueOf(Math.floor(noOfDaysSinceReferenceDate / frequency)) * frequency;
        }

        // calculate next delivery date
        Date nextDeliveryDate = referenceDate.addDays(daysOffset + deliveryWeekDay - 1);

        // if next delivery date is in the past - add a number of weeks equal to the frequency of deliveries
        if (nextDeliveryDate < today) {
            nextDeliveryDate = nextDeliveryDate.addDays(frequency);
        }

        return nextDeliveryDate;
    }

    /**
     * @description determines the next delivery week day
     *
     * @param newAccount account to determine the next delivery week day for
     *
     * @return Integer next delivery week day
     *
     * @author Magdalena Stanciu
     * @date 2023-01-03
     */
    private static Integer getDeliveryWeekDay(Account newAccount) {
        Integer primaryDeliveryDay = String.isNotBlank(newAccount.PrimaryDeliveryDay__c) ? Integer.valueOf(newAccount.PrimaryDeliveryDay__c)  : null;
        Integer secondaryDeliveryDay = String.isNotBlank(newAccount.SecondaryDeliveryDay__c) ? Integer.valueOf(newAccount.SecondaryDeliveryDay__c)  : Integer.valueOf(newAccount.PrimaryDeliveryDay__c);

        Integer minDeliveryWeekDay = Math.min(primaryDeliveryDay, secondaryDeliveryDay);
        Integer maxDeliveryWeekDay = Math.max(primaryDeliveryDay, secondaryDeliveryDay);

        Date referenceDate = newAccount.PrimaryStartDate__c > today ? newAccount.PrimaryStartDate__c : today;
        Integer referenceWeekDay = referenceDate.toStartOfWeek().daysBetween(referenceDate) + 1;

        if (referenceWeekDay <= minDeliveryWeekDay || referenceWeekDay > maxDeliveryWeekDay) {
            return minDeliveryWeekDay;
        }
        return maxDeliveryWeekDay;
    }
  
    /**
     * @description retrieve accounts with their last completed order
     *
     * @param accountIds account ids to be retrieved
     *
     * @return List<Account> retrieved accounts
     *
     * @author Magdalena Stanciu
     * @date 2022-10-10
     */
    private static List <Account> getAccountsWithLastCompletedOrder(Set <Id> accountIds) {
      List <Account> accountsWithLastOrder = [
        SELECT Id, LastOrderDate__c, Frequency__c, AccountStatus__c,
        (
          SELECT Id, EffectiveDate FROM Orders WHERE Status IN: OrderService.COMPLETED_ORDER_STATUSES AND RecordType.DeveloperName IN: OrderService.RECORD_TYPES_TO_UPDATE_ACCOUNT_ON_ORDER_COMPLETION ORDER BY EffectiveDate DESC LIMIT 1
        )
        FROM Account
        WHERE Id IN: accountIds
      ];
  
      return accountsWithLastOrder;
    }
  
    /**
     * @description checks whether a specific account status should be taken into account for account
     *             team membership automatic updated
     *
     * @param status account status
     *
     * @return Boolean requires the account status automatic update of the account team membership
     *
     * @author Magdalena Stanciu
     * @date 2022-10-10
     */
    public static Boolean accountStatusRequiresAccountTeamMembershipUpdate(String status) {
      return STATUSES_TO_REM_ROLES_FROM_ACCOUNT_TEAM.contains(status);
    }

    public static final UrlMapping__mdt AGENT_MANDATE_URL_MAPPING {
        get {
            if (AGENT_MANDATE_URL_MAPPING == null) {
                AGENT_MANDATE_URL_MAPPING = CommonUtility.getUrlMapping('AGENT_MANDATE_FORM');
            }
            return AGENT_MANDATE_URL_MAPPING;
        }
        set;
    }    
  
    public static final UrlMapping__mdt CUSTOMER_MANDATE_URL_MAPPING {
        get {
            if (CUSTOMER_MANDATE_URL_MAPPING == null) {
                CUSTOMER_MANDATE_URL_MAPPING = CommonUtility.getUrlMapping('CUSTOMER_MANDATE_FORM');
            }
            return CUSTOMER_MANDATE_URL_MAPPING;
        }
        set;
    }
      
    public static Map<Id, Account> getAccountDetailsFromFields(List <String> urlFields,Id accountId) {
      String queryString = 'SELECT ' + String.join(urlFields, ',') + ' FROM Account WHERE Id =: accountId';
      Map<Id, Account> accountObjectFields = new Map<Id, Account>((List<Account>) Database.query(queryString));
    
      return accountObjectFields;
    }
}