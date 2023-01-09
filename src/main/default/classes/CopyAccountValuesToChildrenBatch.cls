/**
 * Created by svatopluk.sejkora on 08.01.2023.
 */

public without sharing class CopyAccountValuesToChildrenBatch implements Database.Batchable<SObject> {

    private final List<Account> updatedAccounts;

    public CopyAccountValuesToChildrenBatch(List<Account> updatedAccounts){
        this.updatedAccounts = updatedAccounts;
    }

    public Iterable<SObject> start(Database.BatchableContext batchableContext) {
        return AccountSyncService.getRelatedAccounts(updatedAccounts, AccountSyncService.AccountType.PARENT);
    }

    public void execute(Database.BatchableContext batchableContext, List<Account> accountsToUpdate) {
        List<Account> updatedChildAccounts = AccountSyncService.syncAccounts(new Map<Id, Account>(updatedAccounts), accountsToUpdate);
        update updatedChildAccounts;
    }

    public void finish(Database.BatchableContext param1) {
    }
}