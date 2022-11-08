public with sharing class BenchmarkService {
    
    public static void resetOutletBenchmark(List<aforza__Outlet_Asset__c> outletAssets) {
        List<aforza__Outlet_Asset__c> assetsToUpdate= new List<aforza__Outlet_Asset__c>();
        for(aforza__Outlet_Asset__c oAsset: outletAssets) {
            oAsset.BenchmarkDate__c = null;
            oAsset.BenchmarkScore__c = 0;
            assetsToUpdate.add(oAsset);
        }
        update assetsToUpdate;
    }
}