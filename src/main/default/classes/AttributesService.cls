/**
 * Created by svatopluk.sejkora on 04.10.2022.
 */

public with sharing class AttributesService {

    private static final Id ATTRIBUTE_GROUP_ID {
        get {
            if (ATTRIBUTE_GROUP_ID == null) {
                ATTRIBUTE_GROUP_ID = getAttributeGroupId();
            }
            return ATTRIBUTE_GROUP_ID;
        }
        set;
    }

    private static final String ATTRIBUTE_TYPE = 'Toggle';

    public static void createAttributes(List<Product2> products) {
        List<aforza__Attribute__c> attributesToCreate = new List<aforza__Attribute__c>();
        Map<String, aforza__Attribute__c> existingDeactivatedAttributes = getExistingInActiveAttributes(products);
        for (Product2 product : products) {
            if (existingDeactivatedAttributes.containsKey(product.StockKeepingUnit)) {
                aforza__Attribute__c existingAttribute = existingDeactivatedAttributes.get(product.StockKeepingUnit);
                existingAttribute.aforza__Active__c = true;
                attributesToCreate.add(existingAttribute);
            } else {
                attributesToCreate.add(createAttribute(product));
            }
        }

        upsert attributesToCreate Id;
    }

    public static void deactivateAttributes(Set<String> productSkus) {
        List<aforza__Attribute__c> attributesToDeactivate = new List<aforza__Attribute__c>();
        for (aforza__Attribute__c attribute : [SELECT Id, aforza__Active__c FROM aforza__Attribute__c WHERE aforza__Code__c IN :productSkus]) {
            attribute.aforza__Active__c = false;
            attributesToDeactivate.add(attribute);
        }
        update attributesToDeactivate;
    }

    public static void updateFocusAttributes(List<aforza__Outlet_Asset__c> outletAssets) {
        // get account and product skus from outlet Asset
        Set<Id> accountIds = new Set<Id>();
        Set<String> productSkus = new Set<String>();
        Map<Id, List<aforza__Outlet_Asset__c>> accountIdToOutletAsset = new Map<Id, List<aforza__Outlet_Asset__c>>();
        for (aforza__Outlet_Asset__c outletAsset : outletAssets) {
            accountIds.add(outletAsset.aforza__Account__c);
            productSkus.add(outletAsset.aforza__Product_SKU__c);
            if (accountIdToOutletAsset.containsKey(outletAsset.aforza__Account__c)) {
                accountIdToOutletAsset.get(outletAsset.aforza__Account__c).add(outletAsset);
            } else {
                accountIdToOutletAsset.put(outletAsset.aforza__Account__c, new List<aforza__Outlet_Asset__c>{
                        outletAsset
                });
            }
        }

        Map<Id, Map<String, Id>> accountIdToAssignmentsByIds = getAccountToAssignments(accountIds, productSkus);
        Map<String, Id> attributeCodeToId = getAttributesForSkus(productSkus);

        List<aforza__Attribute_Assignment__c> assignmentsToDelete = new List<aforza__Attribute_Assignment__c>();
        List<aforza__Attribute_Assignment__c> assignmentsToCreate = new List<aforza__Attribute_Assignment__c>();
        // iterate over Outlet Assets from batch and either add or remove attributes
        for (Id accId : accountIdToOutletAsset.keySet()) {
            for (aforza__Outlet_Asset__c outletAsset : accountIdToOutletAsset.get(accId)) {
                Set<String> existingSkusOnAttributes = new Set<String>();
                Map<String, Id> existingSkusToAssignmentId = new Map<String, Id>();

                if (accountIdToAssignmentsByIds.containsKey(accId)) {
                    existingSkusOnAttributes = accountIdToAssignmentsByIds.get(accId).keySet();
                    existingSkusToAssignmentId = accountIdToAssignmentsByIds.get(accId);
                }
                // when we have the match and status is NOT Lapsed we need to remove. if we have and status is lapsed we do not need to do anything
                if (existingSkusOnAttributes != null && existingSkusOnAttributes.contains(outletAsset.aforza__Product_SKU__c) && outletAsset.FocusFiveStatus__c != 'Lapsed') {
                    assignmentsToDelete.add(new aforza__Attribute_Assignment__c(Id = existingSkusToAssignmentId.get(outletAsset.aforza__Product_SKU__c)));
                    //  if we do not have a match and status is lapsed we need to add. When we dont have and any other status we do not need to do anything
                } else if ((existingSkusOnAttributes == null || !existingSkusOnAttributes.contains(outletAsset.aforza__Product_SKU__c)) && outletAsset.FocusFiveStatus__c == 'Lapsed') {
                    assignmentsToCreate.add(createAssignment(attributeCodeToId.get(outletAsset.aforza__Product_SKU__c), accId));
                }
            }
        }

        insert assignmentsToCreate;
        delete assignmentsToDelete;
    }

    public static Map<Id, Map<String, Id>> getAccountToAssignments(Set<Id> accountIds, Set<String> productSkus) {
        Map<Id, Map<String, Id>> accountIdToAssignmentsByIds = new Map<Id, Map<String, Id>>();
        for (Account acc : [
                SELECT Id, (
                        SELECT Id, aforza__Attribute__r.aforza__Code__c
                        FROM aforza__Attribute_Assignments__r
                        WHERE aforza__Attribute__r.aforza__Code__c IN :productSkus
                )
                FROM Account
                WHERE Id IN :accountIds
        ]) {
            for (aforza__Attribute_Assignment__c assignment : acc.aforza__Attribute_Assignments__r) {
                if (accountIdToAssignmentsByIds.containsKey(acc.Id)) {
                    accountIdToAssignmentsByIds.get(acc.Id).put(assignment.aforza__Attribute__r.aforza__Code__c, assignment.Id);
                } else {
                    accountIdToAssignmentsByIds.put(acc.Id, new Map<String, Id>{
                            assignment.aforza__Attribute__r.aforza__Code__c => assignment.Id
                    });
                }
            }
        }
        return accountIdToAssignmentsByIds;
    }

    private static aforza__Attribute__c createAttribute(Product2 product) {
        aforza__Attribute__c attribute = new aforza__Attribute__c();
        attribute.aforza__Type__c = ATTRIBUTE_TYPE;
        attribute.aforza__Attribute_Category__c = ATTRIBUTE_GROUP_ID;
        attribute.Name = product.Name;
        attribute.aforza__Code__c = product.StockKeepingUnit;
        attribute.aforza__Active__c = true;
        return attribute;
    }

    private static aforza__Attribute_Assignment__c createAssignment(Id attributeId, Id accountId) {
        aforza__Attribute_Assignment__c assignment = new aforza__Attribute_Assignment__c();
        assignment.aforza__Account__c = accountId;
        assignment.aforza__Attribute__c = attributeId;

        return assignment;
    }

    @TestVisible
    private static Id getAttributeGroupId() {
        String attributeGroupCode = ProductSetting__mdt.getInstance('OrgDefaultProductSettings').FocusProductAttributeCategory__c;
        List<aforza__Attribute_Category__c> category = [SELECT Id, aforza__Code__c FROM aforza__Attribute_Category__c WHERE aforza__Code__c = :attributeGroupCode];
        if (category.size() == 1) {
            return category[0].Id;
        } else {
            throw new IllegalArgumentException('The required Attribute Category with code ' + attributeGroupCode + ' is not present in the system.');
        }
    }

    @TestVisible
    private static Map<String, Id> getAttributesForSkus(Set<String> skus) {
        Map<String, Id> attributeCodeToId = new Map<String, Id>();
        for (aforza__Attribute__c attribute : [SELECT Id, aforza__Code__c FROM aforza__Attribute__c WHERE aforza__Code__c IN :skus]) {
            attributeCodeToId.put(attribute.aforza__Code__c, attribute.Id);
        }

        return attributeCodeToId;
    }

    @TestVisible
    private static Map<String, aforza__Attribute__c> getExistingInActiveAttributes(List<Product2> products) {
        Set<String> skusToSearch = new Set<String>();
        for (Product2 product : products) {
            skusToSearch.add(product.StockKeepingUnit);
        }

        Map<String, aforza__Attribute__c> skuToAttributeMap = new Map<String, aforza__Attribute__c>();
        for (aforza__Attribute__c attribute : [SELECT Id, aforza__Active__c, aforza__Code__c FROM aforza__Attribute__c WHERE aforza__Code__c IN :skusToSearch AND aforza__Active__c = FALSE]) {
            skuToAttributeMap.put(attribute.aforza__Code__c, attribute);
        }
        return skuToAttributeMap;
    }
}