/**
 * Created by svatopluk.sejkora on 05.10.2022.
 */

@IsTest
private with sharing class OutletAssetTriggerHandlerTest {

    @IsTest
    private static void testDeleteAttributesForFocusedProducts() {
        // create NonStockis attribute category
        TdfSObjectFactory.insertSObject(new aforza__Attribute_Category__c());
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        Test.startTest();
        Product2 prod = (Product2) TdfSObjectFactory.insertSObject(new Product2(FocusFiveProduct__c = true, FocusFiveGroup__c = 'GROUP'));
        Test.stopTest();

        List<aforza__Outlet_Asset__c> assets = [SELECT Id, aforza__Product_Code__c FROM aforza__Outlet_Asset__c WHERE aforza__Account__c = :acc.Id];
        System.debug(assets);
        System.assertEquals(1, assets.size());

        List<aforza__Attribute__c> attributes = [SELECT Id, aforza__Code__c FROM aforza__Attribute__c WHERE aforza__Code__c = :prod.StockKeepingUnit];
        System.assertEquals(1, attributes.size());

        // assign attribute manually
        aforza__Attribute_Assignment__c assignment = new aforza__Attribute_Assignment__c(aforza__Account__c = acc.Id, aforza__Attribute__c = attributes[0].Id);
        insert assignment;

        delete assets;

        List<aforza__Attribute_Assignment__c> assignmentsAfterDel = [SELECT Id FROM aforza__Attribute_Assignment__c WHERE aforza__Account__c = :acc.Id];
        System.assertEquals(0, assignmentsAfterDel.size());
    }

    @IsTest
    private static void testPopulateBenchmarkFields() {
        TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PerfectStoreScoreEligible__c = true));

        Test.startTest();
        Product2 prod = (Product2) TdfSObjectFactory.insertSObject(new Product2(PsProductEngland__c = true));
        Test.stopTest();

        List<aforza__Outlet_Asset__c> assets = [SELECT Id, aforza__Product_Code__c, BenchmarkDate__c, BenchmarkScore__c FROM aforza__Outlet_Asset__c WHERE aforza__Product__c = :prod.Id];
        Assert.areEqual(1, assets.size());
        Assert.areEqual(null, assets[0].BenchmarkDate__c);
        Assert.areEqual(0, assets[0].BenchmarkScore__c);


        assets[0].PerfectStoreMet__c = true;
        assets[0].aforza__Audit_Date__c = System.now();
        update assets;
        // no asserts here. As we cannot set proper shipping state because we cannot set country and state picklists for scratch.
        // there is now ay this logic would have any values.
        // TODO fix once we can add states via API/Apex
        // we have it here just for coverage :(
    }

    @IsTest
    private static void testPopulateEmptyBenchmarkForNotAuditedAssets() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PerfectStoreScoreEligible__c = true));
        Product2 prod = (Product2) TdfSObjectFactory.createSObject(new Product2(PsProductEngland__c = true));
        Product2 prod2 = (Product2) TdfSObjectFactory.createSObject(new Product2(PsProductEngland__c = true, Name = 'Prod 2'));

        List<Product2> products = new List<Product2>{prod, prod2};
        Test.startTest();
        insert products;
        Test.stopTest();

        List<aforza__Outlet_Asset__c> assets = [SELECT Id, aforza__Product_Code__c, BenchmarkDate__c, BenchmarkScore__c FROM aforza__Outlet_Asset__c WHERE aforza__Account__c = :acc.Id];
        Assert.areEqual(2, assets.size());
        Assert.areEqual(null, assets[0].BenchmarkDate__c);
        Assert.areEqual(0, assets[0].BenchmarkScore__c);
        Assert.areEqual(null, assets[1].BenchmarkDate__c);
        Assert.areEqual(0, assets[1].BenchmarkScore__c);

        Datetime dateNow = System.now();

        assets[0].PerfectStoreMet__c = true;
        assets[0].aforza__Audit_Date__c = dateNow;
        update assets;

        List<aforza__Outlet_Asset__c> assets2 = [SELECT Id, aforza__Product_Code__c, BenchmarkDate__c, BenchmarkScore__c, aforza__Audit_Date__c FROM aforza__Outlet_Asset__c WHERE aforza__Account__c = :acc.Id];
        Assert.areEqual(2, assets2.size());
        Assert.areEqual(dateNow.date(), assets2[0].BenchmarkDate__c);
        Assert.areEqual(dateNow, assets2[0].aforza__Audit_Date__c);
        Assert.areEqual(0, assets2[0].BenchmarkScore__c);
        Assert.areEqual(dateNow.date(), assets2[1].BenchmarkDate__c);
        Assert.areEqual(dateNow, assets2[1].aforza__Audit_Date__c);
        Assert.areEqual(0, assets2[1].BenchmarkScore__c);
    }
}