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
}