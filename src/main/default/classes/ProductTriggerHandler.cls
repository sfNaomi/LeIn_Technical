/**
 * Created by magdalena.stanciu on 19.09.2022.
 */

public with sharing class ProductTriggerHandler {
    public static void removeOffSaleProductsFromAssortments(List<Product2> newProducts, Map<Id, Product2> oldProducts) {
        Set<Id> productIdsToRemoveFromAssortments = new Set<Id>();
        for (Product2 newProduct : newProducts) {
            Product2 oldProduct = oldProducts.get(newProduct.Id);
            if (newProduct.OffSale__c != oldProduct.OffSale__c && newProduct.OffSale__c == 'Yes') {
                productIdsToRemoveFromAssortments.add(newProduct.Id);
            }
        }
        ProductService.removeOffSaleProductsFromAssortments(productIdsToRemoveFromAssortments);
    }

    public static void manageRelatedDRSProducts(List<Product2> newProducts, Map<Id, Product2> oldProducts) {
        List<Product2> productsToCreateDRSRelationshipRule = new List<Product2>();
        List<Product2> productsToDeleteDRSRelationshipRule = new List<Product2>();
        List<Product2> productsToUpdateDRSRelationshipRuleQuantity = new List<Product2>();

        for (Product2 newProduct : newProducts) {
            Product2 oldProduct = oldProducts?.get(newProduct.Id);

            if (oldProduct == null) {
                if (String.isNotEmpty(newProduct.DRSSKUCode__c)) {
                    productsToCreateDRSRelationshipRule.add(newProduct);
                }
                continue;
            }

            if (newProduct.DRSSKUCode__c != oldProduct.DRSSKUCode__c) {
                if (String.isNotEmpty(newProduct.DRSSKUCode__c)) {
                    productsToCreateDRSRelationshipRule.add(newProduct);
                }
                if (String.isNotEmpty(oldProduct.DRSSKUCode__c)) {
                    productsToDeleteDRSRelationshipRule.add(oldProduct);
                }
                continue;
            }

            if (String.isNotEmpty(newProduct.DRSSKUCode__c) && newProduct.DRSGrossUnits__c != oldProduct.DRSGrossUnits__c) {
                productsToUpdateDRSRelationshipRuleQuantity.add(newProduct);
            }
        }

        ProductService.deleteDRSRelationshipRules(productsToDeleteDRSRelationshipRule);
        ProductService.createDRSRelationshipRules(productsToCreateDRSRelationshipRule);
        ProductService.updateDRSRelationshipRules(productsToUpdateDRSRelationshipRuleQuantity);
    }
}