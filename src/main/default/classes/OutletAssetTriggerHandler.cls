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
        List<aforza__Attribute_Assignment__c> assignmentsToDelete = new List<aforza__Attribute_Assignment__c>();
        for (aforza__Outlet_Asset__c asset : outletAssetsByIds.values()) {
            Map<String, Id> accountAssignments = accountIdToAssignmentsByIds.get(asset.aforza__Account__c);
            if (accountAssignments <> null && accountAssignments.containsKey(asset.aforza__Product_SKU__c)) {
                assignmentsToDelete.add(new aforza__Attribute_Assignment__c(Id = accountAssignments.get(asset.aforza__Product_SKU__c)));
            }
        }

        delete assignmentsToDelete;
    }

    public static void populateBenchmarkFields(List<aforza__Outlet_Asset__c> outletAssets) {
        List<aforza__Outlet_Asset__c> assetsToUpdate = new List<aforza__Outlet_Asset__c>();
        Set<Id> outletAssetsToExclude = new Set<Id>();
        Map<Id, Datetime> accountWithAuditDateMap = new Map<Id, Datetime>();
        Set<Id> accountIds = new Set<Id>();
        for (aforza__Outlet_Asset__c outletAsset : outletAssets) {
            aforza__Outlet_Asset__c assetToUpdate = new aforza__Outlet_Asset__c();
            if (outletAsset.PerfectStoreMet__c == true && outletAsset.aforza__Audit_Date__c != null && outletAsset.BenchmarkDate__c == null && outletAsset.BenchmarkScore__c == 0) {
                assetToUpdate.Id = outletAsset.Id;
                assetToUpdate.BenchmarkDate__c = outletAsset.aforza__Audit_Date__c.date();
                assetToUpdate.BenchmarkScore__c = outletAsset.Score__c;
                assetsToUpdate.add(assetToUpdate);
                outletAssetsToExclude.add(outletAsset.Id);
                accountWithAuditDateMap.put(outletAsset.aforza__Account__c, outletAsset.aforza__Audit_Date__c);
                accountIds.add(outletAsset.aforza__Account__c);
            }
        }
        update assetsToUpdate;
        populateEmptyBenchmarkForNotAuditedAssets(accountIds, outletAssetsToExclude, accountWithAuditDateMap);
    }

    private static void populateEmptyBenchmarkForNotAuditedAssets(Set<Id> accountIds, Set<Id> outletAssetsToExclude, Map<Id, Datetime> accountWithAuditDateMap) {
        List<aforza__Outlet_Asset__c> assetsToUpdate = new List<aforza__Outlet_Asset__c>();
        // get all relevant outlet assets from Accounts
        for (aforza__Outlet_Asset__c outletAsset : [
                SELECT Id, BenchmarkDate__c, aforza__Account__c
                FROM aforza__Outlet_Asset__c
                WHERE aforza__Account__c IN :accountIds
                AND Id NOT IN :outletAssetsToExclude
                AND BenchmarkDate__c = NULL
                AND BenchmarkScore__c = 0
                AND (aforza__Product__r.PsProductEngland__c = TRUE OR aforza__Product__r.PsProductScotland__c = TRUE)
        ]) {
            aforza__Outlet_Asset__c outletAssetToUpdate = new aforza__Outlet_Asset__c();
            outletAssetToUpdate.Id = outletAsset.Id;
            outletAssetToUpdate.BenchmarkScore__c = 0;
            outletAssetToUpdate.BenchmarkDate__c = accountWithAuditDateMap.get(outletAsset.aforza__Account__c).date();
            outletAssetToUpdate.aforza__Audit_Date__c = accountWithAuditDateMap.get(outletAsset.aforza__Account__c);
            assetsToUpdate.add(outletAssetToUpdate);
        }
        update assetsToUpdate;
    }

}