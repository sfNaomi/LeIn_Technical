/**
 * Created by svatopluk.sejkora on 04.10.2022.
 */

public with sharing class CreateOutletAssetsAccountBatch implements Database.Batchable<SObject> {

    private final Set<Account> accounts;
    private final AccountTriggerHandler.OutletAssetType outletAssetType;

    public CreateOutletAssetsAccountBatch(Set<Account> accounts, AccountTriggerHandler.OutletAssetType outletAssetType){
        this.accounts = accounts;
        this.outletAssetType = outletAssetType;
    }

    public Iterable<SObject> start(Database.BatchableContext batchableContext) {
        return OutletAssetService.createOutletAssetsForAccounts(accounts, outletAssetType);
    }

    public void execute(Database.BatchableContext batchableContext, List<SObject> outletAssets) {
        insert outletAssets;
    }

    public void finish(Database.BatchableContext param1) {
    }
}