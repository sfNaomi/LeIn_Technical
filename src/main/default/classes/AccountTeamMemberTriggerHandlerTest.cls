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

        Assert.areNotEqual(null, record);
    }

    @IsTest
    private static void testManageReoccurrenceRecord_InsertNoCreateCallChecked() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, CreateCalls__c = false)
        );

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

        Assert.areEqual(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_InsertWrongStatus() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Legal')
        );
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

        Assert.areEqual(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_InsertWrongRecordType() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID)
        );

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

        Assert.areEqual(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_InsertNoPrimaryGrid() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PrimaryGridNumber__c = null)
        );

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

        Assert.areEqual(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_InsertNoStartDate() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PrimaryStartDate__c = null)
        );

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

        Assert.areEqual(0, record.size());
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
        Assert.areEqual(1, checkIfExistsRecord.size());

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

        Assert.areEqual(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_DeleteTamRecord() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );
        AccountTeamMember accountTeamMember = (AccountTeamMember) TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = acc.Id)
        );

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
        Assert.areEqual(1, checkIfExistsRecord.size());

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

        Assert.areEqual(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_ChangeToNotTam() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );
        AccountTeamMember accountTeamMember = (AccountTeamMember) TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = acc.Id)
        );

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
        Assert.areEqual(1, checkIfExistsRecord.size());

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

        Assert.areEqual(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_ChangeToTam() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );
        AccountTeamMember accountTeamMember = (AccountTeamMember) TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = acc.Id, TeamMemberRole = 'Driver')
        );

        List<aforza__Recurring_Record__c> recordFirst = [
            SELECT Id
            FROM aforza__Recurring_Record__c
            LIMIT 1
        ];

        Assert.areEqual(0, recordFirst.size());

        Test.startTest();
        accountTeamMember.TeamMemberRole = 'TAM';
        update accountTeamMember;
        Test.stopTest();

        List<aforza__Recurring_Record__c> record = [
                SELECT Id
                FROM aforza__Recurring_Record__c
                LIMIT 1
        ];

        Assert.areEqual(1, record.size());
    }

    @IsTest
    private static void testAllowOnlyOneUserWithSpecifiedRolePerAccount_TAM() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id, TeamMemberRole = 'TAM'));

        System.runAs(runningUser) {
            User newUser = (User) TdfSObjectFactory.insertSObject(new User());

            Test.startTest();
            try {
                TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id, UserId = newUser.Id, TeamMemberRole = 'TAM'));
                Assert.isTrue(false, 'We expect an error to be thrown');
            } catch (Exception e) {
                Assert.areEqual('Exceptions.TdfSObjectFactoryException', e.getTypeName());
                Assert.isTrue(e.getMessage().contains('There is already a user with the'));
            }
            Test.stopTest();
        }
    }

    @IsTest
    private static void testAllowOnlyOneUserWithSpecifiedRolePerAccount_FieldSalesRep() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id, TeamMemberRole = 'Field Sales Rep'));

        System.runAs(runningUser) {
            User newUser = (User) TdfSObjectFactory.insertSObject(new User());

            Test.startTest();
            try {
                TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id, UserId = newUser.Id, TeamMemberRole = 'Field Sales Rep'));
                Assert.isTrue(false, 'We expect an error to be thrown');
            } catch (Exception e) {
                Assert.areEqual('Exceptions.TdfSObjectFactoryException', e.getTypeName());
                Assert.isTrue(e.getMessage().contains('There is already a user with the'));
            }
            Test.stopTest();
        }
    }

    @IsTest
    private static void testAllowOnlyOneUserWithSpecifiedRolePerAccount_Driver() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id, TeamMemberRole = 'Driver'));

        System.runAs(runningUser) {
            User newUser = (User) TdfSObjectFactory.insertSObject(new User());

            Test.startTest();
            try {
                TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id, UserId = newUser.Id, TeamMemberRole = 'Driver'));
                Assert.isTrue(false, 'We expect an error to be thrown');
            } catch (Exception e) {
                Assert.areEqual('Exceptions.TdfSObjectFactoryException', e.getTypeName());
                Assert.isTrue(e.getMessage().contains('There is already a user with the'));
            }
            Test.stopTest();
        }
    }

    @IsTest
    private static void testAllowOnlyOneUserWithSpecifiedRolePerAccount_ExistingTAMInsertDifferentRole() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );
        TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id, TeamMemberRole = 'TAM'));

        System.runAs(runningUser) {
            User newUser = (User) TdfSObjectFactory.insertSObject(new User());

            Test.startTest();
            TdfSObjectFactory.insertSObject(
                new AccountTeamMember(AccountId = acc.Id, TeamMemberRole = 'Driver', UserId = newUser.Id)
            );
            Test.stopTest();
        }

        List<AccountTeamMember> members = [SELECT Id FROM AccountTeamMember WHERE AccountId = :acc.Id];

        Assert.areEqual(2, members.size());
    }

    @IsTest
    private static void testAllowOnlyOneUserWithSpecifiedRolePerAccount_ExistingFieldSalesRepInsertDifferentRole() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id, TeamMemberRole = 'Field Sales Rep'));

        System.runAs(runningUser) {
            User newUser = (User) TdfSObjectFactory.insertSObject(new User());

            Test.startTest();
            TdfSObjectFactory.insertSObject(
                new AccountTeamMember(AccountId = acc.Id, TeamMemberRole = 'Driver', UserId = newUser.Id)
            );
            Test.stopTest();
        }

        List<AccountTeamMember> members = [SELECT Id FROM AccountTeamMember WHERE AccountId = :acc.Id];

        Assert.areEqual(2, members.size());
    }

    @IsTest
    private static void testAllowOnlyUserWithSpecifiedRolePerAccount_TryMoreTamsInSingleTransaction() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );

        System.runAs(runningUser) {
            User newUser = (User) TdfSObjectFactory.insertSObject(new User());

            List<AccountTeamMember> accountTeamMembers = new List<AccountTeamMember>();
            accountTeamMembers.add((AccountTeamMember) TdfSObjectFactory.createSObject(
                new AccountTeamMember(AccountId = acc.Id, TeamMemberRole = 'TAM'))
            );
            accountTeamMembers.add((AccountTeamMember) TdfSObjectFactory.createSObject(
                new AccountTeamMember(AccountId = acc.Id, UserId = newUser.Id, TeamMemberRole = 'TAM'))
            );

            Test.startTest();
            try {
                insert accountTeamMembers;
                Assert.isTrue(false, 'We expect an error to be thrown');
            } catch (Exception e) {
                Assert.areEqual('System.DmlException', e.getTypeName());
                Assert.isTrue(e.getMessage().contains('There is already a user with the'));
            }
            Test.stopTest();
        }
    }

    @IsTest
    private static void testAllowOnlyUserWithSpecifiedRolePerAccount_TryMoreFieldSalesRepsInSingleTransaction() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        System.runAs(runningUser) {
            User newUser = (User) TdfSObjectFactory.insertSObject(new User());

            List<AccountTeamMember> accountTeamMembers = new List<AccountTeamMember>();
            accountTeamMembers.add((AccountTeamMember) TdfSObjectFactory.createSObject(
                new AccountTeamMember(AccountId = acc.Id, TeamMemberRole = 'Field Sales Rep'))
            );
            accountTeamMembers.add((AccountTeamMember) TdfSObjectFactory.createSObject(
                new AccountTeamMember(AccountId = acc.Id, UserId = newUser.Id, TeamMemberRole = 'Field Sales Rep'))
            );

            Test.startTest();
            try {
                insert accountTeamMembers;
                Assert.isTrue(false, 'We expect an error to be thrown');
            } catch (Exception e) {
                Assert.areEqual('System.DmlException', e.getTypeName());
                Assert.isTrue(e.getMessage().contains('There is already a user with the'));
            }
            Test.stopTest();
        }
    }

    @IsTest
    private static void testAllowOnlyUserWithSpecifiedRolePerAccount_TryTamAndFieldSalesRepsInSingleTransaction() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        System.runAs(runningUser) {
            User newUser = (User) TdfSObjectFactory.insertSObject(new User());

            List<AccountTeamMember> accountTeamMembers = new List<AccountTeamMember>();
            accountTeamMembers.add((AccountTeamMember) TdfSObjectFactory.createSObject(
                new AccountTeamMember(AccountId = acc.Id, TeamMemberRole = 'TAM'))
            );
            accountTeamMembers.add((AccountTeamMember) TdfSObjectFactory.createSObject(
                new AccountTeamMember(AccountId = acc.Id, UserId = newUser.Id, TeamMemberRole = 'Field Sales Rep'))
            );

            Test.startTest();
            insert accountTeamMembers;
            Test.stopTest();

            List<AccountTeamMember> members = [SELECT Id FROM AccountTeamMember WHERE AccountId = :acc.Id];

            Assert.areEqual(2, members.size());
        }
    }

    @IsTest
    private static void testAllowOnlyUserWithSpecifiedRolePerAccount_ExchangeRolesInSingleTransaction() {
        User newUser = (User) TdfSObjectFactory.insertSObject(new User());

        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        AccountTeamMember accountTeamMember1 = (AccountTeamMember) TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = acc.Id, TeamMemberRole = 'Field Sales Rep')
        );
        AccountTeamMember accountTeamMember2 = (AccountTeamMember) TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = acc.Id, UserId = newUser.Id, TeamMemberRole = 'TAM')
        );

        Test.startTest();
        try {
            accountTeamMember1.TeamMemberRole = 'TAM';
            accountTeamMember2.TeamMemberRole = 'Field Sales Rep';

            List<AccountTeamMember> accountTeamMembersToUpdate = new List<AccountTeamMember>{
                    accountTeamMember1, accountTeamMember2
            };
            update accountTeamMembersToUpdate;

            List<AccountTeamMember> members = [SELECT Id FROM AccountTeamMember WHERE AccountId = :acc.Id];

            Assert.areEqual(2, members.size());
        } catch (Exception e) {
            System.debug(e.getMessage());
            Assert.isTrue(false, 'Expecting no error to be thrown');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testCopyInformationFromAccountTeamMemberToAccount_InsertDriverTeamMember() {
        User newUser = (User) TdfSObjectFactory.insertSObject(new User(FirstName = 'John', LastName = 'Stewart'));

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        Test.startTest();
        TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = dpAccount.Id, UserId = newUser.Id , TeamMemberRole = 'Driver')
        );
        Test.stopTest();

        Account updatedAccount = [
            SELECT Id, DriverName__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Assert.areEqual('John Stewart', updatedAccount.DriverName__c, 'Expecting to have same name as user');
    }

    @IsTest
    private static void testCopyInformationFromAccountTeamMemberToAccount_InsertFieldSalesRepTeamMember() {
        User newUser = (User) TdfSObjectFactory.insertSObject(new User(FirstName = 'John', LastName = 'Stewart'));

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        Test.startTest();
        TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = dpAccount.Id, UserId = newUser.Id , TeamMemberRole = 'Field Sales Rep')
        );
        Test.stopTest();

        Account updatedAccount = [
            SELECT Id, FieldSalesRepId__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Assert.areEqual(newUser.Id, updatedAccount.FieldSalesRepId__c, 'Expecting to have same name as user');
    }

    @IsTest
    private static void testCopyInformationFromAccountTeamMemberToAccount_UpdateToDriverTeamMember() {
        User newUser = (User) TdfSObjectFactory.insertSObject(new User(FirstName = 'John', LastName = 'Stewart'));

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        AccountTeamMember accountTeamMember = (AccountTeamMember) TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = dpAccount.Id, UserId = newUser.Id , TeamMemberRole = 'TAM')
        );

        Account accountBeforeRoleUpdate = [
            SELECT Id, DriverName__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Assert.isNull(accountBeforeRoleUpdate.DriverName__c);

        Test.startTest();
        accountTeamMember.TeamMemberRole = 'Driver';
        update accountTeamMember;
        Test.stopTest();

        Account accountAfterRoleUpdate = [
            SELECT Id, DriverName__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Assert.areEqual('John Stewart', accountAfterRoleUpdate.DriverName__c);
    }

    @IsTest
    private static void testCopyInformationFromAccountTeamMemberToAccount_UpdateToFieldSalesRepTeamMember() {
        User newUser = (User) TdfSObjectFactory.insertSObject(new User(FirstName = 'John', LastName = 'Stewart'));

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        AccountTeamMember accountTeamMember = (AccountTeamMember) TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = dpAccount.Id, UserId = newUser.Id , TeamMemberRole = 'TAM')
        );

        Account accountBeforeRoleUpdate = [
            SELECT Id, FieldSalesRepId__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Assert.isNull(accountBeforeRoleUpdate.FieldSalesRepId__c);

        Test.startTest();
        accountTeamMember.TeamMemberRole = 'Field Sales Rep';
        update accountTeamMember;
        Test.stopTest();

        Account accountAfterRoleUpdate = [
            SELECT Id, FieldSalesRepId__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Assert.areEqual(newUser.Id, accountAfterRoleUpdate.FieldSalesRepId__c);
    }

    @IsTest
    private static void testCopyInformationFromAccountTeamMemberToAccount_UpdateToNonDriverTeamMember() {
        User newUser = (User) TdfSObjectFactory.insertSObject(new User(FirstName = 'John', LastName = 'Stewart'));

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        AccountTeamMember accountTeamMember = (AccountTeamMember) TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = dpAccount.Id, UserId = newUser.Id , TeamMemberRole = 'Driver')
        );

        Account accountBeforeRoleUpdate = [
            SELECT Id, DriverName__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Assert.areEqual('John Stewart', accountBeforeRoleUpdate.DriverName__c);

        Test.startTest();
        accountTeamMember.TeamMemberRole = 'TAM';
        update accountTeamMember;
        Test.stopTest();

        Account accountAfterRoleUpdate = [
            SELECT Id, DriverName__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Assert.areEqual(null, accountAfterRoleUpdate.DriverName__c);
    }

    @IsTest
    private static void testCopyInformationFromAccountTeamMemberToAccount_UpdateToNonFieldSalesRepTeamMember() {
        User newUser = (User) TdfSObjectFactory.insertSObject(new User(FirstName = 'John', LastName = 'Stewart'));

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        AccountTeamMember accountTeamMember = (AccountTeamMember) TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = dpAccount.Id, UserId = newUser.Id , TeamMemberRole = 'Field Sales Rep')
        );

        Account accountBeforeRoleUpdate = [
            SELECT Id, FieldSalesRepId__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Assert.areEqual(newUser.Id, accountBeforeRoleUpdate.FieldSalesRepId__c);

        Test.startTest();
        accountTeamMember.TeamMemberRole = 'TAM';
        update accountTeamMember;
        Test.stopTest();

        Account accountAfterRoleUpdate = [
            SELECT Id, FieldSalesRepId__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Assert.areEqual(null, accountAfterRoleUpdate.FieldSalesRepId__c);
    }

    @IsTest
    private static void testCopyInformationFromAccountTeamMemberToAccount_DeleteDriverTeamMember() {
        User newUser = (User) TdfSObjectFactory.insertSObject(new User(FirstName = 'John', LastName = 'Stewart'));

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        AccountTeamMember accountTeamMember = (AccountTeamMember) TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = dpAccount.Id, UserId = newUser.Id , TeamMemberRole = 'Driver')
        );

        Account accountBeforeDelete = [
            SELECT Id, DriverName__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Assert.areEqual('John Stewart', accountBeforeDelete.DriverName__c);

        Test.startTest();
        delete accountTeamMember;
        Test.stopTest();

        Account accountAfterDelete = [
            SELECT Id, DriverName__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Assert.areEqual(null, accountAfterDelete.DriverName__c);
    }

    @IsTest
    private static void testCopyInformationFromAccountTeamMemberToAccount_DeleteFieldSalesTeamMember() {
        User newUser = (User) TdfSObjectFactory.insertSObject(new User(FirstName = 'John', LastName = 'Stewart'));

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        AccountTeamMember accountTeamMember = (AccountTeamMember) TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = dpAccount.Id, UserId = newUser.Id , TeamMemberRole = 'Field Sales Rep')
        );

        Account accountBeforeDelete = [
            SELECT Id, FieldSalesRepId__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Assert.areEqual(newUser.Id, accountBeforeDelete.FieldSalesRepId__c);

        Test.startTest();
        delete accountTeamMember;
        Test.stopTest();

        Account accountAfterDelete = [
            SELECT Id, FieldSalesRepId__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Assert.areEqual(null, accountAfterDelete.FieldSalesRepId__c);
    }
    
    @IsTest
    private static void testCopyInformationFromAccountTeamMemberToAccount_OnMultipleUpdates() {
        User user1 = (User) TdfSObjectFactory.insertSObject(new User(FirstName = 'John', LastName = 'Stewart'));
        User user2 = (User) TdfSObjectFactory.insertSObject(new User(FirstName = 'Fred', LastName = 'Davies'));

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );
        AccountTeamMember accountTeamMember1 = (AccountTeamMember) TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = dpAccount.Id, UserId = user1.Id , TeamMemberRole = 'TAM')
        );
        AccountTeamMember accountTeamMember2 = (AccountTeamMember) TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = dpAccount.Id, UserId = user2.Id , TeamMemberRole = 'TAM Manager')
        );

        Account accountBeforeUpdate = [
            SELECT Id, DriverName__c, FieldSalesRepId__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Assert.isNull(accountBeforeUpdate.DriverName__c);
        Assert.isNull(accountBeforeUpdate.FieldSalesRepId__c);

        Test.startTest();
        List<AccountTeamMember> atmList = new List<AccountTeamMember>();

        accountTeamMember1.TeamMemberRole = 'Field Sales Rep';
        accountTeamMember2.TeamMemberRole = 'Driver';

        atmList.add(accountTeamMember1);
        atmList.add(accountTeamMember2);

        update atmList;
        Test.stopTest();

        Account account = [
            SELECT Id, DriverName__c, FieldSalesRepId__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Assert.areEqual('Fred Davies', account.DriverName__c);
        Assert.areEqual(user1.Id, account.FieldSalesRepId__c);
    }
}