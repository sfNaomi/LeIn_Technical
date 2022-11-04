/**
 * Created by svatopluk.sejkora on 03.11.2022.
 */

@IsTest
private class AuditAssetTriggerHandlerTest {
    @IsTest
    static void testPopulatePerfectScoreAttributes() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PerfectStoreScoreEligible__c = true));
        Product2 prod = (Product2) TdfSObjectFactory.insertSObject(new Product2(PsProductEngland__c = true, PsRateEngland__c = 4, PsWeightEngland__c = 0.00234));
        aforza__Outlet_Asset__c outletAsset = (aforza__Outlet_Asset__c) TdfSObjectFactory.insertSObject(new aforza__Outlet_Asset__c(aforza__Product__c = prod.Id,
                aforza__Account__c = acc.Id, aforza__Type__c = 'test', PerfectStoreMet__c = true, aforza__Audit_Date__c = System.today()));

        System.debug('Oasset' + [SELECT Id, PerfectScoreWeight__c, PerfectScoreProduct__c, PerfectScoreRate__c, Score__c FROM aforza__Outlet_Asset__c]);

        aforza__Audit__c audit = (aforza__Audit__c) TdfSObjectFactory.insertSObject(new aforza__Audit__c(aforza__Account__c = acc.Id));

        Test.startTest();
        TdfSObjectFactory.insertSObject(new aforza__Audit_Asset__c(aforza__Outlet_Asset__c = outletAsset.Id, aforza__Audit__c = audit.Id, PerfectStoreMet__c = true));
        Test.stopTest();

        aforza__Audit_Asset__c updatedAsset = [SELECT Id, PerfectScoreRate__c, PerfectScoreProduct__c, PerfectScoreWeight__c, Score__c FROM aforza__Audit_Asset__c LIMIT 1][0];

        //as we cant set states via API/Apex, we cant test this logic in tests.
        Assert.areEqual(0, updatedAsset.PerfectScoreRate__c);
        Assert.areEqual(0, updatedAsset.PerfectScoreWeight__c);
        Assert.areEqual(false, updatedAsset.PerfectScoreProduct__c);
        Assert.areEqual(0.00, updatedAsset.Score__c);
    }
}