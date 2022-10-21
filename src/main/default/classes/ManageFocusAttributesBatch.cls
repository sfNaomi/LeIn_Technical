/**
 * Created by svatopluk.sejkora on 04.10.2022.
 */

public with sharing class ManageFocusAttributesBatch implements Database.Batchable<SObject>, Schedulable {

    public Iterable<SObject> start(Database.BatchableContext batchableContext) {
        String query = 'SELECT Id, aforza__Product_Code__c, FocusFiveStatus__c, aforza__Account__c, ' +
                'aforza__Outlet_Asset__c.aforza__Product_SKU__c ' +
                'FROM aforza__Outlet_Asset__c ' +
                'WHERE FocusFiveProduct__c = TRUE ' +
                'ORDER BY aforza__Account__c ASC';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext batchableContext, List<aforza__Outlet_Asset__c> outletAssets) {
        AttributesService.updateFocusAttributes(outletAssets);
    }

    public void finish(Database.BatchableContext param1) {
    }

    public void execute(SchedulableContext schedulableContext) {
        Database.executeBatch(this);
    }

}