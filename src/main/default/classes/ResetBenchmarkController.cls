public with sharing class ResetBenchmarkController {

    @AuraEnabled
    public static void resetOutletBenchmarkByAccount(String accountId) {
        try {
            if( String.isNotEmpty(accountId) ) {
                BenchmarkService.resetOutletBenchmark(
                    [SELECT Id FROM aforza__Outlet_Asset__c 
                     WHERE aforza__Account__c = :accountId 
                       AND (aforza__Product__r.PsProductEngland__c = true OR aforza__Product__r.PsProductScotland__c = true)]
                );
            } else {
                throw new IllegalArgumentException('Account Id cannot be empty, as it is used to load specific Outlet Assets');
            }
        } catch (Exception e) {
            throw PopulateAuraHandledException.newMessageException(e.getMessage());
        }
    }
}