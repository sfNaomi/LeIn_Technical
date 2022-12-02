@IsTest
public class ResetFeatureValuesBatchTest {
    
    @IsTest
    public static void testBenchmarkResetOnOutletAsset() {
        // Create Data
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(
         	new Product2(PsProductEngland__c = true)
		);
        aforza__Outlet_Asset__c newAsset = (aforza__Outlet_Asset__c) TdfSObjectFactory.insertSObject(
			new aforza__Outlet_Asset__c(
                aforza__Product__c = newProduct.Id,
                BenchmarkDate__c = System.today(),
                BenchmarkScore__c = 10
            )
		);
        
        Test.startTest();
        ResetBenchmarkScheduler.scheduleBenchmarkReset();
        ResetFeatureValuesBatch rfv = new ResetFeatureValuesBatch(
            'SELECT Id FROM aforza__Outlet_Asset__c WHERE aforza__Product__r.PsProductEngland__c = true OR aforza__Product__r.PsProductScotland__c = true', 
            ResetFeatureValuesBatch.FEATURES.BENCHMARK
        );
        Database.executeBatch(rfv);
        Test.stopTest();
        
        aforza__Outlet_Asset__c oAsset = [SELECT BenchmarkDate__c, BenchmarkScore__c FROM aforza__Outlet_Asset__c WHERE Id = :newAsset.Id];
        System.assert(oAsset.BenchmarkDate__c == null, 'After Batch execution Benchmark Date values should be reset');
        System.assert(oAsset.BenchmarkScore__c == 0, 'After Batch execution Benchmark score values should be reset');
    }
}