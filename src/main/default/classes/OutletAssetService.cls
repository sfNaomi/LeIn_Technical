/**
 * Created by svatopluk.sejkora on 04.10.2022.
 */

public with sharing class OutletAssetService {
    private static final List<Product2> FOCUSED_PRODUCTS {
        get {
            if (FOCUSED_PRODUCTS == null) {
                FOCUSED_PRODUCTS = new List<Product2>(
                        getFocusProducts()
                );
            }
            return FOCUSED_PRODUCTS;
        }
        set;
    }

    private static final Map<String, List<Product2>> PERFECT_STORE_PRODUCTS {
        get {
            if (PERFECT_STORE_PRODUCTS == null) {
                PERFECT_STORE_PRODUCTS = new Map<String, List<Product2>>(
                        getPerfectStoreProducts()
                );
            }
            return PERFECT_STORE_PRODUCTS;
        }
        set;
    }

    public static List<aforza__Outlet_Asset__c> createOutletAssetsForAccounts(Set<Account> accounts, AccountTriggerHandler.OutletAssetType outletAssetType) {
        List<aforza__Outlet_Asset__c> outletAssetsToImport = new List<aforza__Outlet_Asset__c>();
        List<Product2> productsToLinkOutletAssetsTo = new List<Product2>();
        for (Account acc : accounts) {
            if (outletAssetType == AccountTriggerHandler.OutletAssetType.FOCUS) {
                productsToLinkOutletAssetsTo = FOCUSED_PRODUCTS;
            } else if (outletAssetType == AccountTriggerHandler.OutletAssetType.PERFECT_SCORE) {
                if (Test.isRunningTest()) {
                    // as the states cannot be added via API/Apex, we are not able to set them in scratch org, thus validation would
                    // be failing and scratch org tests as well. This is why we are using different logic to obtain values.
                    // this should be removed once States can be created via API/Apex - if ever.
                    productsToLinkOutletAssetsTo = PERFECT_STORE_PRODUCTS.get('England');
                } else {
                    productsToLinkOutletAssetsTo = PERFECT_STORE_PRODUCTS.get(acc.ShippingState);
                }
            }

            for (Product2 product : productsToLinkOutletAssetsTo) {
                outletAssetsToImport.add(createOutletAsset(acc.Id, product));
            }
        }
        return outletAssetsToImport;
    }

    public static void addNewOutletAssets(Set<Id> accounts, List<Product2> products) {
        // determine if the newly focused products are already attached to account (from previous orders)
        Map<Id, Map<Id, Date>> accountsOutletAssetsByProductId = getAccountsOutletAssets(accounts);
        List<aforza__Outlet_Asset__c> outletAssetsToImport = new List<aforza__Outlet_Asset__c>();
        System.debug(accounts);
        System.debug(products);

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
        return [SELECT Id, Name, StockKeepingUnit, Family FROM Product2 WHERE FocusFiveProduct__c = TRUE];
    }

    private static Map<String, List<Product2>> getPerfectStoreProducts() {
        Map<String, List<Product2>> stateToProducts = new Map<String, List<Product2>>{
                'England' => new List<Product2>(), 'Scotland' => new List<Product2>()
        };
        for (Product2 product : [
                SELECT Id, Name, StockKeepingUnit, Family, PsProductEngland__c, PsProductScotland__c
                FROM Product2
                WHERE PsProductEngland__c = TRUE
                OR PsProductScotland__c = TRUE
        ]) {
            if (product.PsProductEngland__c) {
                stateToProducts.get('England').add(product);
            }

            if (product.PsProductScotland__c) {
                stateToProducts.get('Scotland').add(product);
            }
        }
        return stateToProducts;
    }

    @TestVisible
    private static aforza__Outlet_Asset__c createOutletAsset(Id accId, Product2 product) {
        aforza__Outlet_Asset__c outletAsset = new aforza__Outlet_Asset__c();
        outletAsset.aforza__Account__c = accId;
        outletAsset.aforza__Product__c = product.Id;
        outletAsset.aforza__Name__c = product.Name;
        outletAsset.aforza__Type__c = product.Family;

        return outletAsset;
    }

    @TestVisible
    private static Map<Id, Map<Id, Date>> getAccountsOutletAssets(Set<Id> accountIdsSet) {
        Map<Id, Map<Id, Date>> accountIdToOutletAssetsProductIds = new Map<Id, Map<Id, Date>>();
        for (aforza__Outlet_Asset__c asset : [SELECT Id, aforza__Account__c, aforza__Product__c, aforza__Purchase_Date__c FROM aforza__Outlet_Asset__c WHERE aforza__Account__c IN :accountIdsSet]) {
            if (accountIdToOutletAssetsProductIds.containsKey(asset.aforza__Account__c)) {
                accountIdToOutletAssetsProductIds.get(asset.aforza__Account__c).put(asset.aforza__Product__c, asset.aforza__Purchase_Date__c);
            } else {
                accountIdToOutletAssetsProductIds.put(asset.aforza__Account__c, new Map<Id, Date>{
                        asset.aforza__Product__c => asset.aforza__Purchase_Date__c
                });
            }
        }
        return accountIdToOutletAssetsProductIds;
    }
}