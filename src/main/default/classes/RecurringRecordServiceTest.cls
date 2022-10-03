/**
 * Created by svatopluk.sejkora on 12.09.2022.
 */

@IsTest
private class RecurringRecordServiceTest {

    @IsTest
    private static void testCreateRecurringRecord() {
        TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Account acc = [
                SELECT Id, OwnerId, Frequency__c, DeliveryPointReference__c, PrimaryStartDate__c,
                        SecondaryStartDate__c, PrimaryGridNumber__c, CallPriority__c, PrimaryCallDay__c,
                        SecondaryCallDay__c
                FROM Account
        ];

        Test.startTest();
        aforza__Recurring_Record__c recurringRecord = RecurringRecordService.createRecurringRecord(acc, 'Primary');
        insert recurringRecord;
        Test.stopTest();

        aforza__Recurring_Record__c record = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c, aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ][0];

        System.assertEquals(acc.OwnerId, record.OwnerId);
        System.assertEquals(RecurringRecordService.CALL_SETTINGS.CallType__c, record.aforza__Type__c);
        System.assertEquals(acc.Id, record.Account__c);
        System.assertEquals(RecurringRecordService.CALL_SETTINGS.CallStatus__c, record.Status__c);
        System.assertEquals(acc.Frequency__c, record.aforza__Frequency__c);
        System.assertEquals(true, record.Name.contains('Primary'));
        System.assertEquals(acc.PrimaryStartDate__c, record.StartDate__c);
        System.assertEquals(acc.CallPriority__c, record.Priority__c);
        System.assertEquals(acc.PrimaryCallDay__c, record.CallDayOfWeek__c);
        System.assertEquals(null, record.aforza__Last_Recurrence_Date__c);
        System.assertEquals(12, record.aforza__Number_Of_Recurrences__c, 'We expect 12 for W Frequency (part of Primary Grid)');
    }

    @IsTest
    private static void testUpsertRecurringRecords_SecondaryGrid() {
        TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, SecondaryGridNumber__c = '3C7201WEW',
                SecondaryStartDate__c = Date.parse('07/09/2022')));

        Account acc = [
                SELECT Id, OwnerId, Frequency__c, DeliveryPointReference__c, PrimaryStartDate__c,
                        SecondaryStartDate__c, PrimaryGridNumber__c, SecondaryGridNumber__c, CallPriority__c, PrimaryCallDay__c,
                        SecondaryCallDay__c
                FROM Account
        ];

        Test.startTest();
        RecurringRecordService.upsertRecurringRecords(new List<Account>{
                acc
        });
        Test.stopTest();

        List<aforza__Recurring_Record__c> records = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c
                FROM aforza__Recurring_Record__c
        ];

        System.assertEquals(2, records.size());
    }

    @IsTest
    private static void testUpsertRecurringRecords_PrimaryGrid() {
        TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        Account acc = [
                SELECT Id, OwnerId, Frequency__c, DeliveryPointReference__c, PrimaryStartDate__c,
                        SecondaryStartDate__c, PrimaryGridNumber__c, SecondaryGridNumber__c, CallPriority__c, PrimaryCallDay__c,
                        SecondaryCallDay__c
                FROM Account
        ];

        Test.startTest();
        RecurringRecordService.upsertRecurringRecords(new List<Account>{
                acc
        });
        Test.stopTest();

        List<aforza__Recurring_Record__c> records = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c
                FROM aforza__Recurring_Record__c
        ];

        System.assertEquals(1, records.size());
    }

    @IsTest
    private static void testCreateRecurringRecord_Upsert() {
        TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Account acc = [
                SELECT Id, OwnerId, Frequency__c, DeliveryPointReference__c, PrimaryStartDate__c,
                        SecondaryStartDate__c, PrimaryGridNumber__c, CallPriority__c, PrimaryCallDay__c,
                        SecondaryCallDay__c
                FROM Account
        ];

        TdfSObjectFactory.insertSObject(new aforza__Recurring_Record__c(Account__c = acc.Id, aforza__Last_Recurrence_Date__c = System.today(), Name = '100001_' + acc.Id + '_Primary'));

        Test.startTest();
        acc.PrimaryGridNumber__c = '3C7201WEM';
        update acc;
        Test.stopTest();

        aforza__Recurring_Record__c record = [
                SELECT Id, aforza__Last_Recurrence_Date__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ][0];

        System.assertEquals(null, record.aforza__Last_Recurrence_Date__c);
    }

    @IsTest
    private static void testUpdateRecurringRecordsLastScheduledDate() {
        aforza__Recurring_Record__c recurringRecord = (aforza__Recurring_Record__c) TdfSObjectFactory.insertSObject(new aforza__Recurring_Record__c());

        Datetime newDate = System.now();

        Test.startTest();
        RecurringRecordService.updateRecurringRecordsLastScheduledDate(new Map<Id, Datetime>{
                recurringRecord.Id => newDate
        });
        Test.stopTest();

        aforza__Recurring_Record__c record = [
                SELECT Id, aforza__Last_Recurrence_Date__c
                FROM aforza__Recurring_Record__c
                WHERE Id = :recurringRecord.Id
                LIMIT 1
        ][0];

        System.assertEquals(newDate, record.aforza__Last_Recurrence_Date__c);
    }

    @IsTest
    private static void testDeleteRecurringAndVisitRecords() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        aforza__Recurring_Record__c recurringRecord = (aforza__Recurring_Record__c) TdfSObjectFactory.insertSObject(new aforza__Recurring_Record__c(Account__c = acc.Id));

        TdfSObjectFactory.insertSObjects(
                new aforza__Visit__c(aforza__Account__c = acc.Id, aforza__Recurring_Record__c = recurringRecord.Id,
                        RecordTypeId = RecordTypes.VISIT_REMOTE_VISIT_ID), 10);

        Test.startTest();
        RecurringRecordService.deleteRecurringAndVisitRecords(new Set<Id>{
                acc.Id
        });
        Test.stopTest();

        List<aforza__Visit__c> deletedVisits = [SELECT Id FROM aforza__Visit__c];
        System.assertEquals(0, deletedVisits.size());
    }
}