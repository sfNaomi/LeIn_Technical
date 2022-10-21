/**
 * Created by svatopluk.sejkora on 04.10.2022.
 */

public with sharing class OutletAssetTriggerHandler {

    public static void deleteAttributesForFocusedProducts(Map<Id, aforza__Outlet_Asset__c> outletAssetsByIds) {
        Set<Id> accountIds = new Set<Id>();
        Set<String> productSkus = new Set<String>();
        for (aforza__Outlet_Asset__c asset : outletAssetsByIds.values()) {
            accountIds.add(asset.aforza__Account__c);
            productSkus.add(asset.aforza__Product_SKU__c);

        }
        Map<Id, Map<String, Id>> accountIdToAssignmentsByIds = AttributesService.getAccountToAssignments(accountIds, productSkus);
        System.debug(accountIdToAssignmentsByIds);
        List<aforza__Attribute_Assignment__c> assignmentsToDelete = new List<aforza__Attribute_Assignment__c>();
        for (aforza__Outlet_Asset__c asset : outletAssetsByIds.values()) {
            Map<String, Id> accountAssignments = accountIdToAssignmentsByIds.get(asset.aforza__Account__c);
            if (accountAssignments <> null && accountAssignments.containsKey(asset.aforza__Product_SKU__c)) {
                assignmentsToDelete.add(new aforza__Attribute_Assignment__c(Id = accountAssignments.get(asset.aforza__Product_SKU__c)));
            }
        }

        delete assignmentsToDelete;
    }

}