/**
 * Created by svatopluk.sejkora on 04.10.2022.
 */

trigger OutletAssetTrigger on aforza__Outlet_Asset__c (after update, after delete) {
    switch on Trigger.operationType {
        when AFTER_UPDATE {
            OutletAssetTriggerHandler.populateBenchmarkFields(Trigger.new, Trigger.oldMap);
        }
        when AFTER_DELETE {
            OutletAssetTriggerHandler.deleteAttributesForFocusedProducts(Trigger.oldMap);
        }
    }
}