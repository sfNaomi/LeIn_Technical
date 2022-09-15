/**
 * Created by magdalena.stanciu on 13.09.2022.
 */

public with sharing class AccountStatusUpdateBatch implements Database.Batchable<sObject>, Schedulable {
    private Integer batchOrder {
        get {
            if (batchOrder == null) {
                batchOrder = 1;
            }
            return batchOrder;
        }
        set;
    }

    private AccountStatusUpdateBatchSetting__mdt setting {
        get {
            if (setting == null) {
                setting = getSetting(batchOrder);
            }
            return setting;
        }
        set;
    }

    public AccountStatusUpdateBatch() {
    }

    public AccountStatusUpdateBatch(Integer batchOrder) {
        this.batchOrder = batchOrder;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        String query = getQuery();
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext context, List<Account> accountsToProcess) {
        List<Account> accountsToUpdate = new List<Account>();
        for (Account newAccount : accountsToProcess) {
            if (newAccount.Orders.isEmpty()) {
                continue;
            }

            Date lastOrderDate = Date.valueOf(newAccount.Orders[0].CreatedDate);

            if (CommonUtility.isMoreThanXWeeksAgo(lastOrderDate, Integer.valueOf(setting.NoOfWeeksNoOrdersUpperLimit__c))) {
                newAccount.AccountStatus__c = setting.UpdatedAccountStatusUpperLimit__c;
                accountsToUpdate.add(newAccount);
                continue;
            }

            if (CommonUtility.isMoreThanXWeeksAgo(lastOrderDate, Integer.valueOf(setting.NoOfWeeksNoOrdersMidLimit__c))) {
                newAccount.AccountStatus__c = setting.UpdatedAccountStatusMidLimit__c;
                accountsToUpdate.add(newAccount);
                continue;
            }

            if (CommonUtility.isMoreThanXWeeksAgo(lastOrderDate, Integer.valueOf(setting.NoOfWeeksNoOrdersLowerLimit__c))) {
                newAccount.AccountStatus__c = setting.UpdatedAccountStatusLowerLimit__c;
                accountsToUpdate.add(newAccount);
                continue;
            }

            newAccount.AccountStatus__c = setting.UpdatedAccountStatusRecentOrders__c;
            accountsToUpdate.add(newAccount);
        }
        update accountsToProcess;
    }

    public void finish(Database.BatchableContext context) {
        Integer nextBatchOrder = batchOrder + 1;
        if (getSetting(nextBatchOrder) != null) {
            AccountStatusUpdateBatch nextChainedBatch = new AccountStatusUpdateBatch(nextBatchOrder);
            Database.executeBatch(nextChainedBatch);
        }
    }

    public void execute(SchedulableContext context) {
        Database.executeBatch(new AccountStatusUpdateBatch());
    }

    private AccountStatusUpdateBatchSetting__mdt getSetting(Integer batchOrder) {
        return AccountStatusUpdateBatchSetting__mdt.getInstance(
                'ASUBS_' + String.valueOf(batchOrder)?.leftPad(3, '0')
        );
    }

    private String getQuery() {
        String orderTypes = '(\'' + setting.OrderTypes__c.replaceAll(',', '\',\'') + '\')';
        String accountStatuses = '(\'' + setting.InitialAccountStatuses__c.replaceAll(',', '\',\'') + '\')';
        String query =
                'SELECT Id, (SELECT Id, CreatedDate FROM Orders WHERE RecordType.DeveloperName ' +
                'IN ' + orderTypes + ' ' +
                'ORDER BY CreatedDate DESC LIMIT 1) ' +
                'FROM Account ' +
                'WHERE AccountStatus__c IN ' + accountStatuses + ' ' +
                'AND Frequency__c = \'' + setting.AccountFrequency__c + '\' ';
        return query;
    }
}