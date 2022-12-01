/**
 * Created by svatopluk.sejkora on 11.09.2022.
 */

public with sharing class RecurringRecordService {

    @TestVisible
    private static final CallRecurrenceSetting__mdt CALL_SETTINGS {
        get {
            if (CALL_SETTINGS == null) {
                CALL_SETTINGS = CallRecurrenceSetting__mdt.getInstance('OrgDefaultCallSettings');
            }
            return CALL_SETTINGS;
        }
        set;
    }

    public static void upsertRecurringRecords(List<Account> accounts) {
        List<aforza__Recurring_Record__c> recurringToUpsert = new List<aforza__Recurring_Record__c>();
        for (Account acc : accounts) {
            // we expect that primary is always populated
            recurringToUpsert.add(createRecurringRecord(acc, 'Primary'));
            if (String.isNotEmpty(acc.SecondaryGridNumber__c) && acc.SecondaryStartDate__c != null) {
                recurringToUpsert.add(createRecurringRecord(acc, 'Secondary'));
            }
        }
        upsert recurringToUpsert Name;
    }

    public static void deleteRecurringAndVisitRecords(Set<Id> accountIds) {
        List<aforza__Recurring_Record__c> recurringRecords = getRecurringRecordIds(accountIds);

        if (recurringRecords.size() > 0) {
            VisitCallService.deleteFutureCalls(recurringRecords, System.today());
        }

        delete recurringRecords;
    }

    public static void updateRecurringRecordsLastScheduledDate(Map<Id, Datetime> recurringRecordToLastScheduledDateMap) {
        List<aforza__Recurring_Record__c> recordsToUpdate = new List<aforza__Recurring_Record__c>();
        for (Id recurringRecordId : recurringRecordToLastScheduledDateMap.keySet()) {
            recordsToUpdate.add(new aforza__Recurring_Record__c(Id = recurringRecordId, aforza__Last_Recurrence_Date__c = recurringRecordToLastScheduledDateMap.get(recurringRecordId)));
        }

        update recordsToUpdate;
    }

    @TestVisible
    private static aforza__Recurring_Record__c createRecurringRecord(Account acc, String priority) {
        aforza__Recurring_Record__c recurring = new aforza__Recurring_Record__c();
        recurring.aforza__Type__c = CALL_SETTINGS.CallType__c;
        recurring.Account__c = acc.Id;
        recurring.OwnerId = acc.OwnerId;
        recurring.Status__c = CALL_SETTINGS.CallStatus__c;
        recurring.aforza__Frequency__c = acc.Frequency__c;
        recurring.Name = acc.DeliveryPointReference__c + '_' + acc.Id + '_' + priority;
        recurring.StartDate__c = priority == 'Primary' ? acc.PrimaryStartDate__c : acc.SecondaryStartDate__c;
        recurring.CallDayOfWeek__c = priority == 'Primary' ? acc.PrimaryCallDay__c : acc.SecondaryCallDay__c;
        recurring.aforza__Last_Recurrence_Date__c = null; // setting to null to trigger recreation of visits for any update
        recurring.aforza__Number_Of_Recurrences__c = acc.Frequency__c == 'W' ? 12 : acc.Frequency__c == 'M' ? 3 : acc.Frequency__c == 'F' ? 6 : 12;
        if (acc.PreferredCallTimeTelesales__c != null){
            recurring.Priority__c = 'Custom';
            recurring.StartTime__c = acc.PreferredCallTimeTelesales__c; 
        } else {
            recurring.Priority__c = acc.CallPriority__c;
        }
        return recurring;
    }

    private static List<aforza__Recurring_Record__c> getRecurringRecordIds(Set<Id> accountIds) {
        return [SELECT Id FROM aforza__Recurring_Record__c WHERE Account__c IN :accountIds];
    }

}