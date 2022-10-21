/**
 * Created by svatopluk.sejkora on 04.10.2022.
 */

public with sharing class FocusProductsService {
    private static final List<Product2> FOCUSED_PRODUCTS {
        get {
            if (FOCUSED_PRODUCTS == null) {
                FOCUSED_PRODUCTS = new List<Product2>(
                        FocusProductsService.getFocusProducts()
                );
            }
            return FOCUSED_PRODUCTS;
        }
        set;
    }

    public static List<aforza__Outlet_Asset__c> createFocusProductsForAccounts(Set<Id> accountIds) {
        List<aforza__Outlet_Asset__c> outletAssetsToImport = new List<aforza__Outlet_Asset__c>();
        for (Id accId : accountIds) {
            for (Product2 product : FOCUSED_PRODUCTS) {
                outletAssetsToImport.add(createOutletAsset(accId, product));
            }
        }
        return outletAssetsToImport;
    }

    public static void addNewFocusProducts(Set<Id> accounts, List<Product2> products) {
        // determine if the newly focused products are already attached to account (from previous orders)
        Map<Id, Map<Id, Date>> accountsOutletAssetsByProductId = getAccountsOutletAssets(accounts);
        List<aforza__Outlet_Asset__c> outletAssetsToImport = new List<aforza__Outlet_Asset__c>();

        for (Id accountId : accounts) {
            Set<Id> outletAssetProductIds = new Set<Id>();
            if (accountsOutletAssetsByProductId.size() > 0 && accountsOutletAssetsByProductId.containsKey(accountId)) {
                outletAssetProductIds = accountsOutletAssetsByProductId?.get(accountId).keySet();
            }
            for (Product2 focusedProduct : products) {
                // if the id is not present in current list we add new Asset Outlet
                if (outletAssetProductIds.isEmpty() || !outletAssetProductIds.contains(focusedProduct.Id)) {
                    outletAssetsToImport.add(createOutletAsset(accountId, focusedProduct));
                }
            }
        }
        // running with limit 150, so save up to 50 focused products, in case we need more, the batch size needs to be lowered
        insert outletAssetsToImport;
    }

    private static List<Product2> getFocusProducts() {
        return [SELECT Id, Name, StockKeepingUnit FROM Product2 WHERE FocusFiveProduct__c = TRUE];
    }

    @TestVisible
    private static aforza__Outlet_Asset__c createOutletAsset(Id accId, Product2 product) {
        aforza__Outlet_Asset__c outletAsset = new aforza__Outlet_Asset__c();
        outletAsset.aforza__Account__c = accId;
        outletAsset.aforza__Product__c = product.Id;
        outletAsset.aforza__Name__c = product.Name;
        outletAsset.aforza__Type__c = 'Product';

        return outletAsset;
    }

    @TestVisible
    private static Map<Id, Map<Id, Date>> getAccountsOutletAssets(Set<Id> accountIdsSet) {
        Map<Id, Map<Id, Date>> accountIdToOutletAssetsProductIds = new Map<Id, Map<Id, Date>>();
        for (aforza__Outlet_Asset__c asset : [SELECT Id, aforza__Account__c, aforza__Product__c, aforza__Purchase_Date__c FROM aforza__Outlet_Asset__c WHERE aforza__Account__c IN :accountIdsSet]) {
            if (accountIdToOutletAssetsProductIds.containsKey(asset.aforza__Account__c)) {
                accountIdToOutletAssetsProductIds.get(asset.aforza__Account__c).put(asset.aforza__Product__c, asset.aforza__Purchase_Date__c);
            } else {
                accountIdToOutletAssetsProductIds.put(asset.aforza__Account__c, new Map<Id, Date>{asset.aforza__Product__c => asset.aforza__Purchase_Date__c});
            }
        }
        return accountIdToOutletAssetsProductIds;
    }
}