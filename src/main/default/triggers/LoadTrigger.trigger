/**
 * Created by svatopluk.sejkora on 19.10.2022.
 */

trigger LoadTrigger on Load__c (before insert, before update, after update) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            LoadTriggerHandler.populateDefaultInventory(Trigger.new, null);
        }
        when BEFORE_UPDATE {
            LoadTriggerHandler.populateDefaultInventory(Trigger.new, Trigger.oldMap);
        }
        when AFTER_UPDATE {
            LoadTriggerHandler.createRouteAndVisitsAndTasks(Trigger.new, Trigger.oldMap);
            LoadTriggerHandler.updateDriverAndDeliveryDate(Trigger.newMap, Trigger.oldMap);
        }
    }
}