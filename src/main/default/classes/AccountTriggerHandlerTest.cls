/**
 * Created by magdalena.stanciu on 03.09.2022.
 */

@IsTest
private with sharing class AccountTriggerHandlerTest {
    @TestSetup
    private static void recalculatePermSetGroups() {
        PermissionSetGroup adminPermSetGroup = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'Administrator'][0];

        Test.calculatePermissionSetGroup(new Id[]{
            adminPermSetGroup.Id
        });
    }

    @IsTest
    private static void testPrimaryContactAutomation_InsertAccountWithPrimaryContact() {
        Account primaryContactParentAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );
        Contact primaryContact = (Contact) TdfSObjectFactory.insertSObject(
            new Contact(AccountId = primaryContactParentAccount.Id)
        );

        Test.startTest();
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Primary_Contact__c = primaryContact.Id)
        );
        Test.stopTest();

        Account updatedDPAccount = [SELECT Id, Phone, Email__c FROM Account WHERE Id = :dpAccount.Id];

        Assert.areEqual(primaryContact.Phone, updatedDPAccount.Phone, 'Expecting a different phone number.');
        Assert.areEqual(primaryContact.Email, updatedDPAccount.Email__c, 'Expecting a different email.');
    }

    @IsTest
    private static void testPrimaryContactAutomation_UpdateAccountPrimaryContact() {
        Account primaryContactParentAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );
        Contact primaryContact = (Contact) TdfSObjectFactory.insertSObject(
            new Contact(AccountId = primaryContactParentAccount.Id)
        );

        Account testDPAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                Phone = '+441234234234',
                Email__c = 'test@test.com'
            )
        );

        Test.startTest();
        testDPAccount.aforza__Primary_Contact__c = primaryContact.Id;
        update testDPAccount;
        Test.stopTest();

        Account updatedDPAccount = [SELECT Id, Phone, Email__c FROM Account WHERE Id = :testDPAccount.Id];

        Assert.areEqual(primaryContact.Phone, updatedDPAccount.Phone, 'Expecting a different phone number.');
        Assert.areEqual(primaryContact.Email, updatedDPAccount.Email__c, 'Expecting a different email.');
    }

    @IsTest
    private static void testPrimaryContactAutomation_RemovePrimaryContact() {
        Account primaryContactParentAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );
        Contact primaryContact = (Contact) TdfSObjectFactory.insertSObject(
            new Contact(AccountId = primaryContactParentAccount.Id)
        );

        Test.startTest();
        Account testDPAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Primary_Contact__c = primaryContact.Id)
        );

        testDPAccount.aforza__Primary_Contact__c = null;
        update testDPAccount;
        Test.stopTest();

        Account updatedDPAccount = [SELECT Id, Phone, Email__c FROM Account WHERE Id = :testDPAccount.Id];

        Assert.isNull(updatedDPAccount.Phone, 'Expecting a different phone number.');
        Assert.isNull(updatedDPAccount.Email__c, 'Expecting a different email.');
    }

    @IsTest
    private static void testPrimaryContactAutomation_PrimaryContactMissingContactDetails() {
        Account primaryContactParentAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );
        Contact primaryContact = (Contact) TdfSObjectFactory.insertSObject(
            new Contact(AccountId = primaryContactParentAccount.Id, Phone = null, Email = null)
        );

        Test.startTest();
        Account testDPAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Primary_Contact__c = primaryContact.Id)
        );
        Test.stopTest();

        Account updatedDPAccount = [SELECT Id, Phone, Email__c FROM Account WHERE Id = :testDPAccount.Id];

        Assert.isNull(updatedDPAccount.Phone, 'Expecting a different phone number.');
        Assert.isNull(updatedDPAccount.Email__c, 'Expecting a different email.');
    }

    @IsTest
    private static void testManageAccountTeamMembership_NonCoverageAccountMovedToActiveProspect() {
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
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

        Test.startTest();
        dpAccount.AccountStatus__c = 'Active Prospect';
        update dpAccount;
        Test.stopTest();

        List<AccountTeamMember> teamMembers = [
            SELECT Id
            FROM AccountTeamMember
            WHERE AccountId = :dpAccount.Id AND TeamMemberRole IN ('Field Sales Rep', 'Field Sales Managers')
        ];

        Assert.areEqual(1, teamMembers.size(), 'Expecting to have team members');
    }

    @IsTest
    private static void testManageAccountTeamMembership_NonCoverageAccountMovedToTraders() {
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
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

        Test.startTest();
        dpAccount.AccountStatus__c = 'Traders';
        update dpAccount;
        Test.stopTest();

        List<AccountTeamMember> teamMembers = [
            SELECT Id
            FROM AccountTeamMember
            WHERE AccountId = :dpAccount.Id AND TeamMemberRole IN ('Field Sales Rep', 'Field Sales Managers')
        ];

        Assert.areEqual(0, teamMembers.size(), 'Expecting to don\'t have team members');
    }

    @IsTest
    private static void testManageAccountTeamMembership_CoverageAccountMovedToActiveProspect() {
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
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

        Test.startTest();
        dpAccount.AccountStatus__c = 'Active Prospect';
        update dpAccount;
        Test.stopTest();

        List<AccountTeamMember> teamMembers = [
            SELECT Id
            FROM AccountTeamMember
            WHERE AccountId = :dpAccount.Id AND TeamMemberRole IN ('Field Sales Rep', 'Field Sales Managers')
        ];

        Assert.areEqual(1, teamMembers.size(), 'Expecting to have team members');
    }

    @IsTest
    private static void testManageAccountTeamMembership_CoverageAccountMovedToTraders() {
        TdfSObjectFactory.insertSObject(new aforza__Attribute__c(aforza__Code__c = 'New DP'));
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

        Test.startTest();
        dpAccount.AccountStatus__c = 'Traders';
        update dpAccount;
        Test.stopTest();

        List<AccountTeamMember> teamMembers = [
            SELECT Id
            FROM AccountTeamMember
            WHERE AccountId = :dpAccount.Id AND TeamMemberRole IN ('Field Sales Rep', 'Field Sales Managers')
        ];

        Assert.areEqual(1, teamMembers.size(), 'Expecting to have team members');
    }

    @IsTest
    private static void testManageReoccurrenceRecord_UpdateNewPrimaryStartDate() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Account createdAcc = [SELECT Id, DeliveryPointReference__c FROM Account WHERE Id = :acc.Id];
        TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id));
        TdfSObjectFactory.insertSObject(new aforza__Recurring_Record__c(Account__c = acc.Id, aforza__Last_Recurrence_Date__c = System.today(), Name = createdAcc.DeliveryPointReference__c + createdAcc.Id + '_Primary'));

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

        Assert.areEqual(newDate, record.StartDate__c);
    }

    @IsTest
    private static void testManageReoccurrenceRecord_UpdateNewPrimaryGrid() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Account createdAcc = [SELECT Id, DeliveryPointReference__c FROM Account WHERE Id = :acc.Id];
        TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id));
        TdfSObjectFactory.insertSObject(new aforza__Recurring_Record__c(Account__c = acc.Id, aforza__Last_Recurrence_Date__c = System.today(), Name = createdAcc.DeliveryPointReference__c + createdAcc.Id + '_Primary'));

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

        Assert.areEqual('3', record.CallDayOfWeek__c);
    }

    @IsTest
    private static void testManageReoccurrenceRecord_UpdateNoCreateCalls() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        TdfSObjectFactory.insertSObject(new aforza__Recurring_Record__c(Account__c = acc.Id, aforza__Last_Recurrence_Date__c = System.today(), Name = '100001_' + acc.Id + '_Primary'));

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

        Assert.areEqual(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_UpdateNoGrid() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        TdfSObjectFactory.insertSObject(new aforza__Recurring_Record__c(Account__c = acc.Id, aforza__Last_Recurrence_Date__c = System.today(), Name = '100001_' + acc.Id + '_Primary'));

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

        Assert.areEqual(0, record.size());
    }

    @IsTest
    private static void testManageReoccurrenceRecord_UpdateNoPrimaryStartDate() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        TdfSObjectFactory.insertSObject(new aforza__Recurring_Record__c(Account__c = acc.Id, aforza__Last_Recurrence_Date__c = System.today(), Name = '100001_' + acc.Id + '_Primary'));

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

        Assert.areEqual(0, record.size());
    }

    @IsTest
    private static void testGetDefaultPriceBooks() {
        TdfSObjectFactory.insertSObject(new Pricebook2(Name = 'Default England'));
        TdfSObjectFactory.insertSObject(new Pricebook2(Name = 'Default Scotland'));

        Test.startTest();
        Map<String, Id> priceBooks = AccountTriggerHandler.getDefaultPriceBooks();
        Test.stopTest();

        Assert.areEqual(2, priceBooks.size());
        Assert.isTrue(priceBooks.containsKey('England'));
        Assert.isTrue(priceBooks.containsKey('Scotland'));
    }

    @IsTest
    private static void testGetDefaultPriceBooks_funkyNames() {
        TdfSObjectFactory.insertSObject(new Pricebook2(Name = ' asd Default England asd'));
        TdfSObjectFactory.insertSObject(new Pricebook2(Name = 'lklk Default Scotlandlklk'));

        Test.startTest();
        Map<String, Id> priceBooks = AccountTriggerHandler.getDefaultPriceBooks();
        Test.stopTest();

        Assert.areEqual(2, priceBooks.size());
        Assert.isTrue(priceBooks.containsKey('England'));
        Assert.isTrue(priceBooks.containsKey('Scotland'));
    }
    @IsTest
    private static void testGetDefaultPriceBooks_NotReturning() {
        TdfSObjectFactory.insertSObject(new Pricebook2(Name = 'Default asd England'));
        TdfSObjectFactory.insertSObject(new Pricebook2(Name = 'efault Scotland'));

        Test.startTest();
        Map<String, Id> priceBooks = AccountTriggerHandler.getDefaultPriceBooks();
        Test.stopTest();

        Assert.areEqual(0, priceBooks.size());
    }

    @IsTest
    private static void testAssignDefaultPriceBook() {
        Pricebook2 priceBook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2(Name = 'Default England'));
        TdfSObjectFactory.insertSObject(new Pricebook2(Name = 'Default Scotland'));

        Test.startTest();
        TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID));
        Test.stopTest();

        Account acc = [SELECT Id, aforza__Default_Price_Book__c FROM Account LIMIT 1][0];

        Assert.areEqual(priceBook.Id, acc.aforza__Default_Price_Book__c);
    }

    @IsTest
    private static void testPullInfoOnDPFromRelatedCustomer_InsertDPRelatedToCustomer() {
        Account customerAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID, PORequired__c = true)
        );

        Test.startTest();
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, ParentId = customerAccount.Id, PORequired__c = false)
        );
        Test.stopTest();

        Account updatedDpAccount = [SELECT Id, PORequired__c FROM Account WHERE Id = :dpAccount.Id];

        Assert.isTrue(updatedDpAccount.PORequired__c);
    }

    @IsTest
    private static void testPullInfoOnDPFromRelatedCustomer_UpdateRelatedCustomerOnDP() {
        Account customerAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID, PORequired__c = true)
        );
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PORequired__c = false)
        );

        Test.startTest();
        dpAccount.ParentId = customerAccount.Id;
        update dpAccount;
        Test.stopTest();

        Account updatedDpAccount = [SELECT Id, PORequired__c FROM Account WHERE Id = :dpAccount.Id];

        Assert.isTrue(updatedDpAccount.PORequired__c);
    }

    @IsTest
    private static void testPushInfoFromCustomerToRelatedDPs_UpdatePoRequired() {
        Account customerAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID, PORequired__c = false)
        );
        List<Account> dpAccounts = (List<Account>) TdfSObjectFactory.insertSObjects(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, ParentId = customerAccount.Id, PORequired__c = false), 2
        );

        Test.startTest();
        customerAccount.PORequired__c = true;
        update customerAccount;
        Test.stopTest();

        List<Account> updatedDpAccounts = [SELECT Id, PORequired__c FROM Account WHERE Id = :dpAccounts];
        for (Account newAccount : updatedDpAccounts) {
            Assert.areEqual(true, newAccount.PORequired__c);
        }
    }

    @IsTest
    private static void testPushInfoFromCustomerToRelatedDPs_DefaultBillingAddressTrue() {
        Account customerAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID,
                BillingStateCode = 'AK',
                BillingStreet = 'Test Street',
                BillingCity = 'Test City',
                BillingCountryCode = 'US',
                BillingPostalCode = 'ABC DEF',
                aforza__Invoice_Email_Address__c = 'test@test.com',
                DefaultInvoiceBillingAddress__c = true
            )
        );
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                BillingStreet = null,
                BillingCity = null,
                BillingStateCode = null,
                BillingCountryCode = null,
                BillingPostalCode = null,
                aforza__Invoice_Email_Address__c = null
            )
        );

        Test.startTest();
        dpAccount.ParentId = customerAccount.Id;
        update dpAccount;
        Test.stopTest();

        Account updatedDpAccount = [
            SELECT
                    Id, BillingStreet, BillingCity, BillingCountryCode, BillingStateCode,
                    BillingPostalCode, aforza__Invoice_Email_Address__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Assert.areEqual(customerAccount.BillingStreet, updatedDpAccount.BillingStreet);
        Assert.areEqual(customerAccount.BillingCity, updatedDpAccount.BillingCity);
        Assert.areEqual(customerAccount.BillingCountryCode, updatedDpAccount.BillingCountryCode);
        Assert.areEqual(customerAccount.BillingStateCode, updatedDpAccount.BillingStateCode);
        Assert.areEqual(customerAccount.BillingPostalCode, updatedDpAccount.BillingPostalCode);
        Assert.areEqual(customerAccount.aforza__Invoice_Email_Address__c, updatedDpAccount.aforza__Invoice_Email_Address__c);
    }

    @IsTest
    private static void testPushInfoFromCustomerToRelatedDPs_DefaultBillingAddressFalse() {
        Account customerAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID,
                BillingStateCode = 'AK',
                BillingStreet = 'Test Street',
                BillingCity = 'Test City',
                BillingCountryCode = 'US',
                BillingPostalCode = 'ABC DEF',
                aforza__Invoice_Email_Address__c = 'test@test.com',
                DefaultInvoiceBillingAddress__c = false
            )
        );
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                BillingStreet = null,
                BillingCity = null,
                BillingStateCode = null,
                BillingCountryCode = null,
                BillingPostalCode = null,
                aforza__Invoice_Email_Address__c = null
            )
        );

        Test.startTest();
        dpAccount.ParentId = customerAccount.Id;
        update dpAccount;
        Test.stopTest();

        Account updatedDpAccount = [
            SELECT
                    Id, BillingStreet, BillingCity, BillingCountryCode, BillingStateCode,
                    BillingPostalCode, aforza__Invoice_Email_Address__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Assert.isNull(updatedDpAccount.BillingStreet);
        Assert.isNull(updatedDpAccount.BillingCity);
        Assert.isNull(updatedDpAccount.BillingCountryCode);
        Assert.isNull(updatedDpAccount.BillingStateCode);
        Assert.isNull(updatedDpAccount.BillingPostalCode);
        Assert.isNull(updatedDpAccount.aforza__Invoice_Email_Address__c);
    }

    @IsTest
    private static void testPushInfoFromCustomerToRelatedDPs_CreditStatus() {
        Account customerAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID, PORequired__c = false)
        );
        List<Account> dpAccounts = (List<Account>) TdfSObjectFactory.insertSObjects(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, ParentId = customerAccount.Id, PORequired__c = false), 2
        );

        Test.startTest();
        customerAccount.PORequired__c = true;
        update customerAccount;
        Test.stopTest();

        List<Account> updatedDpAccounts = [SELECT Id, PORequired__c FROM Account WHERE Id = :dpAccounts];
        for (Account newAccount : updatedDpAccounts) {
            Assert.isTrue(newAccount.PORequired__c);
        }
    }

    @IsTest
    private static void testPushInfoFromCustomerToRelatedDPs_DefaultBillingAddressOnDPs() {
        Account customerAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID,
                CreditStatus__c = null
            )
        );
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                ParentId = customerAccount.Id,
                CreditStatus__c = null
            )
        );

        Test.startTest();
        customerAccount.CreditStatus__c = 'Good';
        update customerAccount;
        Test.stopTest();

        Account updatedDpAccount = [SELECT Id, CreditStatus__c FROM Account WHERE Id = :dpAccount.Id];

        Assert.areEqual('Good', updatedDpAccount.CreditStatus__c);
    }

    @IsTest
    private static void testManageReoccurrenceRecord_NoRecurrenceRecord() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        Test.startTest();
        acc.PrimaryGridNumber__c = '3C7201WEW';
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
    private static void testManageFocusProducts() {
        // create NonStockis attribute category
        TdfSObjectFactory.insertSObject(new aforza__Attribute_Category__c());

        // create product with focus five
        TdfSObjectFactory.insertSObject(new Product2(FocusFiveProduct__c = true, FocusFiveGroup__c = 'GROUP'));

        Test.startTest();
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Test.stopTest();

        List<aforza__Outlet_Asset__c> assets = [SELECT Id, aforza__Product_Code__c FROM aforza__Outlet_Asset__c WHERE aforza__Account__c = :acc.Id];
        // given the fact that batches will be only run after stop test, and there is also batch to add new nonstocking product to accounts. At the time
        // batches run the account is here and thus the Asset is created twice
        Assert.areEqual(2, assets.size());
    }

    @IsTest
    private static void testPopulateDefaultInventory() {
        aforza__Inventory__c inventory = new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID, Name = 'Moston', InventoryCode__c = 'M');
        insert inventory;

        Test.startTest();
        Account acc = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PrimaryGridNumber__c = '2M203FRW')
        );
        Test.stopTest();

        Account account = [SELECT Id, Depot__c, DefaultInventory__c FROM Account WHERE Id = :acc.Id];

        Assert.areEqual('M', account.Depot__c);
        Assert.areEqual(inventory.Id, account.DefaultInventory__c);
    }

    @IsTest
    private static void testPopulateDefaultInventory_setToNull() {
        aforza__Inventory__c inventory = new aforza__Inventory__c(RecordTypeId = RecordTypes.INVENTORY_BUILDING_ID, Name = 'Moston', InventoryCode__c = 'M');
        insert inventory;

        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PrimaryGridNumber__c = '2M203FRW')
        );

        Test.startTest();
        acc.Depot__c = null;
        update acc;
        Test.stopTest();

        Account account = [SELECT Id, Depot__c, DefaultInventory__c FROM Account WHERE Id = :acc.Id];

        Assert.isNull(account.Depot__c);
        Assert.isNull(account.DefaultInventory__c);
    }

    @IsTest
    private static void testAddPerfectScoreProducts() {
        // create product with perfect Score
        TdfSObjectFactory.insertSObject(new Product2(PsProductEngland__c = true));

        Test.startTest();
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, PerfectStoreScoreEligible__c = true));
        Test.stopTest();

        List<aforza__Outlet_Asset__c> assets = [SELECT Id, aforza__Product_Code__c FROM aforza__Outlet_Asset__c WHERE aforza__Account__c = :acc.Id];
        // given the fact that batches will be only run after stop test, and there is also batch to add new perfect store product to account. At the time
        // batches run the account is here and thus the Asset is created twice
        Assert.areEqual(2, assets.size());
    }

    @IsTest
    private static void testAddPerfectScoreProducts_update() {
        // create product with perfect Score
        TdfSObjectFactory.insertSObject(new Product2(PsProductEngland__c = true));
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        Test.startTest();
        acc.PerfectStoreScoreEligible__c = true;
        update acc;
        Test.stopTest();

        List<aforza__Outlet_Asset__c> assets = [SELECT Id, aforza__Product_Code__c FROM aforza__Outlet_Asset__c WHERE aforza__Account__c = :acc.Id];
        // given the fact that batches will be only run after stop test, and there is also batch to add new perfect store product to account. At the time
        // batches run the account is here and thus the Asset is created twice
        Assert.areEqual(2, assets.size());
    }
    
    @IsTest
    private static void testCalculateAvailableCustomerCreditByAddRemoveNewDPAccounts() {

        Account customerAccount1 = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID,
                DefaultInvoiceBillingAddress__c = true,
                AvailableCustomerCredit__c = 0
            )
        );
        
        Account dpAccount1 = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Credit_Amount__c = 100 )
        );
        Account dpAccount2 = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Credit_Amount__c = 200)
        );
        Account dpAccount3 = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Credit_Amount__c = 300)
        );

        List<Account> accountsToUpdate = new List<Account>();

        dpAccount1.ParentId = customerAccount1.Id;
        accountsToUpdate.add(dpAccount1);
        update accountsToUpdate;
        Account cAccount = [SELECT AvailableCustomerCredit__c FROM Account WHERE RecordTypeId = :RecordTypes.ACCOUNT_CUSTOMER_ID LIMIT 1];
        Assert.areEqual(100, cAccount.AvailableCustomerCredit__c);

        Test.startTest();
        accountsToUpdate = new List<Account>();
        // Remove
        dpAccount1.ParentId = null;
        // Add
        dpAccount2.ParentId = customerAccount1.Id;
        dpAccount3.ParentId = customerAccount1.Id;
        accountsToUpdate.add(dpAccount1);
        accountsToUpdate.add(dpAccount2);
        accountsToUpdate.add(dpAccount3);
        update accountsToUpdate;
        Test.stopTest();

        cAccount = [SELECT AvailableCustomerCredit__c FROM Account WHERE RecordTypeId = :RecordTypes.ACCOUNT_CUSTOMER_ID LIMIT 1];
        Assert.areEqual(500, cAccount.AvailableCustomerCredit__c);
    }

    @IsTest
    private static void testCalculateAvailableCustomerCreditByChangeDPAccounts() {

        Account customerAccount1 = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID,
                DefaultInvoiceBillingAddress__c = true,
                AvailableCustomerCredit__c = 0
            )
        );
        Account customerAccount2 = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID,
                DefaultInvoiceBillingAddress__c = true,
                AvailableCustomerCredit__c = 0
            )
        );
        
        Account dpAccount1 = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Credit_Amount__c = 100 )
        );
        Account dpAccount2 = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Credit_Amount__c = 200)
        );
        Account dpAccount3 = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Credit_Amount__c = 300)
        );

        Map<Id, Account> accountMap = new Map<Id, Account>();
        List<Account> accountsToUpdate = new List<Account>();

        dpAccount1.ParentId = customerAccount1.Id;
        dpAccount2.ParentId = customerAccount1.Id;
        dpAccount3.ParentId = customerAccount2.Id;
        accountsToUpdate.add(dpAccount1);
        accountsToUpdate.add(dpAccount2);
        accountsToUpdate.add(dpAccount3);
        update accountsToUpdate;
        accountMap = new Map<Id, Account>([
            SELECT AvailableCustomerCredit__c FROM Account WHERE RecordTypeId = :RecordTypes.ACCOUNT_CUSTOMER_ID
        ]);
        Assert.areEqual(300, accountMap.get(customerAccount1.Id).AvailableCustomerCredit__c);
        Assert.areEqual(300, accountMap.get(customerAccount2.Id).AvailableCustomerCredit__c);

        Test.startTest();
        accountsToUpdate = new List<Account>();
        // Update/Change Parent (DP Account)
        dpAccount2.ParentId = customerAccount2.Id;
        accountsToUpdate.add(dpAccount2);
        update accountsToUpdate;
        Test.stopTest();

        accountMap = new Map<Id, Account>([
            SELECT AvailableCustomerCredit__c FROM Account WHERE RecordTypeId = :RecordTypes.ACCOUNT_CUSTOMER_ID
        ]);
        Assert.areEqual(100, accountMap.get(customerAccount1.Id).AvailableCustomerCredit__c);
        Assert.areEqual(500, accountMap.get(customerAccount2.Id).AvailableCustomerCredit__c);
    }

    @IsTest
    private static void testCalculateAvailableCustomerCreditByUpdatingInvoiceAmount() {

        Account customerAccount1 = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID,
                DefaultInvoiceBillingAddress__c = true,
                AvailableCustomerCredit__c = 0
            )
        );
        
        Account dpAccount1 = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Credit_Amount__c = 100 )
        );
        Account dpAccount2 = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Credit_Amount__c = 200)
        );
        Account dpAccount3 = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Credit_Amount__c = 300)
        );

        List<Account> accountsToUpdate = new List<Account>();

        dpAccount1.ParentId = customerAccount1.Id;
        dpAccount2.ParentId = customerAccount1.Id;
        dpAccount3.ParentId = customerAccount1.Id;
        accountsToUpdate.add(dpAccount1);
        accountsToUpdate.add(dpAccount2);
        accountsToUpdate.add(dpAccount3);
        update accountsToUpdate;
        Account cAccount = [SELECT AvailableCustomerCredit__c FROM Account WHERE RecordTypeId = :RecordTypes.ACCOUNT_CUSTOMER_ID LIMIT 1];
        Assert.areEqual(600, cAccount.AvailableCustomerCredit__c);

        Test.startTest();
        // Update Parent
        accountsToUpdate = new List<Account>();
        dpAccount2.aforza__Credit_Amount__c = 0;
        dpAccount3.aforza__Credit_Amount__c = -100;
        accountsToUpdate.add(dpAccount2);
        accountsToUpdate.add(dpAccount3);
        update accountsToUpdate;
        Test.stopTest();

        cAccount = [SELECT AvailableCustomerCredit__c FROM Account WHERE RecordTypeId = :RecordTypes.ACCOUNT_CUSTOMER_ID LIMIT 1];
        Assert.areEqual(0, cAccount.AvailableCustomerCredit__c);
    }

    @IsTest
    private static void testCalculateAvailableCustomerCreditByClosingDPAccount() {

        Account customerAccount1 = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID,
                DefaultInvoiceBillingAddress__c = true,
                AvailableCustomerCredit__c = 0
            )
        );
        
        Account dpAccount1 = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Credit_Amount__c = 100 )
        );
        Account dpAccount2 = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Credit_Amount__c = 200)
        );
        Account dpAccount3 = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, aforza__Credit_Amount__c = 300)
        );

        List<Account> accountsToUpdate = new List<Account>();

        dpAccount1.ParentId = customerAccount1.Id;
        dpAccount2.ParentId = customerAccount1.Id;
        dpAccount3.ParentId = customerAccount1.Id;
        accountsToUpdate.add(dpAccount1);
        accountsToUpdate.add(dpAccount2);
        accountsToUpdate.add(dpAccount3);
        update accountsToUpdate;
        Account cAccount = [SELECT AvailableCustomerCredit__c FROM Account WHERE RecordTypeId = :RecordTypes.ACCOUNT_CUSTOMER_ID LIMIT 1];
        Assert.areEqual(600, cAccount.AvailableCustomerCredit__c);

        Test.startTest();
        // Update Parent
        accountsToUpdate = new List<Account>();
        dpAccount2.AccountStatus__c = 'Closed';
        accountsToUpdate.add(dpAccount2);
        update accountsToUpdate;
        Test.stopTest();

        cAccount = [SELECT AvailableCustomerCredit__c FROM Account WHERE RecordTypeId = :RecordTypes.ACCOUNT_CUSTOMER_ID LIMIT 1];
        Assert.areEqual(400, cAccount.AvailableCustomerCredit__c);
    }

    @IsTest
    private static void testManageReoccurrenceRecord_CheckOwnerStaysAfterAccountUpdate() {
        User tamUser = (User) TdfSObjectFactory.insertSObject(new User());

        System.runAs([SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1][0]) {
            Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
            Account createdAcc = [SELECT Id, DeliveryPointReference__c FROM Account WHERE Id = :acc.Id];
            TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id, UserId = tamUser.Id));
            TdfSObjectFactory.insertSObject(new aforza__Recurring_Record__c(Account__c = acc.Id, aforza__Last_Recurrence_Date__c = System.today(),
                Name = createdAcc.DeliveryPointReference__c + createdAcc.Id + '_Primary', OwnerId = tamUser.Id));

            Test.startTest();
            acc.PrimaryGridNumber__c = '3C7201WEW'; //changing any tracked item on account
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

            Assert.areEqual(tamUser.Id, record.OwnerId);
        }
    }

    @IsTest
    private static void testCreateDefaultPaymentMethodForEnglandAndScotland() {

        Test.startTest();
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Test.stopTest();

        aforza__Payment_Method__c newPaymentMethod = [SELECT Id, aforza__Account__c, aforza__Active__c, aforza__Primary__c, RecordTypeId
                                                        FROM aforza__Payment_Method__c
                                                        WHERE aforza__Account__c = :acc.Id ];

        Assert.areEqual(acc.Id, newPaymentMethod.aforza__Account__c);
        Assert.areEqual(true, newPaymentMethod.aforza__Active__c);
        Assert.areEqual(true, newPaymentMethod.aforza__Primary__c);
        Assert.areEqual(RecordTypes.PAYMENT_METHOD_CASH_ID, newPaymentMethod.RecordTypeId);
    }
}
