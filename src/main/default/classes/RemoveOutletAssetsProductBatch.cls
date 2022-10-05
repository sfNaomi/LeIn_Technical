/**
 * Created by svatopluk.sejkora on 04.10.2022.
 */

public with sharing class RemoveOutletAssetsProductBatch implements Database.Batchable<SObject> {

    private final Set<Id> unFocusedProductIds;

    public RemoveOutletAssetsProductBatch(Set<Id> unFocusedProductIds){
        this.unFocusedProductIds = unFocusedProductIds;
    }

    public Iterable<SObject> start(Database.BatchableContext batchableContext) {
        String query = 'SELECT Id ' +
                'FROM aforza__Outlet_Asset__c ' +
                'WHERE aforza__Purchase_Date__c = null AND aforza__Product__c IN :unFocusedProductIds';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext batchableContext, List<aforza__Outlet_Asset__c> outletAssets) {
        delete outletAssets;
    }

    public void finish(Database.BatchableContext param1) {
    }
}