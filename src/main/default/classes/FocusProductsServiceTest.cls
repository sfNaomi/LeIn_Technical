/**
 * Created by svatopluk.sejkora on 05.10.2022.
 */

@IsTest
private class FocusProductsServiceTest {
    @IsTest
    private static void testGetAccountsOutletAssets() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Product2 prod1 = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        Product2 prod2 = (Product2) TdfSObjectFactory.insertSObject(new Product2(StockKeepingUnit = 'uniqueSKU2'));


        TdfSObjectFactory.insertSObject(new aforza__Outlet_Asset__c(aforza__Account__c = acc.Id, aforza__Product__c = prod1.Id));
        TdfSObjectFactory.insertSObject(new aforza__Outlet_Asset__c(aforza__Account__c = acc.Id, aforza__Product__c = prod2.Id));

        Test.startTest();
        Map<Id, Map<Id, Date>> outlets = FocusProductsService.getAccountsOutletAssets(new Set<Id>{acc.Id});
        Test.stopTest();

        System.assertEquals(1, outlets.size());
        System.assertEquals(2, outlets.get(acc.Id).size());
    }

    @IsTest
    private static void testCreateOutletAsset() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Product2 prod1 = (Product2) TdfSObjectFactory.insertSObject(new Product2());

        Test.startTest();
        aforza__Outlet_Asset__c outletAsset = FocusProductsService.createOutletAsset(acc.Id, prod1);
        Test.stopTest();

        System.assertEquals(acc.Id, outletAsset.aforza__Account__c);
        System.assertEquals(prod1.Id, outletAsset.aforza__Product__c);
        System.assertEquals(prod1.Name, outletAsset.aforza__Name__c);
        System.assertEquals('Product', outletAsset.aforza__Type__c);
    }

    @IsTest
    private static void testAddNewFocusProducts() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Product2 prod1 = (Product2) TdfSObjectFactory.insertSObject(new Product2());

        Test.startTest();
        FocusProductsService.addNewFocusProducts(new Set<Id>{acc.Id}, new List<Product2>{prod1});
        Test.stopTest();

        List<aforza__Outlet_Asset__c> assets = [SELECT Id FROM aforza__Outlet_Asset__c WHERE aforza__Account__c = :acc.Id AND aforza__Product__c = :prod1.Id];
        System.assertEquals(1, assets.size());
    }

    @IsTest
    private static void testCreateFocusProductsForAccounts() {
        // create NonStockis attribute category
        TdfSObjectFactory.insertSObject(new aforza__Attribute_Category__c());

        Test.startTest();
        TdfSObjectFactory.insertSObject(new Product2(FocusFiveProduct__c = true, FocusFiveGroup__c = 'GROUP'));
        Test.stopTest();
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        List<aforza__Outlet_Asset__c> assetsBefore = [SELECT Id FROM aforza__Outlet_Asset__c WHERE aforza__Account__c = :acc.Id];
        System.assertEquals(0, assetsBefore.size());

        List<aforza__Outlet_Asset__c> assetsToInsert =  FocusProductsService.createFocusProductsForAccounts(new Set<Id>{acc.Id});
        insert assetsToInsert;

        List<aforza__Outlet_Asset__c> assetsAfter = [SELECT Id FROM aforza__Outlet_Asset__c WHERE aforza__Account__c = :acc.Id];
        System.assertEquals(1, assetsAfter.size());
    }
}