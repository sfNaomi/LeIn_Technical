/**
 * Created by svatopluk.sejkora on 19.10.2022.
 */

public with sharing class LoadTriggerHandler {

    public static void createRouteAndVisitsAndTasks(List<Load__c> loads, Map<Id, Load__c> oldLoadsMap) {
        Set<Id> loadsToCreateVisitsFor = new Set<Id>();
        for (Load__c load : loads) {
            if (load.CreateRoute__c && oldLoadsMap.get(load.Id).CreateRoute__c <> load.CreateRoute__c) {
                loadsToCreateVisitsFor.add(load.Id);
            }
        }
        if (loadsToCreateVisitsFor.size() > 0) {
            // get orders for loads in a map, and start preparing of records
            Map<Id, List<Order>> loadsWithOrderIds = prepareLoadToOrdersMap(loadsToCreateVisitsFor);
            Map<String, Id> routeTerritoryCodeToIds = checkIfTerritoryExistsCreateNewIfNot();

            createRoutesAndLocations(loadsWithOrderIds, routeTerritoryCodeToIds);
            createVisitsAndTasks(loadsWithOrderIds);
        }
    }

    public static void updateDriverAndDeliveryDate(Map<Id, Load__c> loadsMap, Map<Id, Load__c> oldLoadsMap) {
        Set<Id> loadIdsToTriggerChangeFor = new Set<Id>();
        for (Load__c load : loadsMap.values()) {
            Load__c oldLoad = oldLoadsMap.get(load.Id);
            if (load.CreateRoute__c && (load.Driver__c <> oldLoad.Driver__c || load.DeliveryDate__c <> oldLoad.DeliveryDate__c)) {
                loadIdsToTriggerChangeFor.add(load.Id);
            }
        }
        updateRoutesWithNewDrive(loadIdsToTriggerChangeFor, loadsMap);
        updateTaskAndVisitWithNewDriverAndDate(loadIdsToTriggerChangeFor, loadsMap);
    }

    private static void updateTaskAndVisitWithNewDriverAndDate(Set<Id> loadIdsToTriggerChangeFor, Map<Id, Load__c> loadsMap) {
        List<SObject> taskAndVisitToUpdate = new List<SObject>();
        Set<SObject> uniqueVisitsToUpdate = new Set<SObject>();
        for (Task task : getTasksAndVisitsForOrdersFromLoad(loadIdsToTriggerChangeFor)) {
            Load__c load = loadsMap.get(task.aforza__Order__r.Load__c);
            // set task owner to new driver and new date
            task.OwnerId = load.Driver__c;
            taskAndVisitToUpdate.add(task);
            // set owner of the visit to new driver too and also populate new dates
            aforza__Visit__c visitToUpdate = new aforza__Visit__c();
            visitToUpdate.Id = task.aforza__Visit__c;
            visitToUpdate.aforza__Owner__c = load.Driver__c;
            visitToUpdate.aforza__Planned_Time__c = combineDateAndDatetime(load.DeliveryDate__c, buildStartEndDateTime(08, 00));
            visitToUpdate.aforza__Planned_End_Time__c = combineDateAndDatetime(load.DeliveryDate__c, buildStartEndDateTime(08, 15));
            uniqueVisitsToUpdate.add(visitToUpdate);
        }
        taskAndVisitToUpdate.addAll(uniqueVisitsToUpdate);
        update taskAndVisitToUpdate;
    }

    private static void updateRoutesWithNewDrive(Set<Id> loadIdsToTriggerChangeFor, Map<Id, Load__c> loadsMap) {
        List<aforza__Route__c> routesToUpdate = getRoutesForLoad(loadIdsToTriggerChangeFor);
        for (aforza__Route__c route : routesToUpdate) {
            Load__c load = loadsMap.get(route.LoadId__c);
            route.Name = createRouteName(load.Name, load.DriverFullName__c);
        }
        update routesToUpdate;
    }

    private static String createRouteName(String loadName, String driverName) {
        return loadName + ' - ' + driverName;
    }

    private static List<aforza__Route__c> getRoutesForLoad(Set<Id> loadIds) {
        return [SELECT Id, Name, LoadId__c FROM aforza__Route__c WHERE LoadId__c IN :loadIds];
    }

    private static List<Task> getTasksAndVisitsForOrdersFromLoad(Set<Id> loadIdsToTriggerChangeFor) {
        return [SELECT Id, aforza__Visit__c, OwnerId, aforza__Order__r.Load__c FROM Task WHERE aforza__Order__r.Load__c IN :loadIdsToTriggerChangeFor];
    }

    private static void createVisitsAndTasks(Map<Id, List<Order>> loadsWithOrderIds) {
        Map<String, aforza__Visit__c> visitsToInsertLinkedToLoad = new Map<String, aforza__Visit__c>();
        List<Task> tasksToInsert = new List<Task>();
        Map<Id, Id> ordersToOrderWithVisit = new Map<Id, Id>();

        // check if the collect unpaid invoice task should be created
        Map<Id, Boolean> accountIdToUnpaidInvoiceFlag = determineIfThereIsUnpaidInvoice(loadsWithOrderIds.values());

        for (List<Order> orderList : loadsWithOrderIds.values()) {
            // make sure we create visit only once per account, not for all orders
            Set<Id> orderAccounts = new Set<Id>();
            Id orderWithVisit;
            for (Order order : orderList) {
                if (!orderAccounts.contains(order.AccountId)) {
                    orderAccounts.add(order.AccountId);
                    visitsToInsertLinkedToLoad.put(order.Id, mapDataToVisit(order));
                    orderWithVisit = order.Id;
                    ordersToOrderWithVisit.put(order.Id, orderWithVisit);
                    // create invoice collection task, only one per Account
                    if (accountIdToUnpaidInvoiceFlag.get(order.AccountId)) {
                        tasksToInsert.add(mapDataToTask(order, 'Collect Payment for unpaid invoices', 2, 'Payment Collection'));
                    }
                } else {
                    ordersToOrderWithVisit.put(order.Id, orderWithVisit);
                }
                // create delivery task for each order
                tasksToInsert.add(mapDataToTask(order, 'Deliver Order', 1, 'Order'));
            }
        }
        Database.insert(visitsToInsertLinkedToLoad.values());

        for (Task task : tasksToInsert) {
            // get order with visit Id for this task
            Id orderWithVisit = ordersToOrderWithVisit.get(task.aforza__Order__c);
            task.aforza__Visit__c = visitsToInsertLinkedToLoad.get(orderWithVisit).Id;
        }
        insert tasksToInsert;
    }

    private static void createRoutesAndLocations(Map<Id, List<Order>> loadsWithOrderIds, Map<String, Id> routeTerritoryCodeToIds) {
        List<aforza__Route__c> routesToInsert = new List<aforza__Route__c>();
        List<aforza__Route_Location__c> locationsToInsert = new List<aforza__Route_Location__c>();
        List<Load__c> loadsToUpdate = new List<Load__c>();
        for (Id loadId : loadsWithOrderIds.keySet()) {
            // create route based on the first item from orders with load fields
            List<Order> orders = loadsWithOrderIds.get(loadId);
            routesToInsert.add(mapDataToRoute(orders[0], routeTerritoryCodeToIds, loadId));

            // create load object to update it via external ID
            loadsToUpdate.add(mapDataToLoad(loadId));

            // create locations
            // make sure we create location only once per account, not for all orders
            Set<Id> orderAccounts = new Set<Id>();
            for (Order order : orders) {
                Integer count = 1;
                if (!orderAccounts.contains(order.AccountId)) {
                    orderAccounts.add(order.AccountId);
                    locationsToInsert.add(mapDataToRouteLocation(order, loadId, count));
                    count++;
                }
            }
        }
        List<SObject> sobjectsToInsert = new List<SObject>();
        sobjectsToInsert.addAll(routesToInsert);
        sobjectsToInsert.addAll(locationsToInsert);

        insert sobjectsToInsert;
        update loadsToUpdate;
    }

    @TestVisible
    private static aforza__Route__c mapDataToRoute(Order order, Map<String, Id> routeTerritoryCodeToIds, Id loadId) {
        aforza__Route__c route = new aforza__Route__c();
        route.Name = createRouteName(order.Load__r.Name, order.Load__r.DriverFullName__c);
        route.aforza__Status__c = 'Active';
        route.aforza__Route_Territory__c = routeTerritoryCodeToIds.get(order.Load__r.Depot__c);
        route.LoadId__c = loadId;

        return route;
    }

    @TestVisible
    private static aforza__Route_Location__c mapDataToRouteLocation(Order order, Id loadId, Integer count) {
        aforza__Route_Location__c location = new aforza__Route_Location__c();
        location.aforza__Route__r = new aforza__Route__c(LoadId__c = loadId);
        location.Name = order.AccountName__c;
        location.aforza__Account__c = order.AccountId;
        location.aforza__Distance_From_Last_Location__c = 1;
        location.aforza__Duration_From_Last_Location__c = 900;
        location.aforza__Sequence__c = count;

        return location;
    }

    @TestVisible
    private static aforza__Visit__c mapDataToVisit(Order order) {
        aforza__Visit__c visit = new aforza__Visit__c();
        visit.RecordTypeId = RecordTypes.VISIT_DIRECT_VISIT_ID;
        visit.aforza__Type__c = 'Outlet Visit';
        visit.aforza__Account__c = order.AccountId;
        visit.aforza__Owner__c = order.Load__r.Driver__c;
        visit.aforza__Status__c = 'Not Started';
        visit.aforza__Planned_Time__c = combineDateAndDatetime(order.Load__r.DeliveryDate__c, buildStartEndDateTime(08, 00));
        visit.aforza__Planned_End_Time__c = combineDateAndDatetime(order.Load__r.DeliveryDate__c, buildStartEndDateTime(08, 15));

        return visit;
    }

    @TestVisible
    private static Task mapDataToTask(Order order, String subject, Integer sequence, String type) {
        Task task = new Task();
        task.Subject = subject;
        task.Status = 'Not Started';
        task.aforza__Type__c = type;
        task.aforza__Order__c = order.Id;
        task.Priority = 'High';
        task.aforza__Sequence__c = sequence;
        task.WhatId = order.Id;
        task.OwnerId = order.Load__r.Driver__c;

        return task;
    }

    @TestVisible
    private static Load__c mapDataToLoad(Id loadId) {
        Load__c loadToUpdate = new Load__c();
        loadToUpdate.Route__r = new aforza__Route__c(LoadId__c = loadId);
        loadToUpdate.Id = loadId;
        return loadToUpdate;
    }


    @TestVisible
    private static Map<Id, List<Order>> prepareLoadToOrdersMap(Set<Id> loadIds) {
        Map<Id, List<Order>> loadsWithOrderIds = new Map<Id, List<Order>>();
        for (Order order : [
            SELECT Id, Load__c, AccountId, Load__r.Driver__c, Load__r.DeliveryDate__c,
                Load__r.Depot__c, Load__r.Name, Load__r.DriverFullName__c, AccountName__c
            FROM Order
            WHERE Load__c IN :loadIds
            ORDER BY Account.ShippingPostalCode ASC
        ]) {
            if (loadsWithOrderIds.containsKey(order.Load__c)) {
                loadsWithOrderIds.get(order.Load__c).add(order);
            } else {
                loadsWithOrderIds.put(order.Load__c, new List<Order>{
                    order
                });
            }
        }
        return loadsWithOrderIds;
    }

    @TestVisible
    private static Map<String, Id> checkIfTerritoryExistsCreateNewIfNot() {
        Map<String, String> depotCodeToLabel = getNeededDepotCodesAndLabels();
        List<aforza__Route_Territory__c> territories = [SELECT Id, aforza__Territory_ID__c FROM aforza__Route_Territory__c];
        Map<String, Id> existingTerritoryCodesToIDMap = new Map<String, Id>();

        for (aforza__Route_Territory__c territory : territories) {
            existingTerritoryCodesToIDMap.put(territory.aforza__Territory_ID__c, territory.Id);
        }

        List<aforza__Route_Territory__c> newTerritories = new List<aforza__Route_Territory__c>();
        Map<String, Id> territoryCodeToId = new Map<String, Id>();
        for (String depotCode : depotCodeToLabel.keySet()) {
            if (existingTerritoryCodesToIDMap.containsKey(depotCode)) {
                territoryCodeToId.put(depotCode, existingTerritoryCodesToIDMap.get(depotCode));
            } else {
                aforza__Route_Territory__c territory = new aforza__Route_Territory__c();
                territory.Name = depotCodeToLabel.get(depotCode);
                territory.aforza__Territory_ID__c = depotCode;

                newTerritories.add(territory);
            }
        }

        insert newTerritories;

        for (aforza__Route_Territory__c territory : newTerritories) {
            territoryCodeToId.put(territory.aforza__Territory_ID__c, territory.Id);
        }
        return territoryCodeToId;
    }

    @TestVisible
    private static Map<String, String> getNeededDepotCodesAndLabels() {
        Map<String, String> depotCodeToLabel = new Map<String, String>();
        for (PicklistEntry picklistEntry : DescriptionSobjectService.getPicklistEntries('Depot__c', 'Load__c')) {
            depotCodeToLabel.put(picklistEntry.getValue(), picklistEntry.getLabel());
        }
        return depotCodeToLabel;
    }

    // TODO duplicated code for time operations from VisitCallService. Would be nice to refactor to TimeService class
    @TestVisible
    private static Datetime buildStartEndDateTime(Integer hour, Integer minute) {
        return Datetime.newInstance(2022, 09, 05, hour, minute, 00);
    }

    @TestVisible
    private static Datetime combineDateAndDatetime(Date visitDate, Datetime visitTime) {
        return Datetime.newInstance(visitDate, visitTime.time());
    }

    public static void populateDefaultInventory(List<Load__c> newLoads, Map<Id, Load__c> oldLoads) {
        Map<String, Id> inventoryIdMap = InventoryService.getDepotInventoryMapping();
        for (Load__c newLoad : newLoads) {
            Load__c oldLoad = oldLoads?.get(newLoad.Id);
            if (
                (oldLoad == null && newLoad.Depot__c != null) ||
                    (oldLoad != null && newLoad.Depot__c != oldLoad.Depot__c)
            ) {
                newLoad.SiteNo__c = inventoryIdMap.get(newLoad.Depot__c);
            }
        }
    }

    public static void setCorrectLoadName(List<Load__c> newLoads, Map<Id, Load__c> oldLoads) {
        Map<Date, List<Load__c>> newLoadsMap = new Map<Date, List<Load__c>>();
        Set<String> newLoadsDepotList = new Set<String>();
        Set<String> newLoadsRouteIdentificationList = new Set<String>();
        for (Load__c newLoad : newLoads) {
            Load__c oldLoad = oldLoads?.get(newLoad.Id);
            if (
                (
                    (oldLoad == null) ||
                        (oldLoad != null &&
                            (
                                (newLoad.Depot__c != oldLoad.Depot__c) ||
                                    (newLoad.DeliveryDate__c != oldLoad.DeliveryDate__c) ||
                                    (newLoad.RouteIdentification__c != oldLoad.RouteIdentification__c)
                            )
                        )
                ) && (newLoad.Depot__c != null && newLoad.DeliveryDate__c != null && newLoad.RouteIdentification__c != null)
            ) {
                if (newLoadsMap.containsKey(newLoad.DeliveryDate__c)) {
                    newLoadsMap.get(newLoad.DeliveryDate__c).add(newLoad);
                } else {
                    newLoadsMap.put(newLoad.DeliveryDate__c, new List<Load__c>{
                        newLoad
                    });
                }
                newLoadsDepotList.add(newLoad.Depot__c);
                newLoadsRouteIdentificationList.add(newLoad.RouteIdentification__c);
            }
        }
        setCorrectLastTwoDigitsOnLoadName(newLoadsMap, getExistingLoadsLastTwoDigits(newLoadsMap, newLoadsDepotList, newLoadsRouteIdentificationList));
    }

    private static Map<String, Integer> getExistingLoadsLastTwoDigits(Map<Date, List<Load__c>> newLoadsMap, Set<String> newLoadsDepotList, Set<String> newLoadsRouteIdentificationList) {
        List<AggregateResult> existingLoadsForSameDateDepotAndRoute = [
            SELECT COUNT(Id) similarLoadsCount, Depot__c, RouteIdentification__c, DeliveryDate__c
            FROM Load__c
            WHERE Depot__c IN :newLoadsDepotList
            AND RouteIdentification__c IN :newLoadsRouteIdentificationList
            AND DeliveryDate__c IN :newLoadsMap.keySet()
            GROUP BY Depot__c, RouteIdentification__c, DeliveryDate__c
        ];

        Map<String, Integer> loadsLastTwoDigits = new Map<String, Integer>();

        for (AggregateResult existingLoad : existingLoadsForSameDateDepotAndRoute) {
            String loadCombinationKey = getLoadCombinationKey(existingLoad);
            Integer similarExistingLoadsCount = (Integer) existingLoad.get('similarLoadsCount');
            loadsLastTwoDigits.put(loadCombinationKey, similarExistingLoadsCount);
        }
        return loadsLastTwoDigits;
    }

    private static void setCorrectLastTwoDigitsOnLoadName(Map<Date, List<Load__c>> newLoadsMap, Map<String, Integer> loadsLastTwoDigits) {
        for (List<Load__c> loadsList : newLoadsMap.values()) {
            for (Load__c newLoad : loadsList) {
                String newLoadCombinationKey = getLoadCombinationKey(newLoad);
                if (!loadsLastTwoDigits.containsKey(newLoadCombinationKey)) {
                    loadsLastTwoDigits.put(newLoadCombinationKey, 1);
                    newLoad.Name = newLoadCombinationKey + '-' + '01';
                } else {
                    Integer higherExistingLoadNumber = loadsLastTwoDigits.get(newLoadCombinationKey);
                    higherExistingLoadNumber++;
                    loadsLastTwoDigits.put(newLoadCombinationKey, higherExistingLoadNumber);
                    if (higherExistingLoadNumber < 10) {
                        newLoad.Name = newLoadCombinationKey + '-' + '0' + (higherExistingLoadNumber);
                    } else {
                        newLoad.Name = newLoadCombinationKey + '-' + (higherExistingLoadNumber);
                    }
                }
            }
        }
    }

    private static String getLoadCombinationKey(SObject loadOrAggregateResult) {
        Datetime deliveryDate = (Datetime) loadOrAggregateResult.get('DeliveryDate__c');
        String loadCombinationKey = loadOrAggregateResult.get('Depot__c') + '-' + loadOrAggregateResult.get('RouteIdentification__c') + '-' + deliveryDate.format('dd/MM/yy');

        return loadCombinationKey;
    }

    private static Map<Id, Boolean> determineIfThereIsUnpaidInvoice(List<List<Order>> orders) {
        Set<Id> orderAccountIds = getAccountIdsFromOrders(orders);
        return getAccountsWithUnpaidInvoices(orderAccountIds);
    }

    private static Set<Id> getAccountIdsFromOrders(List<List<Order>> orders) {
        Set<Id> orderAccountIds = new Set<Id>();
        for (List<Order> orderList : orders) {
            for (Order order : orderList) {
                orderAccountIds.add(order.AccountId);
            }
        }
        return orderAccountIds;
    }

    private static Map<Id, Boolean> getAccountsWithUnpaidInvoices(Set<Id> accountIds) {
        Map<Id, Boolean> accountIdToUnpaidInvoiceFlag = new Map<Id, Boolean>();
        for (Account acc : [
            SELECT Id, (
                SELECT
                    Id
                FROM aforza__Billing_Statements__r
                WHERE aforza__Status__c != 'Paid'
                AND aforza__Status__c != 'Approved for Payment'
                AND aforza__Issued_Date__c = LAST_N_DAYS:62
            )
            FROM Account
            WHERE Id IN :accountIds
        ]) {
            if (acc.aforza__Billing_Statements__r.size() == 0) {
                accountIdToUnpaidInvoiceFlag.put(acc.Id, false);
            } else {
                accountIdToUnpaidInvoiceFlag.put(acc.Id, true);
            }
        }

        return accountIdToUnpaidInvoiceFlag;
    }
}