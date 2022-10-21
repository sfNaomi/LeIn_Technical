/**
 * Created by svatopluk.sejkora on 05.10.2022.
 */

@IsTest
private class AttributesServiceTest {
    @IsTest
    private static void testGetExistingInActiveAttributes() {
        Product2 prod = (Product2) TdfSObjectFactory.insertSObject(new Product2());
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = prod.StockKeepingUnit, aforza__Active__c = false));

        Test.startTest();
        Map<String, aforza__Attribute__c> mapOfAttributes =  AttributesService.getExistingInActiveAttributes(new List<Product2>{prod});
        Test.stopTest();

        System.assertEquals(1, mapOfAttributes.size());
    }

    @IsTest
    private static void testGetAttributesForSkus() {
        String code = 'newCode';
        aforza__Attribute__c attribute = (aforza__Attribute__c) TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = code));

        Test.startTest();
        Map<String, Id> attributeMap =  AttributesService.getAttributesForSkus(new Set<String>{attribute.aforza__Code__c});
        Test.stopTest();

        System.assert(attributeMap.containsKey(code));
    }

    @IsTest
    private static void testGetAttributeGroupId_NoGroup() {
        Test.startTest();
        try {
            AttributesService.getAttributeGroupId();
            System.assert(false, 'We expect an exception to be thrown before');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('The required Attribute Category with code NonStockis is not present in the system.'));
            System.assert(e.getTypeName().contains('IllegalArgumentException'));
        }
        Test.stopTest();
    }

    @IsTest
    private static void testGetAttributeGroupId() {
        // create NonStockis attribute category
        TdfSObjectFactory.insertSObject(new aforza__Attribute_Category__c());
        Test.startTest();
        Id groupId = AttributesService.getAttributeGroupId();
        Test.stopTest();

        System.assert(String.isNotEmpty(groupId));
    }

    @IsTest
    private static void testGetAccountToAssignments() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        aforza__Attribute_Category__c category = (aforza__Attribute_Category__c) TdfSObjectFactory.insertSObject(new aforza__Attribute_Category__c());
        String code = 'newCode';
        String code2 = 'newCode2';
        aforza__Attribute__c attribute = (aforza__Attribute__c) TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = code, aforza__Attribute_Category__c = category.Id));
        aforza__Attribute__c attribute2 = (aforza__Attribute__c) TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = code2, aforza__Attribute_Category__c = category.Id));
        aforza__Attribute_Assignment__c assignment = (aforza__Attribute_Assignment__c) TdfSObjectFactory.insertSObject(new aforza__Attribute_Assignment__c(aforza__Account__c = acc.Id, aforza__Attribute__c = attribute.Id));
        aforza__Attribute_Assignment__c assignment2 = (aforza__Attribute_Assignment__c) TdfSObjectFactory.insertSObject(new aforza__Attribute_Assignment__c(aforza__Account__c = acc.Id, aforza__Attribute__c = attribute2.Id));

        Test.startTest();
        Map<Id, Map<String, Id>> attributesForAccount = AttributesService.getAccountToAssignments(new Set<Id>{acc.Id}, new Set<String>{code, code2});
        Test.stopTest();

        System.assert(attributesForAccount.size() == 1);
        System.assert(attributesForAccount.containsKey(acc.Id));
        System.assertEquals(2, attributesForAccount.get(acc.Id).size());
        System.assert(attributesForAccount.get(acc.Id).containsKey(code));
        System.assert(attributesForAccount.get(acc.Id).containsKey(code2));
        System.assertEquals(assignment.Id, attributesForAccount.get(acc.Id).get(code));
        System.assertEquals(assignment2.Id, attributesForAccount.get(acc.Id).get(code2));
    }

    @IsTest
    private static void testUpdateFocusAttributes() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        TdfSObjectFactory.insertSObject(new aforza__Attribute_Category__c());
        String code = 'newCode';

        Test.startTest();
        Product2 prod = (Product2) TdfSObjectFactory.insertSObject(new Product2(StockKeepingUnit = code, FocusFiveProduct__c = true, FocusFiveGroup__c = 'Group'));
        // should be lapsed
        TdfSObjectFactory.insertSObject(new aforza__Outlet_Asset__c(aforza__Account__c = acc.Id, aforza__Product__c = prod.Id, aforza__Name__c = prod.Name));
        aforza__Outlet_Asset__c assetReselected = [SELECT Id, aforza__Product_Code__c, FocusFiveStatus__c, aforza__Account__c, aforza__Outlet_Asset__c.aforza__Product_SKU__c FROM aforza__Outlet_Asset__c WHERE FocusFiveProduct__c = TRUE][0];

        System.debug(assetReselected.FocusFiveStatus__c);
        Test.stopTest();

        AttributesService.updateFocusAttributes(new List<aforza__Outlet_Asset__c>{assetReselected});

        // get attribute assignment
        List<aforza__Attribute_Assignment__c> attributeAssignments = [SELECT Id, aforza__Attribute__c, aforza__Account__c FROM aforza__Attribute_Assignment__c];

        System.assertEquals(1, attributeAssignments.size());
        System.assertEquals(acc.Id, attributeAssignments[0].aforza__Account__c);
    }

    @IsTest
    private static void testDeactivateAttributes() {
        aforza__Attribute_Category__c category = (aforza__Attribute_Category__c) TdfSObjectFactory.insertSObject(new aforza__Attribute_Category__c());
        String code = 'newCode';
        String code2 = 'newCode2';
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = code, aforza__Attribute_Category__c = category.Id));
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = code2, aforza__Attribute_Category__c = category.Id));

        Test.startTest();
        AttributesService.deactivateAttributes(new Set<String>{code});
        Test.stopTest();

        List<aforza__Attribute__c> leftAttributes = [SELECT Id FROM aforza__Attribute__c WHERE aforza__Active__c = TRUE];

        System.assertEquals(1, leftAttributes.size());
    }

    @IsTest
    private static void testCreateAttributes() {
        TdfSObjectFactory.insertSObject(new aforza__Attribute_Category__c());
        String code = 'newCode';
        Product2 prod = (Product2) TdfSObjectFactory.insertSObject(new Product2(StockKeepingUnit = code, FocusFiveProduct__c = false, FocusFiveGroup__c = 'Group'));

        Test.startTest();
        AttributesService.createAttributes(new List<Product2>{prod});
        Test.stopTest();

        List<aforza__Attribute__c> attributes = [SELECT Id, aforza__Code__c, aforza__Active__c FROM aforza__Attribute__c];
        System.assertEquals(1, attributes.size());
        System.assertEquals(code, attributes[0].aforza__Code__c);
        System.assertEquals(true, attributes[0].aforza__Active__c);
    }

    @IsTest
    private static void testCreateAttributes_Update() {
        String code = 'newCode';
        Product2 prod = (Product2) TdfSObjectFactory.insertSObject(new Product2(StockKeepingUnit = code, FocusFiveProduct__c = false));
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = code, aforza__Active__c = false));

        Test.startTest();
        AttributesService.createAttributes(new List<Product2>{prod});
        Test.stopTest();

        List<aforza__Attribute__c> attributes = [SELECT Id, aforza__Code__c, aforza__Active__c FROM aforza__Attribute__c];
        System.assertEquals(1, attributes.size());
        System.assertEquals(code, attributes[0].aforza__Code__c);
        System.assertEquals(true, attributes[0].aforza__Active__c);
    }

}