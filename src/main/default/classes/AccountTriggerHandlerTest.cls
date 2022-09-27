/**
 * Created by magdalena.stanciu on 03.09.2022.
 */

@IsTest
private with sharing class AccountTriggerHandlerTest {
    @IsTest
    private static void testPrimaryContactAutomation_InsertAccountWithPrimaryContact() {
        // create new contact to be set as primary
        Account primaryContactParentAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );
        Contact primaryContact = (Contact) TdfSObjectFactory.insertSObject(
            new Contact(AccountId = primaryContactParentAccount.Id)
        );

        // create new DP account and set primary contact
        Test.startTest();
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Primary_Contact__c = primaryContact.Id)
        );
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [SELECT Id, Phone, Email__c FROM Account WHERE Id = :dpAccount.Id];

        // check results
        System.assertEquals(primaryContact.Phone, updatedDPAccount.Phone, 'Expecting a different phone number.');
        System.assertEquals(primaryContact.Email, updatedDPAccount.Email__c, 'Expecting a different email.');
    }

    @IsTest
    private static void testPrimaryContactAutomation_UpdateAccountPrimaryContact() {
        // create new contact to be set as primary
        Account primaryContactParentAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );
        Contact primaryContact = (Contact) TdfSObjectFactory.insertSObject(
            new Contact(AccountId = primaryContactParentAccount.Id)
        );

        // create new DP account
        Account testDPAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                Phone = '+404234234234',
                Email__c = 'test@test.com'
            )
        );

        // update the primary contact of the DP account
        Test.startTest();
        testDPAccount.aforza__Primary_Contact__c = primaryContact.Id;
        update testDPAccount;
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [SELECT Id, Phone, Email__c FROM Account WHERE Id = :testDPAccount.Id];

        // check results
        System.assertEquals(primaryContact.Phone, updatedDPAccount.Phone, 'Expecting a different phone number.');
        System.assertEquals(primaryContact.Email, updatedDPAccount.Email__c, 'Expecting a different email.');
    }

    @IsTest
    private static void testPrimaryContactAutomation_RemovePrimaryContact() {
        // create new contact to be set as primary
        Account primaryContactParentAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );
        Contact primaryContact = (Contact) TdfSObjectFactory.insertSObject(
            new Contact(AccountId = primaryContactParentAccount.Id)
        );

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
        Account updatedDPAccount = [SELECT Id, Phone, Email__c FROM Account WHERE Id = :testDPAccount.Id];

        // check results
        System.assertEquals(null, updatedDPAccount.Phone, 'Expecting a different phone number.');
        System.assertEquals(null, updatedDPAccount.Email__c, 'Expecting a different email.');
    }

    @IsTest
    private static void testPrimaryContactAutomation_PrimaryContactMissingContactDetails() {
        // create new contact to be set as primary
        Account primaryContactParentAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );
        Contact primaryContact = (Contact) TdfSObjectFactory.insertSObject(
            new Contact(AccountId = primaryContactParentAccount.Id, Phone = null, Email = null)
        );

        // create new DP account and set primary contact
        Test.startTest();
        Account testDPAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Primary_Contact__c = primaryContact.Id)
        );
        Test.stopTest();

        // retrieve updated account
        Account updatedDPAccount = [SELECT Id, Phone, Email__c FROM Account WHERE Id = :testDPAccount.Id];

        // check results
        System.assertEquals(null, updatedDPAccount.Phone, 'Expecting a different phone number.');
        System.assertEquals(null, updatedDPAccount.Email__c, 'Expecting a different email.');
    }

    @IsTest
    private static void testManageAccountTeamMembership_NonCoverageAccountMovedToActiveProspect() {
        // create dp account and add team member
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                IsCoverage__c = false,
                AccountStatus__c = 'Prospect'
            )
        );
        TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = dpAccount.Id, TeamMemberRole = 'Field Sales Rep')
        );

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
    private static void testManageAccountTeamMembership_NonCoverageAccountMovedToTraders() {
        // create dp account and add team member
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                IsCoverage__c = false,
                AccountStatus__c = 'Active Prospect'
            )
        );
        TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = dpAccount.Id, TeamMemberRole = 'Field Sales Rep')
        );

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
    private static void testManageAccountTeamMembership_CoverageAccountMovedToActiveProspect() {
        // create dp account and add team member
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                IsCoverage__c = true,
                AccountStatus__c = 'Prospect'
            )
        );
        TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = dpAccount.Id, TeamMemberRole = 'Field Sales Rep')
        );

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
    private static void testManageAccountTeamMembership_CoverageAccountMovedToTraders() {
        // create dp account and add team member
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                IsCoverage__c = true,
                AccountStatus__c = 'Active Prospect'
            )
        );
        TdfSObjectFactory.insertSObject(
            new AccountTeamMember(AccountId = dpAccount.Id, TeamMemberRole = 'Field Sales Rep')
        );

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
        Test.startTest();
        TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, CreateCalls__c = false)
        );
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
        Test.startTest();
        TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Legal')
        );
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
        Test.startTest();
        TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID));
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
        Test.startTest();
        TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PrimaryGridNumber__c = null)
        );
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
        Test.startTest();
        TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PrimaryStartDate__c = null)
        );
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
    private static void testManageReoccurrenceRecord_UpdateNewPrimaryStartDate() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );
        Date newDate = Date.parse('21/09/2022');

        Test.startTest();
        acc.PrimaryStartDate__c = newDate;
        update acc;
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

        System.assertEquals(newDate, record.StartDate__c);
    }

    @IsTest
    private static void testManageReoccurrenceRecord_UpdateNewPrimaryGrid() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );

        Test.startTest();
        acc.PrimaryGridNumber__c = '3C7201WEW'; //changing Call Day of Week (3)
        update acc;
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

        System.assertEquals('3', record.CallDayOfWeek__c);
    }

    @IsTest
    private static void testManageReoccurrenceRecord_UpdateNoCreateCalls() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );

        List<aforza__Recurring_Record__c> checkItExists = [
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
        System.assertEquals(1, checkItExists.size());

        Test.startTest();
        acc.CreateCalls__c = false;
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
    private static void testManageReoccurrenceRecord_OutStatus() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );

        List<aforza__Recurring_Record__c> checkItExists = [
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
        System.assertEquals(1, checkItExists.size());

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
    private static void testManageReoccurrenceRecord_UpdateNoGrid() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );

        List<aforza__Recurring_Record__c> checkItExists = [
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
        System.assertEquals(1, checkItExists.size());

        Test.startTest();
        acc.PrimaryGridNumber__c = '';
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
    private static void testManageReoccurrenceRecord_UpdateNoPrimaryStartDate() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );

        List<aforza__Recurring_Record__c> checkItExists = [
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
        System.assertEquals(1, checkItExists.size());

        Test.startTest();
        acc.PrimaryStartDate__c = null;
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
    private static void testGetDefaultPriceBooks() {
        // create price books
        TdfSObjectFactory.insertSObject(new Pricebook2(Name = 'Default England'));
        TdfSObjectFactory.insertSObject(new Pricebook2(Name = 'Default Scotland'));

        Test.startTest();
        Map<String, Id> priceBooks = AccountTriggerHandler.getDefaultPriceBooks();
        Test.stopTest();

        System.debug(priceBooks);

        System.assertEquals(2, priceBooks.size());
        System.assert(priceBooks.containsKey('England'));
        System.assert(priceBooks.containsKey('Scotland'));
    }

    @IsTest
    private static void testGetDefaultPriceBooks_funkyNames() {
        // create price books
        TdfSObjectFactory.insertSObject(new Pricebook2(Name = ' asd Default England asd'));
        TdfSObjectFactory.insertSObject(new Pricebook2(Name = 'lklk Default Scotlandlklk'));

        Test.startTest();
        Map<String, Id> priceBooks = AccountTriggerHandler.getDefaultPriceBooks();
        Test.stopTest();

        System.debug(priceBooks);

        System.assertEquals(2, priceBooks.size());
        System.assert(priceBooks.containsKey('England'));
        System.assert(priceBooks.containsKey('Scotland'));
    }
    @IsTest
    private static void testGetDefaultPriceBooks_NotReturning() {
        // create price books
        TdfSObjectFactory.insertSObject(new Pricebook2(Name = 'Default asd England'));
        TdfSObjectFactory.insertSObject(new Pricebook2(Name = 'efault Scotland'));

        Test.startTest();
        Map<String, Id> priceBooks = AccountTriggerHandler.getDefaultPriceBooks();
        Test.stopTest();

        System.debug(priceBooks);

        System.assertEquals(0, priceBooks.size());
    }

    @IsTest
    private static void testAssignDefaultPriceBook() {
        // create price books
        Pricebook2 priceBook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2(Name = 'Default England'));
        TdfSObjectFactory.insertSObject(new Pricebook2(Name = 'Default Scotland'));

        Test.startTest();
        TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID));
        Test.stopTest();

        Account acc = [SELECT Id, aforza__Default_Price_Book__c FROM Account LIMIT 1][0];

        System.assertEquals(priceBook.Id, acc.aforza__Default_Price_Book__c);
    }

    @IsTest
    private static void testAssignDefault_Scotland() {
        // create price books
        TdfSObjectFactory.insertSObject(new Pricebook2(Name = 'Default England'));
        Pricebook2 priceBook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2(Name = 'Default Scotland'));

        Test.startTest();
        TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID, FieldSalesRegion__c = 'Scotland East')
        );
        Test.stopTest();

        Account acc = [SELECT Id, aforza__Default_Price_Book__c FROM Account LIMIT 1][0];

        System.assertEquals(priceBook.Id, acc.aforza__Default_Price_Book__c);
    }

    @IsTest
    private static void testUpdatePORequiredStartingWithCustomerAccs_UpdateTrue() {
        Account customerAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID)
        );
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, ParentId = customerAccount.Id)
        );
        Test.startTest();
        customerAccount.PORequired__c = true;
        update customerAccount;
        Test.stopTest();

        Account updatedDpAccount = [SELECT Id, PORequired__c FROM Account WHERE Id = :dpAccount.Id];
        System.assertEquals(true, updatedDpAccount.PORequired__c);
    }
    @IsTest
    private static void testUpdatePORequiredStartingWithCustomerAccs_UpdateFalse() {
        Account customerAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID, PORequired__c = true)
        );
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, ParentId = customerAccount.Id)
        );
        Test.startTest();
        customerAccount.PORequired__c = false;
        update customerAccount;
        Test.stopTest();

        Account updatedDpAccount = [SELECT Id, PORequired__c FROM Account WHERE Id = :dpAccount.Id];
        System.assertEquals(false, updatedDpAccount.PORequired__c);
    }

    @IsTest
    private static void testUpdatePORequiredStartingWithDPs_InsertMultiples() {
        Account customerAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID, PORequired__c = true)
        );

        Test.startTest();
        List<Account> dpAccounts = (List<Account>) TdfSObjectFactory.insertSObjects(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, ParentId = customerAccount.Id),
            10
        );
        Test.stopTest();
        List<Account> updatedDpAccounts = [
            SELECT Id, PORequired__c
            FROM Account
            WHERE PORequired__c = TRUE AND RecordTypeId = :RecordTypes.ACCOUNT_OUTLET_ID
        ];
        System.assertEquals(10, updatedDpAccounts.size());
    }

    @IsTest
    private static void testUpdatePORequiredStartingWithDPs_Update() {
        Account customerAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID, PORequired__c = true)
        );
        List<Account> dpAccounts = (List<Account>) TdfSObjectFactory.insertSObjects(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID),
            10
        );
        Test.startTest();
        for (Account acc : dpAccounts) {
            acc.ParentId = customerAccount.Id;
        }
        update dpAccounts;
        Test.stopTest();
        List<Account> updatedDpAccounts = [
            SELECT Id, PORequired__c
            FROM Account
            WHERE PORequired__c = TRUE AND RecordTypeId = :RecordTypes.ACCOUNT_OUTLET_ID
        ];
        System.assertEquals(10, updatedDpAccounts.size());
    }
}
