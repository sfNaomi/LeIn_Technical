/**
 * Created by svatopluk.sejkora on 04.10.2022.
 */

public with sharing class RemoveOutletAssetsProductBatch implements Database.Batchable<SObject> {

    private final Set<Id> unFocusedProductIds;
    private final ProductTriggerHandler.OutletAssetType outletAssetType;
    private final String country;

    public RemoveOutletAssetsProductBatch(Set<Id> unFocusedProductIds, ProductTriggerHandler.OutletAssetType outletAssetType, String country){
        this.unFocusedProductIds = unFocusedProductIds;
        this.outletAssetType = outletAssetType;
        this.country = country;
    }

    public Iterable<SObject> start(Database.BatchableContext batchableContext) {
        String query = getQuery();
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext batchableContext, List<aforza__Outlet_Asset__c> outletAssets) {
        delete outletAssets;
    }

    public void finish(Database.BatchableContext param1) {
    }

    private String getQuery() {
        if (outletAssetType == ProductTriggerHandler.OutletAssetType.FOCUS) {
            return 'SELECT Id ' +
                    'FROM aforza__Outlet_Asset__c ' +
                    'WHERE aforza__Purchase_Date__c = NULL AND aforza__Product__c IN :unFocusedProductIds';
        } else if (outletAssetType == ProductTriggerHandler.OutletAssetType.PERFECT_SCORE) {
            return 'SELECT Id ' +
                    'FROM aforza__Outlet_Asset__c ' +
                    'WHERE aforza__Product__c IN :unFocusedProductIds ' +
                    'AND aforza__Account__r.ShippingState = \'' + country + '\'';
        } else {
            return '';
        }
    }
}