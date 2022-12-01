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
            throw new PopulateAuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Load__c fetchLoadData(String loadId) {
        try {
            List<Load__c> load = [SELECT Id, Driver__c, Vehicle__c, DeliveryDate__c, RouteIdentification__c FROM Load__c WHERE Id = :loadId];

            return load.isEmpty() ? null : load[0];
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            throw new PopulateAuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Vehicle__c fetchVehicle(String driverName) {
        try {
            List<Vehicle__c> vehicle = [SELECT Id, Driver__c  FROM Vehicle__c WHERE Driver__r.Name LIKE :driverName];

            return vehicle.isEmpty() ? null : vehicle[0];
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            throw new PopulateAuraHandledException(e.getMessage());
        }
    }
}