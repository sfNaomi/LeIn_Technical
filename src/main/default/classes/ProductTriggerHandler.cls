/**
 * Created by magdalena.stanciu on 19.09.2022.
 */

public with sharing class ProductTriggerHandler {

    public enum OutletAssetType {
        FOCUS,
        PERFECT_SCORE
    }

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
            Database.executeBatch(new CreateOutletAssetsProductsBatch(focusedProducts, OutletAssetType.FOCUS, null), 150);
        }

        if (notFocusedProductsSkus.size() > 0) {
            AttributesService.deactivateAttributes(notFocusedProductsSkus);
            Database.executeBatch(new RemoveOutletAssetsProductBatch(notFocusedProductsIds, OutletAssetType.FOCUS, null));
        }
    }

    public static void managePerfectScoreProducts(List<Product2> products, Map<Id, Product2> oldMap) {
        List<Product2> perfectScoreEnglandProducts = new List<Product2>();
        List<Product2> perfectScoreScotlandProducts = new List<Product2>();
        Set<Id> notPerfectScoreEnglandIds = new Set<Id>();
        Set<Id> notPerfectScoreScotlandIds = new Set<Id>();

        for (Product2 product : products) {
            Product2 oldProduct = oldMap?.get(product.Id);
            if (oldProduct == null && product.PsProductEngland__c == true) {
                perfectScoreEnglandProducts.add(product);
            }

            if (oldProduct == null && product.PsProductScotland__c == true) {
                perfectScoreScotlandProducts.add(product);
            }

            if (product.PsProductEngland__c == true && oldProduct != null && oldProduct.PsProductEngland__c <> product.PsProductEngland__c) {
                perfectScoreEnglandProducts.add(product);
            }

            if (product.PsProductScotland__c == true && oldProduct != null && oldProduct.PsProductScotland__c <> product.PsProductScotland__c) {
                perfectScoreScotlandProducts.add(product);
            }

            if (product.PsProductEngland__c == false && oldProduct != null && oldProduct.PsProductEngland__c <> product.PsProductEngland__c) {
                notPerfectScoreEnglandIds.add(product.Id);
            }

            if (product.PsProductScotland__c == false && oldProduct != null && oldProduct.PsProductScotland__c <> product.PsProductScotland__c) {
                notPerfectScoreScotlandIds.add(product.Id);
            }
        }

        if (perfectScoreEnglandProducts.size() > 0) {
            Database.executeBatch(new CreateOutletAssetsProductsBatch(perfectScoreEnglandProducts, OutletAssetType.PERFECT_SCORE, 'England'), 150);
        }

        if (perfectScoreScotlandProducts.size() > 0) {
            Database.executeBatch(new CreateOutletAssetsProductsBatch(perfectScoreScotlandProducts, OutletAssetType.PERFECT_SCORE, 'Scotland'), 150);
        }

        if (notPerfectScoreEnglandIds.size() > 0) {
            Database.executeBatch(new RemoveOutletAssetsProductBatch(notPerfectScoreEnglandIds, OutletAssetType.PERFECT_SCORE, 'England'));
        }

        if (notPerfectScoreScotlandIds.size() > 0) {
            Database.executeBatch(new RemoveOutletAssetsProductBatch(notPerfectScoreScotlandIds, OutletAssetType.PERFECT_SCORE, 'Scotland'));
        }
    }
}