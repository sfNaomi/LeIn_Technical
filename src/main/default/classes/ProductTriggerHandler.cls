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

    public static void manageFocusProducts(List<Product2> products, Map<Id, Product2> oldMap) {
        List<Product2> focusedProducts = new List<Product2>();
        Set<String> notFocusedProductsSkus = new Set<String>();
        Set<Id> notFocusedProductsIds = new Set<Id>();
        for (Product2 product : products) {
            Product2 oldProduct = oldMap?.get(product.Id);
            if (oldProduct == null && product.FocusFiveProduct__c == true) {
                focusedProducts.add(product);
                continue;
            }
            if (product.FocusFiveProduct__c == true && oldProduct != null && oldProduct.FocusFiveProduct__c <> product.FocusFiveProduct__c) {
                focusedProducts.add(product);
                continue;
            }
            if (product.FocusFiveProduct__c == false && oldProduct != null && oldProduct.FocusFiveProduct__c <> product.FocusFiveProduct__c) {
                notFocusedProductsSkus.add(product.StockKeepingUnit);
                notFocusedProductsIds.add(product.Id);
            }
        }

        if (focusedProducts.size() > 0) {
            AttributesService.createAttributes(focusedProducts);
            Database.executeBatch(new CreateOutletAssetsProductsBatch(focusedProducts), 150);
        }

        if (notFocusedProductsSkus.size() > 0) {
            AttributesService.deactivateAttributes(notFocusedProductsSkus);
            Database.executeBatch(new RemoveOutletAssetsProductBatch(notFocusedProductsIds));
        }
    }
}