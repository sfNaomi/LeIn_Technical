/**
 * Created by svatopluk.sejkora on 11.09.2022.
 */

public with sharing class RecurringRecordService {

    private static final CallCreationSettings__c CALL_SETTING {
        get {
            if (CALL_SETTING == null) {
                CALL_SETTING = CallCreationSettings__c.getOrgDefaults();
            }
            return CALL_SETTING;
        }
        set;
    }

    public static void manageRecurringRecords(List<Account> accounts) {

    }

    private static aforza__Recurring_Record__c createRecurringRecord(Account acc) {
        aforza__Recurring_Record__c recurring = new aforza__Recurring_Record__c();
        recurring.aforza__Type__c = CALL_SETTING.CallType__c;
        recurring.Account__c = acc.Id;
        recurring.OwnerId = acc.OwnerId;
        recurring.Status__c = CALL_SETTING.CallStatus__c;
        recurring.aforza__Frequency__c = acc.Frequency__c;

        return recurring;
    }

}