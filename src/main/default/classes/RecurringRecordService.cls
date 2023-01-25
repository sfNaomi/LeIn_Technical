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

    public static void upsertRecurringRecords(List<AccountToTamDto> accountsToTam) {
        List<aforza__Recurring_Record__c> recurringToUpsert = new List<aforza__Recurring_Record__c>();
        for (AccountToTamDto accToTam : accountsToTam) {
            // we expect that primary is always populated
            recurringToUpsert.add(createRecurringRecord(accToTam, 'Primary'));
            if (String.isNotEmpty(accToTam.account.SecondaryGridNumber__c) && accToTam.account.SecondaryStartDate__c != null) {
                recurringToUpsert.add(createRecurringRecord(accToTam, 'Secondary'));
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
    private static aforza__Recurring_Record__c createRecurringRecord(AccountToTamDto accToTam, String priority) {
        aforza__Recurring_Record__c recurring = new aforza__Recurring_Record__c();
        recurring.aforza__Type__c = CALL_SETTINGS.CallType__c;
        recurring.Account__c = accToTam.account.Id;
        recurring.OwnerId = accToTam.tamId;
        recurring.Status__c = CALL_SETTINGS.CallStatus__c;
        recurring.aforza__Frequency__c = accToTam.account.Frequency__c;
        recurring.Name = /*accToTam.account.DeliveryPointReference__c + */'_' + accToTam.account.Id + '_' + priority;
        recurring.StartDate__c = priority == 'Primary' ? accToTam.account.PrimaryStartDate__c : accToTam.account.SecondaryStartDate__c;
        recurring.CallDayOfWeek__c = priority == 'Primary' ? accToTam.account.PrimaryCallDay__c : accToTam.account.SecondaryCallDay__c;
        recurring.aforza__Last_Recurrence_Date__c = null; // setting to null to trigger recreation of visits for any update
        recurring.aforza__Number_Of_Recurrences__c = accToTam.account.Frequency__c == 'W' ? 12 : accToTam.account.Frequency__c == 'M' ? 3 : accToTam.account.Frequency__c == 'F' ? 6 : 12;
        if (accToTam.account.PreferredCallTimeTelesales__c != null) {
            recurring.Priority__c = 'Custom';
            recurring.StartTime__c = accToTam.account.PreferredCallTimeTelesales__c;
        } else {
            recurring.Priority__c = accToTam.account.CallPriority__c;
        }
        return recurring;
    }

    private static List<aforza__Recurring_Record__c> getRecurringRecordIds(Set<Id> accountIds) {
        return [SELECT Id FROM aforza__Recurring_Record__c WHERE Account__c IN :accountIds];
    }

    public class AccountToTamDto {
        public Account account;
        public Id tamId;

        public AccountToTamDto(Account account, Id tamId) {
            this.account = account;
            this.tamId = tamId;
        }
    }
}