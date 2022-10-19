/**
 * Created by svatopluk.sejkora on 13.10.2022.
 */

public with sharing class LoadPlanningAssignmentController {
    @AuraEnabled
    public static Decimal fetchVehicleLoadWeight(String vehicleId) {
        try {
            List<Vehicle__c> vehicles = [SELECT Id, LoadCapacityWeight__c FROM Vehicle__c WHERE Id = :vehicleId];
            return vehicles.isEmpty() ? 0 : vehicles[0].LoadCapacityWeight__c;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            throw new PopulateAuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Load__c upsertLoad(Load__c load) {
        try {
            upsert load Id;
            Load__c loadName = [SELECT Id, Name, DeliveryDate__c FROM Load__c WHERE Id = :load.Id];

            return loadName;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            throw new PopulateAuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateOrdersWithLoadIdAndNewStatus(List<String> orderIds, String newStatus, String loadId) {
        try {
            List<Order> ordersToUpdate = new List<Order>();
            for (String orderId : orderIds) {
                Order order = new Order();
                order.Id = orderId;
                order.Load__c = loadId;
                order.Status = newStatus;
                ordersToUpdate.add(order);
            }

            update ordersToUpdate;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            throw new PopulateAuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void processDeselectedOrders(List<Order> deselectedOrderIds) {
        try {
            Map<String, RemoveOrdersFromLoadStatusMapping__mdt> mappings = RemoveOrdersFromLoadStatusMapping__mdt.getAll();

            for (Order order : deselectedOrderIds) {
                String processedStatus = order.Status.deleteWhitespace().toLowerCase();
                if (mappings.containsKey(processedStatus)) {
                    order.Status = mappings.get(processedStatus).TargetOrderStatus__c;
                    order.Load__c = null;
                    if (mappings.get(processedStatus).SetReplanToTrue__c) {
                        order.Replanned__c = true;
                    }
                }
            }

            update deselectedOrderIds;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            throw new PopulateAuraHandledException(e.getMessage());
        }
    }
}