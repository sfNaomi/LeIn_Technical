/**
 * @description       : Service class for inventory
 **/

public with sharing class InventoryService {

    public static Map<String, Id> getDepotInventoryMapping(){
            Map<String, String> depotAndInventoryCodeMap = new Map<String, String>();
            Map<String, Id> inventoryCodeAndInventoryIdMap = new Map<String, Id>();
        	Map<String, Id> depotCodeAndInventoryIdMap = new Map<String, Id>();
            for (InventorySetting__mdt setting : InventorySetting__mdt.getAll().values()) {
                    depotAndInventoryCodeMap.put(setting.DepotCode__c, setting.InventoryCode__c);
            }
        	List<aforza__Inventory__c> inventoryList = [SELECT Id, InventoryCode__c FROM aforza__Inventory__c WHERE InventoryCode__c IN :depotAndInventoryCodeMap.values()];
        	
        	if(!inventoryList.isEmpty()){
            	for(aforza__Inventory__c inv : inventoryList){
                	inventoryCodeAndInventoryIdMap.put(inv.InventoryCode__c, inv.Id);
            	}
                for(String depotCode : depotAndInventoryCodeMap.keySet()){
                    if(inventoryCodeAndInventoryIdMap.containsKey(depotAndInventoryCodeMap.get(depotCode))){
                    	depotCodeAndInventoryIdMap.put(depotCode, inventoryCodeAndInventoryIdMap.get(depotAndInventoryCodeMap.get(depotCode)));
                	}
                }    
            }
			return depotCodeAndInventoryIdMap;
    }
}