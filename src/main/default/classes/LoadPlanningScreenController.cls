/**
 * Created by svatopluk.sejkora on 12.10.2022.
 */

public with sharing class LoadPlanningScreenController {

    @AuraEnabled
    public static List<Order> fetchOrdersForLoad(String fieldsToGet, String loadId) {
        try {
            String sQuery = 'SELECT ';
            sQuery += fieldsToGet;
            sQuery += ' FROM Order WHERE Load__c = \'' + loadId + '\'';

            List<Order> orders = Database.query(sQuery);

            return orders.isEmpty() ? null : orders;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Load__c fetchLoadData(String loadId) {
        try {
            List<Load__c> load = [SELECT Id, Driver__c, Vehicle__c, DeliveryDate__c FROM Load__c WHERE Id = :loadId];

            return load.isEmpty() ? null : load[0];
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
}