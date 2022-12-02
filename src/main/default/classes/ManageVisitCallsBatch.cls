/**
 * Created by svatopluk.sejkora on 12.09.2022.
 */

public without sharing class ManageVisitCallsBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {

    public Iterable<SObject> start(Database.BatchableContext batchableContext) {
        // load all recurring records that has been modified
        String query = 'SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c, ' +
                'aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c, ' +
                'aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c ' +
                'FROM aforza__Recurring_Record__c ' +
                'WHERE PlanAnotherVisit__c = TRUE ' +
                'AND aforza__Type__c = \'Phone Call\'';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext batchableContext, List<aforza__Recurring_Record__c> recurringRecords) {
        VisitCallService.manageVisitCalls(recurringRecords);
    }

    public void finish(Database.BatchableContext param1) {
    }

    public void execute(SchedulableContext schedulableContext) {
        Database.executeBatch(this);
    }
}