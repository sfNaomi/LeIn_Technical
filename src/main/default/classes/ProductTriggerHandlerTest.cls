/**
 * Created by magdalena.stanciu on 20.09.2022.
 */
@IsTest
private with sharing class ProductTriggerHandlerTest {
    @IsTest
    private static void testRemoveOffSaleProductsFromAssortments_MarkProductAsOffSale() {
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(OffSale__c = 'No'));
        TdfSObjectFactory.insertSObject(new aforza__Assortment_Product__c(aforza__Product__c = newProduct.Id));

        Test.startTest();
        newProduct.OffSale__c = 'Yes';
        update newProduct;
        Test.stopTest();

        List<aforza__Assortment_Product__c> assortProds = [
                SELECT Id
                FROM aforza__Assortment_Product__c
        ];
        System.assertEquals(0, assortProds.size(), 'Expecting to have the assort prods deleted.');
    }

    @IsTest
    private static void testRemoveOffSaleProductsFromAssortments_MarkProductAsOnSale() {
        Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(OffSale__c = null));
        TdfSObjectFactory.insertSObject(new aforza__Assortment_Product__c(aforza__Product__c = newProduct.Id));

        Test.startTest();
        newProduct.OffSale__c = 'No';
        update newProduct;
        Test.stopTest();

        List<aforza__Assortment_Product__c> assortProds = [
                SELECT Id
                FROM aforza__Assortment_Product__c
        ];
        System.assertEquals(1, assortProds.size(), 'Expecting to have assort prods.');
    }

    @IsTest
    private static void testManageRelatedDRSProducts_NewProductNoDRSCode() {
        Test.startTest();
        Product2 baseProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(ProductCode = 'TBP'));
        Test.stopTest();

        List<aforza__Relationship_Rule__c> relationshipRules = [
                SELECT Id
                FROM aforza__Relationship_Rule__c
                WHERE aforza__Source_Product__c = :baseProduct.Id
        ];
        System.assertEquals(0, relationshipRules.size(), 'Expecting no relationship rules to be created.');
    }

    @IsTest
    private static void testManageRelatedDRSProducts_NewProductWithDRSCode() {
        Product2 drsProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(ProductCode = 'TDP'));

        Test.startTest();
        Product2 baseProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(
                ProductCode = 'TBP',
                DRSSKUCode__c = drsProduct.ProductCode,
                DRSGrossUnits__c = 12
        ));
        Test.stopTest();

        List<aforza__Relationship_Rule__c> relationshipRules = [
                SELECT Id, aforza__Source_Product__c, aforza__Target_Product__c, aforza__Quantity__c
                FROM aforza__Relationship_Rule__c
                WHERE aforza__Source_Product__c = :baseProduct.Id
        ];

        System.assertEquals(1, relationshipRules.size(), 'Expecting a relationship rule to be created.');
        System.assertEquals(baseProduct.Id, relationshipRules[0].aforza__Source_Product__c, 'Expecting a different value.');
        System.assertEquals(drsProduct.Id, relationshipRules[0].aforza__Target_Product__c, 'Expecting a different value.');
        System.assertEquals(baseProduct.DRSGrossUnits__c, relationshipRules[0].aforza__Quantity__c, 'Expecting a different value.');
    }

    @IsTest
    private static void testManageRelatedDRSProducts_UpdateProductDRSCode() {
        Product2 drsProduct1 = (Product2) TdfSObjectFactory.insertSObject(new Product2(ProductCode = 'TDP1'));
        Product2 drsProduct2 = (Product2) TdfSObjectFactory.insertSObject(new Product2(ProductCode = 'TDP2'));
        Product2 baseProduct = (Product2) TdfSObjectFactory.insertSObject(
                new Product2(ProductCode = 'TBP', DRSSKUCode__c = drsProduct1.ProductCode, DRSGrossUnits__c = 12)
        );

        Test.startTest();
        baseProduct.DRSSKUCode__c = drsProduct2.ProductCode;
        update baseProduct;
        Test.stopTest();

        List<aforza__Relationship_Rule__c> relationshipRules = [
                SELECT Id, aforza__Source_Product__c, aforza__Target_Product__c, aforza__Quantity__c
                FROM aforza__Relationship_Rule__c
                WHERE aforza__Source_Product__c = :baseProduct.Id
        ];

        System.assertEquals(1, relationshipRules.size(), 'Expecting a relationship rule to be created.');
        System.assertEquals(baseProduct.Id, relationshipRules[0].aforza__Source_Product__c, 'Expecting a different value.');
        System.assertEquals(drsProduct2.Id, relationshipRules[0].aforza__Target_Product__c, 'Expecting a different value.');
        System.assertEquals(baseProduct.DRSGrossUnits__c, relationshipRules[0].aforza__Quantity__c, 'Expecting a different value.');
    }

    @IsTest
    private static void testManageRelatedDRSProducts_UpdateProductDRSCodeFromNullToNotNull() {
        Product2 drsProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(ProductCode = 'TDP'));
        Product2 baseProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(ProductCode = 'TBP'));

        Test.startTest();
        baseProduct.DRSSKUCode__c = drsProduct.ProductCode;
        update baseProduct;
        Test.stopTest();

        List<aforza__Relationship_Rule__c> relationshipRules = [
                SELECT Id, aforza__Source_Product__c, aforza__Target_Product__c, aforza__Quantity__c
                FROM aforza__Relationship_Rule__c
                WHERE aforza__Source_Product__c = :baseProduct.Id
        ];

        System.assertEquals(1, relationshipRules.size(), 'Expecting a relationship rule to be created.');
        System.assertEquals(baseProduct.Id, relationshipRules[0].aforza__Source_Product__c, 'Expecting a different value.');
        System.assertEquals(drsProduct.Id, relationshipRules[0].aforza__Target_Product__c, 'Expecting a different value.');
        System.assertEquals(baseProduct.DRSGrossUnits__c, relationshipRules[0].aforza__Quantity__c, 'Expecting a different value.');
    }

    @IsTest
    private static void testManageRelatedDRSProducts_UpdateProductDRSCodeFromNotNullToNull() {
        Product2 drsProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(ProductCode = 'TDP'));
        Product2 baseProduct = (Product2) TdfSObjectFactory.insertSObject(
                new Product2(ProductCode = 'TBP', DRSSKUCode__c = drsProduct.Id, DRSGrossUnits__c = 12)
        );

        Test.startTest();
        baseProduct.DRSSKUCode__c = null;
        update baseProduct;
        Test.stopTest();

        List<aforza__Relationship_Rule__c> relationshipRules = [
                SELECT Id, aforza__Source_Product__c, aforza__Target_Product__c, aforza__Quantity__c
                FROM aforza__Relationship_Rule__c
                WHERE aforza__Source_Product__c = :baseProduct.Id
        ];

        System.assertEquals(0, relationshipRules.size(), 'Expecting no relationship rules to be created.');
    }

    @IsTest
    private static void testManageRelatedDRSProducts_UpdateProductDRSUnits() {
        Product2 drsProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(ProductCode = 'TDP'));
        Product2 baseProduct = (Product2) TdfSObjectFactory.insertSObject(
                new Product2(ProductCode = 'TBP', DRSSKUCode__c = drsProduct.ProductCode, DRSGrossUnits__c = 12)
        );

        Test.startTest();
        baseProduct.DRSGrossUnits__c = 10;
        update baseProduct;
        Test.stopTest();

        List<aforza__Relationship_Rule__c> relationshipRules = [
                SELECT Id, aforza__Source_Product__c, aforza__Target_Product__c, aforza__Quantity__c
                FROM aforza__Relationship_Rule__c
                WHERE aforza__Source_Product__c = :baseProduct.Id
        ];

        System.assertEquals(1, relationshipRules.size(), 'Expecting a relationship rule to be created.');
        System.assertEquals(baseProduct.Id, relationshipRules[0].aforza__Source_Product__c, 'Expecting a different value.');
        System.assertEquals(drsProduct.Id, relationshipRules[0].aforza__Target_Product__c, 'Expecting a different value.');
        System.assertEquals(baseProduct.DRSGrossUnits__c, relationshipRules[0].aforza__Quantity__c, 'Expecting a different value.');
    }

    @IsTest
    private static void testManageFocusProducts() {
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
    }

    @IsTest
    private static void testManageFocusProducts_UnCheck() {
        // create NonStockis attribute category
        TdfSObjectFactory.insertSObject(new aforza__Attribute_Category__c());
        TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Product2 prod = (Product2) TdfSObjectFactory.insertSObject(new Product2(FocusFiveProduct__c = true, FocusFiveGroup__c = 'GROUP'));

        Test.startTest();
        prod.FocusFiveProduct__c = false;
        update prod;
        Test.stopTest();

        // cant assert much as the batches run in random order after stopTest, so we cant deterministically say which one will happen first
    }

    @IsTest
    private static void testManageFocusProducts_Check() {
        // create NonStockis attribute category
        TdfSObjectFactory.insertSObject(new aforza__Attribute_Category__c());
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Product2 prod = (Product2) TdfSObjectFactory.insertSObject(new Product2(FocusFiveProduct__c = false, FocusFiveGroup__c = 'GROUP'));

        Test.startTest();
        prod.FocusFiveProduct__c = true;
        update prod;
        Test.stopTest();

        List<aforza__Outlet_Asset__c> assets = [SELECT Id, aforza__Product_Code__c FROM aforza__Outlet_Asset__c WHERE aforza__Account__c = :acc.Id];
        System.debug(assets);
        System.assertEquals(1, assets.size());

        List<aforza__Attribute__c> attributes = [SELECT Id, aforza__Code__c FROM aforza__Attribute__c WHERE aforza__Code__c = :prod.StockKeepingUnit];
        System.assertEquals(1, attributes.size());
    }

    @IsTest
    private static void testManagePerfectScoreProducts() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PerfectStoreScoreEligible__c = true));

        Test.startTest();
        Product2 prod = (Product2) TdfSObjectFactory.insertSObject(new Product2(PsProductEngland__c = true));
        Test.stopTest();

        List<aforza__Outlet_Asset__c> assets = [SELECT Id, aforza__Product_Code__c FROM aforza__Outlet_Asset__c WHERE aforza__Account__c = :acc.Id AND aforza__Product__c = :prod.Id];
        System.assertEquals(1, assets.size());
    }

    @IsTest
    private static void testManagePerfectScoreProducts_UnCheck() {
        TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PerfectStoreScoreEligible__c = true));
        Product2 prod = (Product2) TdfSObjectFactory.insertSObject(new Product2(PsProductEngland__c = true));

        Test.startTest();
        prod.PsProductEngland__c = false;
        update prod;
        Test.stopTest();

        // cant assert much as the batches run in random order after stopTest, so we cant deterministically say which one will happen first
    }

    @IsTest
    private static void testManagePerfectScoreProducts_Check() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PerfectStoreScoreEligible__c = true));
        Product2 prod = (Product2) TdfSObjectFactory.insertSObject(new Product2());

        Test.startTest();
        prod.PsProductEngland__c = true;
        update prod;
        Test.stopTest();

        List<aforza__Outlet_Asset__c> assets = [SELECT Id, aforza__Product_Code__c FROM aforza__Outlet_Asset__c WHERE aforza__Account__c = :acc.Id AND aforza__Product__c = :prod.Id];
        System.assertEquals(1, assets.size());
    }

    @IsTest
    private static void testManagePerfectScoreProducts_Scotland() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PerfectStoreScoreEligible__c = true));

        Test.startTest();
        Product2 prod = (Product2) TdfSObjectFactory.insertSObject(new Product2(PsProductScotland__c = true));
        Test.stopTest();

        List<aforza__Outlet_Asset__c> assets = [SELECT Id, aforza__Product_Code__c FROM aforza__Outlet_Asset__c WHERE aforza__Account__c = :acc.Id AND aforza__Product__c = :prod.Id];
        System.assertEquals(1, assets.size());
    }

    @IsTest
    private static void testManagePerfectScoreProducts_ScotlandUnCheck() {
        TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PerfectStoreScoreEligible__c = true));
        Product2 prod = (Product2) TdfSObjectFactory.insertSObject(new Product2(PsProductScotland__c = true));

        Test.startTest();
        prod.PsProductScotland__c = false;
        update prod;
        Test.stopTest();

        // cant assert much as the batches run in random order after stopTest, so we cant deterministically say which one will happen first
    }

    @IsTest
    private static void testManagePerfectScoreProducts_ScotlandCheck() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PerfectStoreScoreEligible__c = true));
        Product2 prod = (Product2) TdfSObjectFactory.insertSObject(new Product2());

        Test.startTest();
        prod.PsProductScotland__c = true;
        update prod;
        Test.stopTest();

        List<aforza__Outlet_Asset__c> assets = [SELECT Id, aforza__Product_Code__c FROM aforza__Outlet_Asset__c WHERE aforza__Account__c = :acc.Id AND aforza__Product__c = :prod.Id];
        System.assertEquals(1, assets.size());
    }
}