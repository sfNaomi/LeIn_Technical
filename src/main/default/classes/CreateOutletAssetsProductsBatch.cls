/**
 * Created by svatopluk.sejkora on 04.10.2022.
 */

public with sharing class CreateOutletAssetsProductsBatch implements Database.Batchable<SObject> {

    private final List<Product2> focusedProducts;
    private final ProductTriggerHandler.OutletAssetType outletAssetType;
    private final String country;

    public CreateOutletAssetsProductsBatch(List<Product2> focusedProducts, ProductTriggerHandler.OutletAssetType outletAssetType, String country) {
        this.focusedProducts = focusedProducts;
        this.outletAssetType = outletAssetType;
        this.country = country;
    }

    public Iterable<SObject> start(Database.BatchableContext batchableContext) {
        String query = getQuery();
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext batchableContext, List<Account> accounts) {
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        OutletAssetService.addNewOutletAssets(accountIds, focusedProducts);
    }

    public void finish(Database.BatchableContext param1) {
    }

    private String getQuery() {

        if (outletAssetType == ProductTriggerHandler.OutletAssetType.FOCUS) {
            return 'SELECT Id ' +
                    'FROM Account ' +
                    'WHERE RecordTypeId = \'' + RecordTypes.ACCOUNT_OUTLET_ID + '\'';
        } else if (outletAssetType == ProductTriggerHandler.OutletAssetType.PERFECT_SCORE) {
            // as we cannot set state in scratch we need to run this logic in tests somehow
            if (Test.isRunningTest()) {
                return 'SELECT Id ' +
                        'FROM Account ' +
                        'WHERE RecordTypeId = \'' + RecordTypes.ACCOUNT_OUTLET_ID + '\' ' +
                        'AND PerfectStoreScoreEligible__c = TRUE';
            } else {
                return 'SELECT Id ' +
                        'FROM Account ' +
                        'WHERE RecordTypeId = \'' + RecordTypes.ACCOUNT_OUTLET_ID + '\' ' +
                        'AND PerfectStoreScoreEligible__c = TRUE ' +
                        'AND ShippingState = \'' + country + '\'';
            }
        } else {
            return '';
        }
    }
}