/**
 * Created by svatopluk.sejkora on 19.10.2022.
 */

trigger LoadTrigger on Load__c (after update) {
    switch on Trigger.operationType {
        when AFTER_UPDATE {
            LoadTriggerHandler.createRouteAndVisitsAndTasks(Trigger.new, Trigger.oldMap);
            LoadTriggerHandler.updateDriver(Trigger.newMap, Trigger.oldMap);
        }
    }
}