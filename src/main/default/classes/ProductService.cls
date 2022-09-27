/**
 * Created by magdalena.stanciu on 20.09.2022.
 */

public with sharing class ProductService {
    public static final ProductSetting__mdt SETTINGS {
        get {
            if (SETTINGS == null) {
                SETTINGS = ProductSetting__mdt.getInstance('OrgDefaultProductSettings');
            }
            return SETTINGS;
        }
        set;
    }

    public static void removeOffSaleProductsFromAssortments(Set<Id> productIds) {
        List<aforza__Assortment_Product__c> assortProds = [
                SELECT Id
                FROM aforza__Assortment_Product__c
                WHERE aforza__Product__c IN :productIds
        ];
        delete assortProds;
    }

    public static void createDRSRelationshipRules(List<Product2> newProducts) {
        List<String> skuCodesOfRelatedDRSProducts = new List<String>();
        for (Product2 newProduct : newProducts) {
            skuCodesOfRelatedDRSProducts.add(newProduct.DRSSKUCode__c);
        }

        Map<String, Product2> drsProducts = getProductsBasedOnSKUCodes(skuCodesOfRelatedDRSProducts);

        List<aforza__Relationship_Rule__c> relationshipRulesToBeCreated = new List<aforza__Relationship_Rule__c>();
        for (Product2 newProduct : newProducts) {
            Product2 drsProduct = drsProducts.get(newProduct.DRSSKUCode__c);
            if (drsProduct != null) {
                aforza__Relationship_Rule__c newRelationshipRule = createNewDRSRelationshipRule(
                        newProduct, drsProduct
                );
                relationshipRulesToBeCreated.add(newRelationshipRule);
            }
        }

        insert relationshipRulesToBeCreated;
    }

    public static Map<String, Product2> getProductsBasedOnSKUCodes(List<String> skuCodes) {
        List<Product2> drsProducts = [
                SELECT Id, Name, StockKeepingUnit
                FROM Product2
                WHERE StockKeepingUnit IN :skuCodes
        ];

        Map<String, Product2> productsBySKU = new Map<String, Product2>();
        for (Product2 newProduct : drsProducts) {
            productsBySKU.put(newProduct.StockKeepingUnit, newProduct);
        }

        return productsBySKU;
    }

    public static aforza__Relationship_Rule__c createNewDRSRelationshipRule(Product2 baseProduct, Product2 drsProduct) {
        aforza__Relationship_Rule__c relationship = new aforza__Relationship_Rule__c();
        relationship.aforza__Local_Id__c = createLocalIdForRelationshipRule(
                SETTINGS.DRSProductRelationshipRulePrefix__c,
                baseProduct.StockKeepingUnit,
                drsProduct.StockKeepingUnit
        );
        relationship.Name = baseProduct.Name + ' - ' + drsProduct.Name;
        relationship.aforza__Source_Product__c = baseProduct.Id;
        relationship.aforza__Target_Product__c = drsProduct.Id;
        relationship.aforza__Type__c = 'Addition';
        relationship.aforza__Active__c = true;
        relationship.aforza__Rule_Source__c = 'Manual';
        relationship.aforza__Quantity__c = baseProduct.DRSGrossUnits__c;
        return relationship;
    }

    public static void deleteDRSRelationshipRules(List<Product2> oldProducts) {
        List<String> idsOfRelationshipsToBeDeleted = new List<String>();
        for (Product2 oldProduct : oldProducts) {
            idsOfRelationshipsToBeDeleted.add(
                    createLocalIdForRelationshipRule(
                            SETTINGS.DRSProductRelationshipRulePrefix__c,
                            oldProduct.StockKeepingUnit,
                            oldProduct.DRSSKUCode__c
                    )
            );
        }

        List<aforza__Relationship_Rule__c> relationshipsToBeDeleted = [
                SELECT Id
                FROM aforza__Relationship_Rule__c
                WHERE aforza__Local_Id__c IN :idsOfRelationshipsToBeDeleted
        ];

        delete relationshipsToBeDeleted;
    }

    public static void updateDRSRelationshipRules(List<Product2> newProducts) {
        List<aforza__Relationship_Rule__c> relationshipsToBeUpdated = new List<aforza__Relationship_Rule__c>();
        for (Product2 newProduct : newProducts) {
            aforza__Relationship_Rule__c newRelationship = new aforza__Relationship_Rule__c();
            newRelationship.aforza__LocaL_Id__c = createLocalIdForRelationshipRule (
                    SETTINGS.DRSProductRelationshipRulePrefix__c,
                    newProduct.StockKeepingUnit,
                    newProduct.DRSSKUCode__c
            );
            newRelationship.aforza__Quantity__c = newProduct.DRSGrossUnits__c;
            relationshipsToBeUpdated.add(newRelationship);
        }
        upsert relationshipsToBeUpdated aforza__LocaL_Id__c;
    }

    public static String createLocalIdForRelationshipRule(String prefix, String baseProductSKU, String drsProductSku) {
        return prefix + baseProductSKU + drsProductSku;
    }
}