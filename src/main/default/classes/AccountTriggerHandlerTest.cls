/**
 * Created by magdalena.stanciu on 03.09.2022.
 */

@IsTest
private with sharing class AccountTriggerHandlerTest {
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
    private static void testAssignDefault_Scotland() {
        TdfSObjectFactory.insertSObject(new Pricebook2(Name = 'Default England'));
        Pricebook2 priceBook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2(Name = 'Default Scotland'));

        Test.startTest();
        TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID, FieldSalesRegion__c = 'Scotland East')
        );
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
    private static void testCreateAforzaPaymentMethodForBottomLineDdMandate_onInsert() {
        
        Test.startTest();
        	Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                                                                                BottomlineRefNumber__c = 'testRef01',
                        							DirectDebitMandateRef__c = 'testRef01',
                       								DdActive__c = true));
        Test.stopTest();

        aforza__Payment_Method__c newPayment = [SELECT Id, aforza__Account__c, aforza__Active__c, aforza__Primary__c, RecordTypeId
                                                FROM aforza__Payment_Method__c WHERE aforza__Account__c =:acc.Id];
        
        Assert.areEqual(true, newPayment.aforza__Active__c);
        Assert.areEqual(true, newPayment.aforza__Primary__c);
        Assert.areEqual(acc.Id, newPayment.aforza__Account__c);
        Assert.areEqual(RecordTypes.PAYMENT_METHOD_DIRECT_CARD_ID, newPayment.RecordTypeId);
    }
    
    @IsTest
    private static void testCreateAforzaPaymentMethodForBottomLineDdMandate_onInsertNotFillingAnyNecessaryFields() {
        
        Test.startTest();
        	Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        Test.stopTest();

        List<aforza__Payment_Method__c> newPayments = [SELECT Id, aforza__Account__c, aforza__Active__c, aforza__Primary__c, RecordTypeId
                                                FROM aforza__Payment_Method__c WHERE aforza__Account__c =:acc.Id];
        Assert.areEqual(0, newPayments.size());
    }
    
    @IsTest
    private static void testCreateAforzaPaymentMethodForBottomLineDdMandate_onInsertNotFillingAllNecessaryFields() {
        
        Test.startTest();
        	Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                                                                                BottomlineRefNumber__c = 'testRef01',
                        							DirectDebitMandateRef__c = 'testRef01',
                       								DdActive__c = false));
        Test.stopTest();

        List<aforza__Payment_Method__c> newPayments = [SELECT Id, aforza__Account__c, aforza__Active__c, aforza__Primary__c, RecordTypeId
                                                FROM aforza__Payment_Method__c WHERE aforza__Account__c =:acc.Id];
        Assert.areEqual(0, newPayments.size());
    }
    
    @IsTest
    private static void testCreateAforzaPaymentMethodForBottomLineDdMandate_onUpdate() {
        
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                                                                        BottomlineRefNumber__c = 'testRef01',
                        						DirectDebitMandateRef__c = 'testRef01',
                       							DdActive__c = false));
        Test.startTest();
        	acc.DdActive__c = true;
        	update acc;
        Test.stopTest();

        aforza__Payment_Method__c newPayment = [SELECT Id, aforza__Account__c, aforza__Active__c, aforza__Primary__c, RecordTypeId
                                                FROM aforza__Payment_Method__c WHERE aforza__Account__c =:acc.Id];
        
        Assert.areEqual(true, newPayment.aforza__Active__c);
        Assert.areEqual(true, newPayment.aforza__Primary__c);
        Assert.areEqual(acc.Id, newPayment.aforza__Account__c);
        Assert.areEqual(RecordTypes.PAYMENT_METHOD_DIRECT_CARD_ID, newPayment.RecordTypeId);
    }
}