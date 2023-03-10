/**
 * Created by svatopluk.sejkora on 03.11.2022.
 */

public with sharing class AuditAssetTriggerHandler {

    public static void populatePerfectScoreAttributes(List<aforza__Audit_Asset__c> auditAssets) {
        Set<Id> outletAssetIdsToGetDataFrom = new Set<Id>();
        List<aforza__Audit_Asset__c> assetsToUpdate = new List<aforza__Audit_Asset__c>();
        for (aforza__Audit_Asset__c auditAsset : auditAssets) {
            if (auditAsset.aforza__Outlet_Asset__c != null) {
                outletAssetIdsToGetDataFrom.add(auditAsset.aforza__Outlet_Asset__c);
                assetsToUpdate.add(auditAsset);
            }
        }

        Map<Id, aforza__Outlet_Asset__c> outletAssetMap = fetchOutletAssets(outletAssetIdsToGetDataFrom);
        for (aforza__Audit_Asset__c auditToUpdate : assetsToUpdate) {
            aforza__Outlet_Asset__c linkedOutletAsset = outletAssetMap?.get(auditToUpdate.aforza__Outlet_Asset__c);
            auditToUpdate.PerfectScoreRate__c = linkedOutletAsset.PerfectScoreRate__c;
            auditToUpdate.PerfectScoreProduct__c = linkedOutletAsset.PerfectScoreProduct__c;
            auditToUpdate.PerfectScoreWeight__c = linkedOutletAsset.PerfectScoreWeight__c;
            auditToUpdate.PerfectStoreMet__c = linkedOutletAsset.PerfectStoreMet__c;
            auditToUpdate.Score__c = linkedOutletAsset.Score__c;
        }
    }


    private static Map<Id, aforza__Outlet_Asset__c> fetchOutletAssets(Set<Id> outletAssetIds) {
        return new Map<Id, aforza__Outlet_Asset__c>([
                SELECT Id, PerfectScoreProduct__c, PerfectScoreRate__c, PerfectScoreWeight__c, Score__c, PerfectStoreMet__c
                FROM aforza__Outlet_Asset__c
                WHERE Id IN :outletAssetIds
        ]);
    }
}