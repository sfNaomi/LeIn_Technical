/**
 * Created by svatopluk.sejkora on 12.09.2022.
 */

public without sharing class VisitCallService {

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

    public static void manageVisitCalls(List<aforza__Recurring_Record__c> recurringRecords) {
        // always look for items to delete, and delete anything in future.
        Date actualDate = System.today();
        List<aforza__Recurring_Record__c> filteredRecurringRecords = filterRecurringRecordsForVisitDeletion(recurringRecords);
        deleteFutureCalls(filteredRecurringRecords, actualDate);

        // recreate all visits for each recurring record from now on
        List<aforza__Visit__c> visits = createNewCalls(recurringRecords, actualDate);
        insert visits;
        determineLastVisitForEachAccount(visits);
    }

    private static List<aforza__Recurring_Record__c> filterRecurringRecordsForVisitDeletion(List<aforza__Recurring_Record__c> recurringRecords) {
        List<aforza__Recurring_Record__c> filteredRecurringRecords = new List<aforza__Recurring_Record__c>();
        for (aforza__Recurring_Record__c recurringRecord : recurringRecords) {
            if (recurringRecord.aforza__Last_Recurrence_Date__c == null) {
                filteredRecurringRecords.add(recurringRecord);
            }
        }

        return filteredRecurringRecords;
    }

    private static List<aforza__Visit__c> createNewCalls(List<aforza__Recurring_Record__c> recurringRecords, Date actualDate) {
        List<aforza__Visit__c> scheduledVisits = new List<aforza__Visit__c>();
        for (aforza__Recurring_Record__c recurring : recurringRecords) {
            Set<Date> scheduledDates = getScheduledCallDates(recurring, actualDate);
            dropDatesBeforeDate(scheduledDates, recurring.StartDate__c);
            if (recurring.aforza__Last_Recurrence_Date__c != null) {
                dropDatesBeforeDate(scheduledDates, recurring.aforza__Last_Recurrence_Date__c.date());
            }
            scheduledVisits.addAll(createVisitsFromDates(scheduledDates, recurring));
        }
        return scheduledVisits;
    }

    @TestVisible
    private static Set<Date> getScheduledCallDates(aforza__Recurring_Record__c recurringRecord, Date actualDate) {
        Date startDateMonday = toMonday(recurringRecord.StartDate__c);
        Date thisWeekMonday = toMonday(actualDate);

        Integer periodInDays = Integer.valueOf(recurringRecord.DaysBetweenRecurrence__c);

        Date mostRecentCallWeekStart;
        if (startDateMonday >= thisWeekMonday) {
            mostRecentCallWeekStart = startDateMonday; // startDate is in this week or later
        } else {
            // start date is in previous weeks, find latest week matching the period
            Integer daysBetweenMondays = startDateMonday.daysBetween(thisWeekMonday);
            mostRecentCallWeekStart = thisWeekMonday.addDays(-Math.mod(daysBetweenMondays, periodInDays));
        }
        Integer callingDay = Integer.valueOf(recurringRecord.CallDayOfWeek__c) - 1; // subtract 1 to get numbering based on SF numbering of week days (Sunday = 1)

        return findGivenWeekDaysInNextPeriod(mostRecentCallWeekStart, periodInDays, callingDay, actualDate);
    }

    @TestVisible
    private static void dropDatesBeforeDate(Set<Date> scheduledDates, Date startDate) {
        for (Date possibleDate : scheduledDates) {
            if (possibleDate < startDate) {
                scheduledDates.remove(possibleDate);
            }
        }
    }

    private static List<aforza__Visit__c> createVisitsFromDates(Set<Date> scheduledDates, aforza__Recurring_Record__c recurring) {
        List<aforza__Visit__c> visits = new List<aforza__Visit__c>();
        if (scheduledDates != null) {
            for (Date scheduledDate : scheduledDates) {
                visits.add(createVisit(recurring, scheduledDate));
            }
        }

        return visits;
    }

    @TestVisible
    private static void determineLastVisitForEachAccount(List<aforza__Visit__c> visits) {
        Map<Id, Datetime> recurringRecordToLastScheduledDateMap = new Map<Id, Datetime>();
        for (aforza__Visit__c visit : visits) {
            if (recurringRecordToLastScheduledDateMap.get(visit.aforza__Recurring_Record__c) == null) {
                recurringRecordToLastScheduledDateMap.put(visit.aforza__Recurring_Record__c, visit.aforza__Planned_Time__c);
            } else if (recurringRecordToLastScheduledDateMap.get(visit.aforza__Recurring_Record__c) < visit.aforza__Planned_Time__c) {
                recurringRecordToLastScheduledDateMap.put(visit.aforza__Recurring_Record__c, visit.aforza__Planned_Time__c);
            }
        }
        RecurringRecordService.updateRecurringRecordsLastScheduledDate(recurringRecordToLastScheduledDateMap);
    }

    public static void deleteFutureCalls(List<aforza__Recurring_Record__c> recurringRecords, Date actualDate) {
        List<aforza__Visit__c> visitsToDelete = [SELECT Id FROM aforza__Visit__c WHERE aforza__Recurring_Record__c IN :recurringRecords AND aforza__Planned_Time__c > :actualDate];

        delete visitsToDelete;
    }

    @TestVisible
    private static aforza__Visit__c createVisit(aforza__Recurring_Record__c recurringRecord, Date scheduledDate) {
        aforza__Visit__c visit = new aforza__Visit__c();
        visit.RecordTypeId = RecordTypes.VISIT_REMOTE_VISIT_ID;
        visit.aforza__Account__c = recurringRecord.Account__c;
        visit.aforza__Owner__c = recurringRecord.OwnerId;
        visit.aforza__Type__c = recurringRecord.aforza__Type__c;
        visit.aforza__Status__c = recurringRecord.Status__c;
        visit.aforza__Recurring_Record__c = recurringRecord.Id;

        addStartEndTime(visit, recurringRecord, scheduledDate);

        return visit;
    }

    @TestVisible
    private static void addStartEndTime(aforza__Visit__c visit, aforza__Recurring_Record__c recurringRecord, Date scheduledDate) {
        switch on recurringRecord.Priority__c {
            when 'P1' {
                visit.aforza__Planned_Time__c = combineDateAndDatetime(scheduledDate, buildStartEndDateTime(09, 00));
                visit.aforza__Planned_End_Time__c = combineDateAndDatetime(scheduledDate, buildStartEndDateTime(09, 06));
            }
            when 'P2' {
                visit.aforza__Planned_Time__c = combineDateAndDatetime(scheduledDate, buildStartEndDateTime(10, 00));
                visit.aforza__Planned_End_Time__c = combineDateAndDatetime(scheduledDate, buildStartEndDateTime(10, 06));
            }
            when 'P3' {
                visit.aforza__Planned_Time__c = combineDateAndDatetime(scheduledDate, buildStartEndDateTime(11, 00));
                visit.aforza__Planned_End_Time__c = combineDateAndDatetime(scheduledDate, buildStartEndDateTime(11, 06));
            }
            when else {
                visit.aforza__Planned_Time__c = combineDateAndDatetime(scheduledDate, buildStartEndDateTime(12, 00));
                visit.aforza__Planned_End_Time__c = combineDateAndDatetime(scheduledDate, buildStartEndDateTime(12, 06));
            }
        }
    }

    @TestVisible
    private static Datetime buildStartEndDateTime(Integer hour, Integer minute) {
        return Datetime.newInstance(2022, 09, 05, hour, minute, 00);
    }

    @TestVisible
    private static Datetime combineDateAndDatetime(Date visitDate, Datetime visitTime) {
        return Datetime.newInstance(visitDate, visitTime.time());
    }

    @TestVisible
    private static Set<Date> findGivenWeekDaysInNextPeriod(Date callWeekStart, Integer period, Integer callingDay, Date actualDate) {
        Set<Date> foundDates = new Set<Date>();
        Date day = actualDate;
        day = day.addDays(Integer.valueOf(CALL_SETTINGS.GenerateVisitsForNextAmountOfDays__c));

        // find limit day = as per settings (and last) working day since now (including today)
        Date limitDate = day.addDays(-1);
        while (callWeekStart <= limitDate) {
            Date candidate = callWeekStart.addDays(callingDay);
            if (isWorkingDay(candidate) && candidate >= actualDate && candidate <= limitDate) {
                foundDates.add(candidate);
            }
            callWeekStart = callWeekStart.addDays(period);
        }
        return foundDates;
    }

    @TestVisible
    private static Boolean isWorkingDay(Date day) {
        Integer dayOfWeek = dayOfWeek(day);
        if (dayOfWeek == 5 || dayOfWeek == 6) {
            return false;
        }
        return true;
    }

    @TestVisible
    private static Date toMonday(Date d) {
        return d.addDays(-dayOfWeek(d));
    }

    @TestVisible
    private static Integer dayOfWeek(Date d) {
        Integer day = Math.mod(Date.newInstance(2001, 1, 1).daysBetween(d), 7); // 1/1/2001 was a Monday
        return day;
    }
}