public with sharing class InventoryProductCalculationBatch implements Database.Batchable < SObject > , Schedulable {

    public Iterable < SObject > start(Database.BatchableContext batchableContext) {
        // load all recurring records that has been modified
        String query = 'SELECT aforza__Stock_Quantity__c,Id,JDEStockQuantity__c, NonSalableStock__c,  ' +
            'Name, PickingLocation__c, aforza__Inventory__c,aforza__Product__c FROM aforza__Inventory_Product__c';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext batchableContext, List < aforza__Inventory_Product__c > inventoryProducts) {

        InventoryProductService.updateInventoryStock(inventoryProducts);
    }

    public void finish(Database.BatchableContext param1) {

    }

    public void execute(SchedulableContext schedulableContext) {
        Database.executeBatch(this);
    }


}