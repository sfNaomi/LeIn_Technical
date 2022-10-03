/**
 * Created by svatopluk.sejkora on 01.10.2022.
 */

@IsTest
private class AccountTeamMemberTriggerHandlerTest {
    @IsTest
    private static void testManageReoccurrenceRecord() {
        Test.startTest();
        TdfSObjectFactory.insertSObject(new AccountTeamMember());
        Test.stopTest();

        aforza__Recurring_Record__c record = [
                SELECT
                        Id,
                        aforza__Type__c,
                        Account__c,
                        OwnerId,
                        Status__c,
                        aforza__Frequency__c,
                        Name,
                        StartDate__c,
                        PlanAnotherVisit__c,
                        DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c,
                        CallDayOfWeek__c,
                        Priority__c,
                        aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ][0];

        System.assertNotEquals(null, record);
    }

    @IsTest
    private static void testManageReoccurrenceRecord_InsertNoCreateCallChecked() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, CreateCalls__c = false));

        Test.startTest();
        TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id));
        Test.stopTest();

        List<aforza__Recurring_Record__c> record = [
                SELECT
                        Id,
                        aforza__Type__c,
                        Account__c,
                        OwnerId,
                        Status__c,
                        aforza__Frequency__c,
                        Name,
                        StartDate__c,
                        PlanAnotherVisit__c,
                        DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c,
                        CallDayOfWeek__c,
                        Priority__c,
                        aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];

        System.assertEquals(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_InsertWrongStatus() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Legal'));
        Test.startTest();
        TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id));
        Test.stopTest();

        List<aforza__Recurring_Record__c> record = [
                SELECT
                        Id,
                        aforza__Type__c,
                        Account__c,
                        OwnerId,
                        Status__c,
                        aforza__Frequency__c,
                        Name,
                        StartDate__c,
                        PlanAnotherVisit__c,
                        DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c,
                        CallDayOfWeek__c,
                        Priority__c,
                        aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];

        System.assertEquals(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_InsertWrongRecordType() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID));

        Test.startTest();
        TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id));
        Test.stopTest();

        List<aforza__Recurring_Record__c> record = [
                SELECT
                        Id,
                        aforza__Type__c,
                        Account__c,
                        OwnerId,
                        Status__c,
                        aforza__Frequency__c,
                        Name,
                        StartDate__c,
                        PlanAnotherVisit__c,
                        DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c,
                        CallDayOfWeek__c,
                        Priority__c,
                        aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];

        System.assertEquals(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_InsertNoPrimaryGrid() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PrimaryGridNumber__c = null));

        Test.startTest();
        TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id));
        Test.stopTest();

        List<aforza__Recurring_Record__c> record = [
                SELECT
                        Id,
                        aforza__Type__c,
                        Account__c,
                        OwnerId,
                        Status__c,
                        aforza__Frequency__c,
                        Name,
                        StartDate__c,
                        PlanAnotherVisit__c,
                        DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c,
                        CallDayOfWeek__c,
                        Priority__c,
                        aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];

        System.assertEquals(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_InsertNoStartDate() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PrimaryStartDate__c = null));

        Test.startTest();
        TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id));
        Test.stopTest();

        List<aforza__Recurring_Record__c> record = [
                SELECT
                        Id,
                        aforza__Type__c,
                        Account__c,
                        OwnerId,
                        Status__c,
                        aforza__Frequency__c,
                        Name,
                        StartDate__c,
                        PlanAnotherVisit__c,
                        DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c,
                        CallDayOfWeek__c,
                        Priority__c,
                        aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];

        System.assertEquals(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_OutStatus() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );
        TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id));

        List<aforza__Recurring_Record__c> checkIfExistsRecord = [
                SELECT
                        Id,
                        aforza__Type__c,
                        Account__c,
                        OwnerId,
                        Status__c,
                        aforza__Frequency__c,
                        Name,
                        StartDate__c,
                        PlanAnotherVisit__c,
                        DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c,
                        CallDayOfWeek__c,
                        Priority__c,
                        aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];
        System.assertEquals(1, checkIfExistsRecord.size());

        Test.startTest();
        acc.AccountStatus__c = 'Legal';
        update acc;
        Test.stopTest();

        List<aforza__Recurring_Record__c> record = [
                SELECT
                        Id,
                        aforza__Type__c,
                        Account__c,
                        OwnerId,
                        Status__c,
                        aforza__Frequency__c,
                        Name,
                        StartDate__c,
                        PlanAnotherVisit__c,
                        DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c,
                        CallDayOfWeek__c,
                        Priority__c,
                        aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];

        System.assertEquals(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_DeleteTamRecord() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );
        AccountTeamMember accountTeamMember = (AccountTeamMember) TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id));

        List<aforza__Recurring_Record__c> checkIfExistsRecord = [
                SELECT
                        Id,
                        aforza__Type__c,
                        Account__c,
                        OwnerId,
                        Status__c,
                        aforza__Frequency__c,
                        Name,
                        StartDate__c,
                        PlanAnotherVisit__c,
                        DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c,
                        CallDayOfWeek__c,
                        Priority__c,
                        aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];
        System.assertEquals(1, checkIfExistsRecord.size());

        Test.startTest();
        delete accountTeamMember;
        Test.stopTest();

        List<aforza__Recurring_Record__c> record = [
                SELECT
                        Id,
                        aforza__Type__c,
                        Account__c,
                        OwnerId,
                        Status__c,
                        aforza__Frequency__c,
                        Name,
                        StartDate__c,
                        PlanAnotherVisit__c,
                        DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c,
                        CallDayOfWeek__c,
                        Priority__c,
                        aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];

        System.assertEquals(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_ChangeToNotTam() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );
        AccountTeamMember accountTeamMember = (AccountTeamMember) TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id));

        List<aforza__Recurring_Record__c> checkIfExistsRecord = [
                SELECT
                        Id,
                        aforza__Type__c,
                        Account__c,
                        OwnerId,
                        Status__c,
                        aforza__Frequency__c,
                        Name,
                        StartDate__c,
                        PlanAnotherVisit__c,
                        DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c,
                        CallDayOfWeek__c,
                        Priority__c,
                        aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];
        System.assertEquals(1, checkIfExistsRecord.size());

        Test.startTest();
        accountTeamMember.TeamMemberRole = 'Driver';
        update accountTeamMember;
        Test.stopTest();

        List<aforza__Recurring_Record__c> record = [
                SELECT
                        Id,
                        aforza__Type__c,
                        Account__c,
                        OwnerId,
                        Status__c,
                        aforza__Frequency__c,
                        Name,
                        StartDate__c,
                        PlanAnotherVisit__c,
                        DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c,
                        CallDayOfWeek__c,
                        Priority__c,
                        aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];

        System.assertEquals(0, record.size());
    }

    @IsTest
    private static void testAllowOnlyOneTamUserPerAccount() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );
        TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id));

        Test.startTest();
        try {
            TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id));
            System.assert(false, 'We expect an error to be thrown');
        } catch (Exception e) {
            System.assertEquals('Exceptions.TdfSObjectFactoryException', e.getTypeName());
            System.assert(e.getMessage().contains('There can be only one TAM user assigned to each'));
        }
        Test.stopTest();
    }

    @IsTest
    private static void testAllowOnlyOneTamUserPerAccount_DifferentMember() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );
        TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id));

        User user = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(user) {
            User newUser = (User) TdfSObjectFactory.insertSObject(new User());

            Test.startTest();
            TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id, TeamMemberRole = 'Driver', UserId = newUser.Id));
            Test.stopTest();
        }

        List<AccountTeamMember> members = [SELECT Id FROM AccountTeamMember WHERE AccountId = :acc.Id];

        System.assertEquals(2, members.size());
    }

    @IsTest
    private static void testAllowOnlyOneTamUserPerAccount_TryMoreTamsInSingleTransaction() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );

        User user = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(user) {
            User newUser = (User) TdfSObjectFactory.insertSObject(new User());
            List<AccountTeamMember> accountTeamMembers = new List<AccountTeamMember>();
            accountTeamMembers.add((AccountTeamMember) TdfSObjectFactory.createSObject(new AccountTeamMember(AccountId = acc.Id)));
            accountTeamMembers.add((AccountTeamMember) TdfSObjectFactory.createSObject(new AccountTeamMember(AccountId = acc.Id, UserId = newUser.Id)));

            Test.startTest();
            try {
                insert accountTeamMembers;
                System.assert(false, 'We expect an error to be thrown');
            } catch (Exception e) {
                System.assertEquals('System.DmlException', e.getTypeName());
                System.assert(e.getMessage().contains('There can be only one TAM user assigned to each'));
            }
            Test.stopTest();
        }
    }

    @IsTest
    private static void testManageReoccurrenceRecord_ChangeToTam() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );
        AccountTeamMember accountTeamMember = (AccountTeamMember) TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id, TeamMemberRole = 'Driver'));

        List<aforza__Recurring_Record__c> recordFirst = [
                SELECT
                        Id
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];

        System.assertEquals(0, recordFirst.size());

        Test.startTest();
        accountTeamMember.TeamMemberRole = 'TAM';
        update accountTeamMember;
        Test.stopTest();

        List<aforza__Recurring_Record__c> record = [
                SELECT
                        Id
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];

        System.assertEquals(1, record.size());
    }
}