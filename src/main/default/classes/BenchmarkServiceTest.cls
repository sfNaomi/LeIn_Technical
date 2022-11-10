@isTest
public class BenchmarkServiceTest {
    
    @isTest
    public static void testResetOutletBenchmark() {
        // Create Data
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(
            new Product2(PsProductEngland__c = true)
		);
        List<aforza__Outlet_Asset__c> newAssets = new List<aforza__Outlet_Asset__c>();
        newAssets.add((aforza__Outlet_Asset__c) TdfSObjectFactory.insertSObject(
			new aforza__Outlet_Asset__c(
                aforza__Product__c = newProduct.Id,
                BenchmarkDate__c = System.today(),
                BenchmarkScore__c = 10
            )
		));
        
        Test.startTest();
        BenchmarkService.resetOutletBenchmark(newAssets);
        Test.stopTest();
        
        aforza__Outlet_Asset__c oAsset = [SELECT BenchmarkDate__c, BenchmarkScore__c FROM aforza__Outlet_Asset__c WHERE Id = :newAssets[0].Id];
        System.assert(oAsset.BenchmarkDate__c == NULL, 'Benchmark Date values should be reset');
        System.assert(oAsset.BenchmarkScore__c == 0, 'Benchmark score values should be reset');
    }
}