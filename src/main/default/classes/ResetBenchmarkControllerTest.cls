@isTest
public class ResetBenchmarkControllerTest {
    
    @isTest
    public static void testResetOutletBenchmarkByAccount() {
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
        
        ResetBenchmarkController.resetOutletBenchmarkByAccount(newAsset.aforza__Account__c);
        
        aforza__Outlet_Asset__c oAsset = [SELECT BenchmarkDate__c, BenchmarkScore__c FROM aforza__Outlet_Asset__c WHERE Id = :newAsset.Id];
        System.assert(oAsset.BenchmarkDate__c == NULL, 'Benchmark Date values should be reset');
        System.assert(oAsset.BenchmarkScore__c == 0, 'Benchmark score values should be reset');
    }
}