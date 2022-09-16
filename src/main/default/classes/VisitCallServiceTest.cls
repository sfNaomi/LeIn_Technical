/**
 * Created by svatopluk.sejkora on 12.09.2022.
 */

@IsTest
private class VisitCallServiceTest {

    /*@IsTest
    private static void testManageVisitCalls_Weekly() {
        // create accounts, we are expecting that trigger will create needed recurring records
        TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PrimaryGridNumber__c = '3C7201MOW',
                PrimaryStartDate__c = VisitCallService.toMonday(System.today()), CallPriority__c = 'P1', PrimaryCallDay__c = '1'));

        List<aforza__Recurring_Record__c> recurringRecords = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c
                FROM aforza__Recurring_Record__c
        ];

        Test.startTest();
        VisitCallService.manageVisitCalls(recurringRecords);
        Test.stopTest();

        List<aforza__Visit__c> visits = [SELECT Id, aforza__Planned_Time__c FROM aforza__Visit__c ORDER BY aforza__Planned_Time__c DESC];
        System.assertEquals(13, visits.size(), 'We expect 13 visits for weekly recurrence');
    }

    @IsTest
    private static void testManageVisitCalls_Monthly() {
        // create accounts, we are expecting that trigger will create needed recurring records
        TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PrimaryGridNumber__c = '3C7201WEM',
                PrimaryStartDate__c = Date.today().addDays(-8), CallPriority__c = 'P2', PrimaryCallDay__c = '3'));

        List<aforza__Recurring_Record__c> recurringRecords = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c
                FROM aforza__Recurring_Record__c
        ];

        Test.startTest();
        VisitCallService.manageVisitCalls(recurringRecords);
        Test.stopTest();

        List<aforza__Visit__c> visits = [SELECT Id, aforza__Planned_Time__c FROM aforza__Visit__c ORDER BY aforza__Planned_Time__c DESC];
        System.assertEquals(3, visits.size(), 'We expect 3 visits for weekly recurrence');
    }

    @IsTest
    private static void testManageVisitCalls_Fortnightly() {
        // create accounts, we are expecting that trigger will create needed recurring records
        TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PrimaryGridNumber__c = '3C7201TH1',
                PrimaryStartDate__c = Date.today().addDays(-8), CallPriority__c = 'P2', PrimaryCallDay__c = '4'));

        List<aforza__Recurring_Record__c> recurringRecords = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c
                FROM aforza__Recurring_Record__c
        ];

        Test.startTest();
        VisitCallService.manageVisitCalls(recurringRecords);
        Test.stopTest();

        List<aforza__Visit__c> visits = [SELECT Id, aforza__Planned_Time__c FROM aforza__Visit__c ORDER BY aforza__Planned_Time__c DESC];
        System.assertEquals(6, visits.size(), 'We expect 6 visits for weekly recurrence');
    }*/

    @IsTest
    private static void testDayOfWeek() {
        Date monday = Date.parse('12/09/2022');

        Test.startTest();
        Integer mondayNumber = VisitCallService.dayOfWeek(monday);
        Test.stopTest();

        System.assertEquals(0, mondayNumber);
    }

    @IsTest
    private static void testToMonday() {
        Date wednesday = Date.parse('13/09/2022');

        Test.startTest();
        Date monday = VisitCallService.toMonday(wednesday);
        Test.stopTest();

        System.assertEquals(Date.parse('12/09/2022'), monday);
    }

    @IsTest
    private static void testIsWorkingDay() {
        Date wednesday = Date.parse('13/09/2022');

        Test.startTest();
        Boolean workingDay = VisitCallService.isWorkingDay(wednesday);
        Test.stopTest();

        System.assert(workingDay);
    }

    @IsTest
    private static void testIsWorkingDay_Sunday() {
        Date sunday = Date.parse('11/09/2022');

        Test.startTest();
        Boolean workingDay = VisitCallService.isWorkingDay(sunday);
        Test.stopTest();

        System.assertEquals(false, workingDay);
    }

    @IsTest
    private static void testFindGivenWeekDaysInNextPeriod() {
        Date callWeekStart = Date.parse('12/09/2022');
        Integer period = 7;
        Integer callingDay = 4;
        Date actualDate = Date.parse('14/09/2022');

        Test.startTest();
        Set<Date> dates = VisitCallService.findGivenWeekDaysInNextPeriod(callWeekStart, period, callingDay, actualDate);
        Test.stopTest();

        List<Date> datesList = new List<Date>(dates);

        for (Integer i = 0; i < datesList.size(); i++) {
            // determine first calling day as call week start + calling date
            // 12.9 + 4 days = 16.9
            Date startDate = Date.parse('16/9/2022');
            Date dateToCheck = startDate.addDays(i * period);
            System.assertEquals(dateToCheck, datesList[i]);
        }
    }

    @IsTest
    private static void testAddStartEndTime() {
        aforza__Visit__c visit = new aforza__Visit__c();
        aforza__Recurring_Record__c recurringRecord = (aforza__Recurring_Record__c) TdfSObjectFactory.createSObject(new aforza__Recurring_Record__c(Priority__c = 'P1'));
        Date scheduledDate = Date.parse('14/09/2022');

        Test.startTest();
        VisitCallService.addStartEndTime(visit, recurringRecord, scheduledDate);
        Test.stopTest();

        System.assertEquals('14/09/2022, 09:00', visit.aforza__Planned_Time__c.format());
        System.assertEquals('14/09/2022, 09:06', visit.aforza__Planned_End_Time__c.format());
    }

    @IsTest
    private static void testAddStartEndTime_Priority2() {
        aforza__Visit__c visit = new aforza__Visit__c();
        aforza__Recurring_Record__c recurringRecord = (aforza__Recurring_Record__c) TdfSObjectFactory.createSObject(new aforza__Recurring_Record__c(Priority__c = 'P2'));
        Date scheduledDate = Date.parse('14/09/2022');

        Test.startTest();
        VisitCallService.addStartEndTime(visit, recurringRecord, scheduledDate);
        Test.stopTest();

        System.assertEquals('14/09/2022, 10:00', visit.aforza__Planned_Time__c.format());
        System.assertEquals('14/09/2022, 10:06', visit.aforza__Planned_End_Time__c.format());
    }

    @IsTest
    private static void testAddStartEndTime_Priority3() {
        aforza__Visit__c visit = new aforza__Visit__c();
        aforza__Recurring_Record__c recurringRecord = (aforza__Recurring_Record__c) TdfSObjectFactory.createSObject(new aforza__Recurring_Record__c(Priority__c = 'P3'));
        Date scheduledDate = Date.parse('14/09/2022');

        Test.startTest();
        VisitCallService.addStartEndTime(visit, recurringRecord, scheduledDate);
        Test.stopTest();

        System.assertEquals('14/09/2022, 11:00', visit.aforza__Planned_Time__c.format());
        System.assertEquals('14/09/2022, 11:06', visit.aforza__Planned_End_Time__c.format());
    }

    @IsTest
    private static void testAddStartEndTime_NoPriority() {
        aforza__Visit__c visit = new aforza__Visit__c();
        aforza__Recurring_Record__c recurringRecord = (aforza__Recurring_Record__c) TdfSObjectFactory.createSObject(new aforza__Recurring_Record__c(Priority__c = ''));
        Date scheduledDate = Date.parse('14/09/2022');

        Test.startTest();
        VisitCallService.addStartEndTime(visit, recurringRecord, scheduledDate);
        Test.stopTest();

        System.assertEquals('14/09/2022, 12:00', visit.aforza__Planned_Time__c.format());
        System.assertEquals('14/09/2022, 12:06', visit.aforza__Planned_End_Time__c.format());
    }

    @IsTest
    private static void testCreateVisit() {
        aforza__Recurring_Record__c recurringRecord = (aforza__Recurring_Record__c) TdfSObjectFactory.insertSObject(new aforza__Recurring_Record__c());
        Date startDate = Date.parse('14/09/2022');

        Test.startTest();
        aforza__Visit__c visit = VisitCallService.createVisit(recurringRecord, startDate);
        Test.stopTest();

        System.assertEquals(visit.aforza__Account__c, recurringRecord.Account__c);
        System.assertEquals(visit.aforza__Owner__c, recurringRecord.OwnerId);
        System.assertEquals(visit.aforza__Type__c, VisitCallService.CALL_SETTINGS.CallType__c);
        System.assertEquals(visit.aforza__Status__c, VisitCallService.CALL_SETTINGS.CallStatus__c);
        System.assertEquals(visit.aforza__Recurring_Record__c, recurringRecord.Id);
    }

   /* @IsTest
    private static void testDeleteFutureCalls() {
        // get all the visits
        aforza__Recurring_Record__c recurringRecord = (aforza__Recurring_Record__c) TdfSObjectFactory.insertSObject(new aforza__Recurring_Record__c());
        Date startDate1 = System.today();
        Date startDate2 = System.today().addDays(7);

        aforza__Visit__c visit1 = VisitCallService.createVisit(recurringRecord, startDate1);
        aforza__Visit__c visit2 = VisitCallService.createVisit(recurringRecord, startDate2);

        insert new List<aforza__Visit__c>{
                visit1, visit2
        };

        Test.startTest();
        VisitCallService.deleteFutureCalls(new List<aforza__Recurring_Record__c>{
                recurringRecord
        }, System.today().addDays(3));
        Test.stopTest();

        List<aforza__Visit__c> leftVisits = [SELECT Id FROM aforza__Visit__c];
        System.assert(leftVisits.size() == 1);
    }

    @IsTest
    private static void testDeleteFutureCalls_NoneLeft() {
        // get all the visits
        aforza__Recurring_Record__c recurringRecord = (aforza__Recurring_Record__c) TdfSObjectFactory.insertSObject(new aforza__Recurring_Record__c());
        Date startDate1 = System.today();
        Date startDate2 = System.today().addDays(7);

        aforza__Visit__c visit1 = VisitCallService.createVisit(recurringRecord, startDate1);
        aforza__Visit__c visit2 = VisitCallService.createVisit(recurringRecord, startDate2);

        insert new List<aforza__Visit__c>{
                visit1, visit2
        };

        Test.startTest();
        VisitCallService.deleteFutureCalls(new List<aforza__Recurring_Record__c>{
                recurringRecord
        }, System.today().addDays(-3));
        Test.stopTest();

        List<aforza__Visit__c> leftVisits = [SELECT Id FROM aforza__Visit__c];
        System.assert(leftVisits.size() == 0);
    }

    @IsTest
    private static void testDeleteFutureCalls_AllStay() {
        // get all the visits
        aforza__Recurring_Record__c recurringRecord = (aforza__Recurring_Record__c) TdfSObjectFactory.insertSObject(new aforza__Recurring_Record__c());
        Date startDate1 = System.today();
        Date startDate2 = System.today().addDays(7);

        aforza__Visit__c visit1 = VisitCallService.createVisit(recurringRecord, startDate1);
        aforza__Visit__c visit2 = VisitCallService.createVisit(recurringRecord, startDate2);

        insert new List<aforza__Visit__c>{
                visit1, visit2
        };

        Test.startTest();
        VisitCallService.deleteFutureCalls(new List<aforza__Recurring_Record__c>{
                recurringRecord
        }, System.today().addDays(13));
        Test.stopTest();

        List<aforza__Visit__c> leftVisits = [SELECT Id FROM aforza__Visit__c];
        System.assert(leftVisits.size() == 2);
    }*/

    @IsTest
    private static void testDetermineLastVisitForEachAccount() {
        aforza__Recurring_Record__c recurringRecord = (aforza__Recurring_Record__c) TdfSObjectFactory.insertSObject(new aforza__Recurring_Record__c());
        Date startDate1 = System.today();
        Date startDate2 = System.today().addDays(7);

        System.assertEquals(null, recurringRecord.aforza__Last_Recurrence_Date__c);

        aforza__Visit__c visit1 = VisitCallService.createVisit(recurringRecord, startDate1);
        aforza__Visit__c visit2 = VisitCallService.createVisit(recurringRecord, startDate2);

        List<aforza__Visit__c> visits = new List<aforza__Visit__c>{
                visit1, visit2
        };

        Test.startTest();
        VisitCallService.determineLastVisitForEachAccount(visits);
        Test.stopTest();

        List<aforza__Recurring_Record__c> updatedRecurring = [SELECT Id, aforza__Last_Recurrence_Date__c FROM aforza__Recurring_Record__c WHERE Id = :recurringRecord.Id];

        Datetime startDateTime = VisitCallService.combineDateAndDatetime(startDate2, VisitCallService.buildStartEndDateTime(09, 00));

        System.assertEquals(1, updatedRecurring.size());
        System.assertEquals(startDateTime, updatedRecurring[0].aforza__Last_Recurrence_Date__c);
    }

    @IsTest
    private static void testGetScheduledCallDates() {
        aforza__Recurring_Record__c recurringRecordInitial = (aforza__Recurring_Record__c)
                TdfSObjectFactory.insertSObject(new aforza__Recurring_Record__c(StartDate__c = Date.parse('20/09/2022')));
        Date actualDate = Date.parse('13/09/2022');

        aforza__Recurring_Record__c recurringRecord = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c
                FROM aforza__Recurring_Record__c
                WHERE Id = :recurringRecordInitial.Id
        ];

        Test.startTest();
        Set<Date> dates = VisitCallService.getScheduledCallDates(recurringRecord, actualDate);
        Test.stopTest();

        List<Date> dateList = new List<Date>(dates);

        // correct date would be 26.09.2022 (second in the list) but this is before removing the ones prior to start date. We are testing specific
        // scenario where start date is in future.
        System.assertEquals(Date.parse('19/09/2022'), dateList[0]);
    }


    @IsTest
    private static void testDropDatesBeforeStartDate() {
        Date startDate = Date.parse('20/09/2022');
        aforza__Recurring_Record__c recurringRecordInitial = (aforza__Recurring_Record__c)
                TdfSObjectFactory.insertSObject(new aforza__Recurring_Record__c(StartDate__c = startDate));
        Date actualDate = Date.parse('13/09/2022');

        aforza__Recurring_Record__c recurringRecord = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c
                FROM aforza__Recurring_Record__c
                WHERE Id = :recurringRecordInitial.Id
        ];
        Set<Date> dates = VisitCallService.getScheduledCallDates(recurringRecord, actualDate);
        List<Date> dateList = new List<Date>(dates);
        System.assertEquals(Date.parse('19/09/2022'), dateList[0]);

        Test.startTest();
        VisitCallService.dropDatesBeforeDate(dates, startDate);
        Test.stopTest();

        dateList.clear();
        dateList = new List<Date>(dates);

        System.assertEquals(Date.parse('26/09/2022'), dateList[0]);
    }

    /*@IsTest
    private static void testManageVisitCalls_AddVisits() {
        // create accounts, we are expecting that trigger will create needed recurring records
        TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PrimaryGridNumber__c = '3C7201MOW',
                PrimaryStartDate__c = Date.today().addDays(-8), CallPriority__c = 'P1', PrimaryCallDay__c = '1'));

        List<aforza__Recurring_Record__c> recurringRecords = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c
                FROM aforza__Recurring_Record__c
        ];
        // create first set of visits
        VisitCallService.manageVisitCalls(recurringRecords);
        // delete the last one and modify Last Recurrence date
        List<aforza__Visit__c> visits = [SELECT Id, aforza__Planned_Time__c FROM aforza__Visit__c ORDER BY aforza__Planned_Time__c DESC LIMIT 1];
        System.debug(visits[0].aforza__Planned_Time__c);
        delete visits;
        // get second latest
        List<aforza__Visit__c> secondLatest = [SELECT Id, aforza__Planned_Time__c FROM aforza__Visit__c ORDER BY aforza__Planned_Time__c DESC LIMIT 1];
        recurringRecords[0].aforza__Last_Recurrence_Date__c = secondLatest[0].aforza__Planned_Time__c;
        update recurringRecords;

        // getting this to check if expected visits would stay
        List<aforza__Visit__c> visitsBeforeUpdate = [SELECT Id, aforza__Planned_Time__c FROM aforza__Visit__c ORDER BY aforza__Planned_Time__c ASC];

        Test.startTest();
        VisitCallService.manageVisitCalls(recurringRecords);
        Test.stopTest();

        List<aforza__Visit__c> finalVisits = [SELECT Id, aforza__Planned_Time__c FROM aforza__Visit__c ORDER BY aforza__Planned_Time__c ASC];
        for (Integer i = 0; i < visitsBeforeUpdate.size(); i++) {
            System.assertEquals(visitsBeforeUpdate[0].Id, finalVisits[0].Id);
        }
    }

    @IsTest
    private static void testManageVisitCalls_RemoveAndAddAllNew() {
        // create accounts, we are expecting that trigger will create needed recurring records
        TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PrimaryGridNumber__c = '3C7201MOW',
                PrimaryStartDate__c = Date.today().addDays(-8), CallPriority__c = 'P1', PrimaryCallDay__c = '1'));

        List<aforza__Recurring_Record__c> recurringRecords = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c
                FROM aforza__Recurring_Record__c
        ];
        // create first set of visits
        VisitCallService.manageVisitCalls(recurringRecords);
        recurringRecords[0].aforza__Last_Recurrence_Date__c = null;
        update recurringRecords;

        // getting this to check if expected visits would stay
        List<aforza__Visit__c> visitsBeforeUpdate = [SELECT Id, aforza__Planned_Time__c FROM aforza__Visit__c ORDER BY aforza__Planned_Time__c ASC];

        Test.startTest();
        VisitCallService.manageVisitCalls(recurringRecords);
        Test.stopTest();

        List<aforza__Visit__c> finalVisits = [SELECT Id, aforza__Planned_Time__c FROM aforza__Visit__c ORDER BY aforza__Planned_Time__c ASC];
        for (Integer i = 0; i < visitsBeforeUpdate.size(); i++) {
            System.assertNotEquals(visitsBeforeUpdate[0].Id, finalVisits[0].Id);
        }
    }*/
}