/**
 * Created by svatopluk.sejkora on 04.10.2022.
 */

public with sharing class CreateOutletAssetsAccountBatch implements Database.Batchable<SObject> {

    private final Set<Id> accountIds;

    public CreateOutletAssetsAccountBatch(Set<Id> accountIds){
        this.accountIds = accountIds;
    }

    public Iterable<SObject> start(Database.BatchableContext batchableContext) {
        return FocusProductsService.createFocusProductsForAccounts(accountIds);
    }

    public void execute(Database.BatchableContext batchableContext, List<SObject> outletAssets) {
        insert outletAssets;
    }

    public void finish(Database.BatchableContext param1) {
    }
}