/**
 * Created by magdalena.stanciu on 03.09.2022.
 */

@IsTest
private with sharing class AccountTriggerHandlerTest {
    @IsTest
    private static void testPrimaryContactAutomationInsertAccountWithPrimaryContact() {
        // create new contact to be set as primary
        Account primaryContactParentAccount = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Contact primaryContact  = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = primaryContactParentAccount.Id));

        // create new DP account and set primary contact
        Test.startTest();
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Primary_Contact__c = primaryContact.Id)
        );
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
                SELECT Id, Phone, Email__c
                FROM Account
                WHERE Id = :dpAccount.Id
        ];

        // check results
        System.assertEquals(primaryContact.Phone, updatedDPAccount.Phone, 'Expecting a different phone number.');
        System.assertEquals(primaryContact.Email, updatedDPAccount.Email__c, 'Expecting a different email.');
    }

    @IsTest
    private static void testPrimaryContactAutomationUpdateAccountPrimaryContact() {
        // create new contact to be set as primary
        Account primaryContactParentAccount = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Contact primaryContact  = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = primaryContactParentAccount.Id));

        // create new DP account
        Account testDPAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, Phone = '+404234234234', Email__c = 'test@test.com')
        );

        // update the primary contact of the DP account
        Test.startTest();
        testDPAccount.aforza__Primary_Contact__c = primaryContact.Id;
        update testDPAccount;
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
                SELECT Id, Phone, Email__c
                FROM Account
                WHERE Id = :testDPAccount.Id
        ];

        // check results
        System.assertEquals(primaryContact.Phone, updatedDPAccount.Phone, 'Expecting a different phone number.');
        System.assertEquals(primaryContact.Email, updatedDPAccount.Email__c, 'Expecting a different email.');
    }

    @IsTest
    private static void testPrimaryContactAutomationRemovePrimaryContact() {
        // create new contact to be set as primary
        Account primaryContactParentAccount = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Contact primaryContact  = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = primaryContactParentAccount.Id));

        // create new DP account and set primary contact; update account by removing primary contact
        Test.startTest();
        // create new DP account and set primary contact
        Account testDPAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Primary_Contact__c = primaryContact.Id)
        );

        testDPAccount.aforza__Primary_Contact__c = null;
        update testDPAccount;
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
                SELECT Id, Phone, Email__c
                FROM Account
                WHERE Id = :testDPAccount.Id
        ];

        // check results
        System.assertEquals(null, updatedDPAccount.Phone, 'Expecting a different phone number.');
        System.assertEquals(null, updatedDPAccount.Email__c, 'Expecting a different email.');
    }

    @IsTest
    private static void testPrimaryContactAutomationPrimaryContactMissingContactDetails() {
        // create new contact to be set as primary
        Account primaryContactParentAccount = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Contact primaryContact  = (Contact) TdfSObjectFactory.insertSObject(new Contact(AccountId = primaryContactParentAccount.Id, Phone = null, Email = null));

        // create new DP account and set primary contact
        Test.startTest();
        Account testDPAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Primary_Contact__c = primaryContact.Id)
        );
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [
                SELECT Id, Phone, Email__c
                FROM Account
                WHERE Id = :testDPAccount.Id
        ];

        // check results
        System.assertEquals(null, updatedDPAccount.Phone, 'Expecting a different phone number.');
        System.assertEquals(null, updatedDPAccount.Email__c, 'Expecting a different email.');
    }

    @IsTest
    private static void testNonCoverageAccountMovedToActiveProspect() {
        // create dp account and add team member
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                IsCoverage__c = FALSE,
                AccountStatus__c = 'Prospect'
        ));
        AccountTeamMember newTeamMember = (AccountTeamMember) TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = dpAccount.Id, TeamMemberRole = 'Field Sales Rep'
        ));

        // update status
        Test.startTest();
        dpAccount.AccountStatus__c = 'Active Prospect';
        update dpAccount;
        Test.stopTest();

        // query team members
        List<AccountTeamMember> teamMembers = [
                SELECT Id
                FROM AccountTeamMember
                WHERE AccountId = :dpAccount.Id AND TeamMemberRole IN ('Field Sales Rep', 'Field Sales Managers')
        ];

        // check results
        System.assertEquals(1, teamMembers.size(), 'Expecting to have team members');
    }

    @IsTest
    private static void testNonCoverageAccountMovedToTraders() {
        // create dp account and add team member
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                IsCoverage__c = FALSE,
                AccountStatus__c = 'Active Prospect'
        ));
        AccountTeamMember newTeamMember = (AccountTeamMember) TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = dpAccount.Id, TeamMemberRole = 'Field Sales Rep'
        ));

        // update status
        Test.startTest();
        dpAccount.AccountStatus__c = 'Traders';
        update dpAccount;
        Test.stopTest();

        // query team members
        List<AccountTeamMember> teamMembers = [
                SELECT Id
                FROM AccountTeamMember
                WHERE AccountId = :dpAccount.Id AND TeamMemberRole IN ('Field Sales Rep', 'Field Sales Managers')
        ];

        // check results
        System.assertEquals(0, teamMembers.size(), 'Expecting to don\'t have team members');
    }

    @IsTest
    private static void testCoverageAccountMovedToActiveProspect() {
        // create dp account and add team member
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                IsCoverage__c = TRUE,
                AccountStatus__c = 'Prospect'
        ));
        AccountTeamMember newTeamMember = (AccountTeamMember) TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = dpAccount.Id, TeamMemberRole = 'Field Sales Rep'
        ));

        // update status
        Test.startTest();
        dpAccount.AccountStatus__c = 'Active Prospect';
        update dpAccount;
        Test.stopTest();

        // query team members
        List<AccountTeamMember> teamMembers = [
                SELECT Id
                FROM AccountTeamMember
                WHERE AccountId = :dpAccount.Id AND TeamMemberRole IN ('Field Sales Rep', 'Field Sales Managers')
        ];

        // check results
        System.assertEquals(1, teamMembers.size(), 'Expecting to have team members');
    }

    @IsTest
    private static void testCoverageAccountMovedToTraders() {
        // create dp account and add team member
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                IsCoverage__c = TRUE,
                AccountStatus__c = 'Active Prospect'
        ));
        AccountTeamMember newTeamMember = (AccountTeamMember) TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = dpAccount.Id, TeamMemberRole = 'Field Sales Rep'
        ));

        // update status
        Test.startTest();
        dpAccount.AccountStatus__c = 'Traders';
        update dpAccount;
        Test.stopTest();

        // query team members
        List<AccountTeamMember> teamMembers = [
                SELECT Id
                FROM AccountTeamMember
                WHERE AccountId = :dpAccount.Id AND TeamMemberRole IN ('Field Sales Rep', 'Field Sales Managers')
        ];

        // check results
        System.assertEquals(1, teamMembers.size(), 'Expecting to have team members');
    }

    @IsTest
    private static void testManageReoccurrenceRecord() {
        Test.startTest();
        TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Test.stopTest();

        aforza__Recurring_Record__c record = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c, aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ][0];

        System.assertNotEquals(null, record);
    }

    @IsTest
    private static void testManageReoccurrenceRecord_InsertNoCreateCallChecked() {
        Test.startTest();
        TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, CreateCalls__c = false));
        Test.stopTest();

        List<aforza__Recurring_Record__c> record = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c, aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];

        System.assertEquals(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_InsertWrongStatus() {
        Test.startTest();
        TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Legal'));
        Test.stopTest();

        List<aforza__Recurring_Record__c> record = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c, aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];

        System.assertEquals(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_InsertWrongRecordType() {
        Test.startTest();
        TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID));
        Test.stopTest();

        List<aforza__Recurring_Record__c> record = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c, aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];

        System.assertEquals(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_InsertNoPrimaryGrid() {
        Test.startTest();
        TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PrimaryGridNumber__c = null));
        Test.stopTest();

        List<aforza__Recurring_Record__c> record = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c, aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];

        System.assertEquals(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_InsertNoStartDate() {
        Test.startTest();
        TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PrimaryStartDate__c = null));
        Test.stopTest();

        List<aforza__Recurring_Record__c> record = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c, aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];

        System.assertEquals(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_UpdateNewPrimaryStartDate() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Date newDate = Date.parse('21/09/2022');

        Test.startTest();
        acc.PrimaryStartDate__c = newDate;
        update acc;
        Test.stopTest();

        aforza__Recurring_Record__c record = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c, aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ][0];

        System.assertEquals(newDate, record.StartDate__c);
    }

    @IsTest
    private static void testManageReoccurrenceRecord_UpdateNewPrimaryGrid() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        Test.startTest();
        acc.PrimaryGridNumber__c = '3C7201WEW'; //changing Call Day of Week (3)
        update acc;
        Test.stopTest();

        aforza__Recurring_Record__c record = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c, aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ][0];

        System.assertEquals('3', record.CallDayOfWeek__c);
    }

    @IsTest
    private static void testManageReoccurrenceRecord_UpdateNoCreateCalls() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        List<aforza__Recurring_Record__c> checkItExists = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c, aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];
        System.assertEquals(1, checkItExists.size());


        Test.startTest();
        acc.CreateCalls__c = false;
        update acc;
        Test.stopTest();

        List<aforza__Recurring_Record__c> record = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c, aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];

        System.assertEquals(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_OutStatus() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        List<aforza__Recurring_Record__c> checkItExists = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c, aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];
        System.assertEquals(1, checkItExists.size());


        Test.startTest();
        acc.AccountStatus__c = 'Legal';
        update acc;
        Test.stopTest();

        List<aforza__Recurring_Record__c> record = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c, aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];

        System.assertEquals(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_UpdateNoGrid() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        List<aforza__Recurring_Record__c> checkItExists = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c, aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];
        System.assertEquals(1, checkItExists.size());


        Test.startTest();
        acc.PrimaryGridNumber__c = '';
        update acc;
        Test.stopTest();

        List<aforza__Recurring_Record__c> record = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c, aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];

        System.assertEquals(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_UpdateNoPrimaryStartDate() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        List<aforza__Recurring_Record__c> checkItExists = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c, aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];
        System.assertEquals(1, checkItExists.size());


        Test.startTest();
        acc.PrimaryStartDate__c = null;
        update acc;
        Test.stopTest();

        List<aforza__Recurring_Record__c> record = [
                SELECT Id, aforza__Type__c, Account__c, OwnerId, Status__c,
                        aforza__Frequency__c, Name, StartDate__c, PlanAnotherVisit__c, DaysBetweenRecurrence__c,
                        aforza__Last_Recurrence_Date__c, CallDayOfWeek__c, Priority__c, aforza__Number_Of_Recurrences__c
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];

        System.assertEquals(0, record.size());
    }
}