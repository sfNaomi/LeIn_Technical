/**
 * Created by magdalena.stanciu on 03.01.2023.
 */

public with sharing class AccountNextDeliveryDateUpdateBatch implements Database.Batchable<SObject>, Schedulable {
    public Database.QueryLocator start(Database.BatchableContext context) {
        String query = getQuery();
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext context, List<Account> accountsToProcess) {
        List<Account> accountsToUpdate = new List<Account>();
        for (Account newAccount : accountsToProcess) {
            Date newDeliveryDate = AccountService.computeNextDeliveryDate(newAccount);
            if (newAccount.NextDeliveryDate__c != newDeliveryDate) {
                newAccount.NextDeliveryDate__c = newDeliveryDate;
                accountsToUpdate.add(newAccount);
            }
        }
        update accountsToUpdate;
    }

    public void finish(Database.BatchableContext context) {

    }

    public void execute(SchedulableContext context) {
        Database.executeBatch(new AccountNextDeliveryDateUpdateBatch());
    }

    private String getQuery() {
        String accountStatuses = '(\'' + String.join(AccountService.STATUSES_TO_UPDATE_NEXT_DELIVERY_DATE, '\',\'') + '\')';
        String query =
            'SELECT Id, NextDeliveryDate__c, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c, SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c ' +
            'FROM Account ' +
            'WHERE AccountStatus__c IN ' + accountStatuses;
        return query;
    }
}