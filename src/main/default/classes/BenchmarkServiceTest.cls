@IsTest
public class BenchmarkServiceTest {
    
    @IsTest
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
        System.assert(oAsset.BenchmarkDate__c == null, 'Benchmark Date values should be reset');
        System.assert(oAsset.BenchmarkScore__c == 0, 'Benchmark score values should be reset');
    }

    @IsTest
    public static void testResetOutletBenchmark_WithProperOutletAsset() {
        // Create Data
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PerfectStoreScoreEligible__c = true));
        // add product in test as the outlet asset will be created in batch
        Test.startTest();
        TdfSObjectFactory.insertSObject(new Product2(PsProductEngland__c = true, PsRateEngland__c = 2.3, PsWeightEngland__c = 0.45));
        Test.stopTest();

        // get outlet asset from acc and update it so it is considered as met
        List<aforza__Outlet_Asset__c> createdAsset = [SELECT Id, PerfectStoreMet__c FROM aforza__Outlet_Asset__c WHERE aforza__Account__c = :acc.Id];
        Assert.isTrue(createdAsset.size() == 1);

        createdAsset[0].PerfectStoreMet__c = true;
        createdAsset[0].aforza__Audit_Date__c = System.today();

        update createdAsset;

        //check that values are populated
        List<aforza__Outlet_Asset__c> createdAssetBenchmarked = [SELECT Id, PerfectStoreMet__c, BenchmarkDate__c, BenchmarkScore__c FROM aforza__Outlet_Asset__c WHERE aforza__Account__c = :acc.Id];
        Assert.isTrue(createdAssetBenchmarked.size() == 1);
        Assert.isTrue(createdAssetBenchmarked[0].BenchmarkDate__c != null, 'There should be date populated');
        //TODO cant check for the score now, as the state cannot be set via data load or metadata, as the fields calculating it are dependent on it and are formula fields
        //Assert.isTrue(createdAssetBenchmarked[0].BenchmarkScore__c != 0, 'The score should be populated to non zero value');

        // run the reset
        BenchmarkService.resetOutletBenchmark(createdAssetBenchmarked);

        // get the new values reset
        aforza__Outlet_Asset__c resetOutletAsset = [SELECT BenchmarkDate__c, BenchmarkScore__c FROM aforza__Outlet_Asset__c WHERE Id = :createdAssetBenchmarked[0].Id];
        Assert.isTrue(resetOutletAsset != null);
        System.assert(resetOutletAsset.BenchmarkDate__c == null, 'Benchmark Date values should be reset = null');
        System.assert(resetOutletAsset.BenchmarkScore__c == 0, 'Benchmark score values should be reset = 0');
    }
}