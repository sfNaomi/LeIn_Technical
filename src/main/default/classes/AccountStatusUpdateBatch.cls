/**
 * Created by magdalena.stanciu on 13.09.2022.
 */

public with sharing class AccountStatusUpdateBatch implements Database.Batchable<sObject>, Schedulable {
    private Map<Integer, String> orderFrequencyToBeProcessed = new Map<Integer, String>{
            1 => 'W',
            2 => 'F',
            3 => 'M'
    };

    private Integer order {
        get {
            if (order == null) {
                order = 1;
            }
            return order;
        }
        set;
    }

    private AccountStatusUpdateSetting__mdt setting {
        get {
            if (setting == null) {
                setting = AccountService.ACC_STATUS_UPDATE_SETTINGS.get(orderFrequencyToBeProcessed.get(order));
            }
            return setting;
        }
        set;
    }

    public AccountStatusUpdateBatch() {
    }

    private AccountStatusUpdateBatch(Integer order) {
        this.order = order;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        String query = getQuery();
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext context, List<Account> accountsToProcess) {
        List<Account> accountsToUpdate = AccountService.updateAccountStatusBasedOnLastOrderDate(accountsToProcess);
        update accountsToUpdate;
    }

    public void finish(Database.BatchableContext context) {
        Integer nextBatchOrder = order + 1;
        if (nextBatchOrder <= 3) {
            AccountStatusUpdateBatch nextChainedBatch = new AccountStatusUpdateBatch(nextBatchOrder);
            Database.executeBatch(nextChainedBatch);
        }
    }

    public void execute(SchedulableContext context) {
        Database.executeBatch(new AccountStatusUpdateBatch());
    }

    private String getQuery() {
        String accountStatuses = '(\'' + String.join(AccountService.STATUSES_TO_UPDATE_WHEN_NO_RECENT_ORDERS, '\',\'') + '\')';
        String query =
                'SELECT Id, LastOrderDate__c, Frequency__c, AccountStatus__c ' +
                'FROM Account ' +
                'WHERE AccountStatus__c IN ' + accountStatuses + ' ' +
                'AND Frequency__c = \'' + setting.AccountFrequency__c + '\' AND LastOrderDate__c != null AND (' +
                    '(LastOrderDate__c < LAST_N_DAYS:' + (Integer.ValueOf(setting.NoOfWeeksNoOrdersUpperLimit__c) * 7) + ' AND AccountStatus__c != \'' + setting.UpdatedAccountStatusUpperLimit__c + '\') OR ' +
                    '(LastOrderDate__c < LAST_N_DAYS:' + (Integer.ValueOf(setting.NoOfWeeksNoOrdersMidLimit__c) * 7) + ' AND AccountStatus__c != \'' + setting.UpdatedAccountStatusMidLimit__c + '\') OR ' +
                    '(LastOrderDate__c < LAST_N_DAYS:' + (Integer.ValueOf(setting.NoOfWeeksNoOrdersLowerLimit__c) * 7) + ' AND AccountStatus__c != \'' + setting.UpdatedAccountStatusLowerLimit__c + '\') OR ' +
            		'(LastOrderDate__c >= LAST_N_DAYS:' + (Integer.ValueOf(setting.NoOfWeeksNoOrdersLowerLimit__c) * 7) + ' AND AccountStatus__c != \'' + setting.UpdatedAccountStatusRecentOrders__c + '\') ' +
            	')';
        return query;
    }
}