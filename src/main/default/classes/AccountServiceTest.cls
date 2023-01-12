@IsTest
public class AccountServiceTest {	
    @IsTest
    private static void testDdMandateCreationHandlerStageOver6() {
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );
    
        Account accRef1 = [SELECT Id, DeliveryPointReference__c, DdActive__c, DirectDebitMandateRef__c FROM Account WHERE Id =:dpAccount.id];
        
        System.assertEquals(FALSE, accRef1.DdActive__c);
		
        String deliveryRef = accRef1.DeliveryPointReference__c;
        DdMandateCreationController.ddMandateCreationHandler(deliveryRef, '9');
        
        aforza__Payment_Method__c newPayment = [SELECT Id, aforza__Account__c, aforza__Active__c, aforza__Primary__c, RecordTypeId
                                                FROM aforza__Payment_Method__c WHERE aforza__Account__c =:dpAccount.Id AND RecordTypeId =: RecordTypes.PAYMENT_METHOD_DIRECT_CARD_ID];
        Account accRef2 = [SELECT Id, DeliveryPointReference__c, DdActive__c, DirectDebitMandateRef__c FROM Account WHERE Id =:dpAccount.id];

        Assert.areEqual(true, newPayment.aforza__Active__c);
        Assert.areEqual(true, newPayment.aforza__Primary__c);
        Assert.areEqual(accRef2.Id, newPayment.aforza__Account__c);
        Assert.areEqual(RecordTypes.PAYMENT_METHOD_DIRECT_CARD_ID, newPayment.RecordTypeId);

        System.assertEquals(TRUE, accRef2.DdActive__c);
        System.assertEquals(deliveryRef, accRef2.DirectDebitMandateRef__c);
    }
	
    @IsTest
    private static void testDdMandateCreationHandlerStage6OrBelow() {
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );

        Account accRef1 = [SELECT Id, DeliveryPointReference__c, DdActive__c, DirectDebitMandateRef__c FROM Account WHERE Id =:dpAccount.id];
        
        System.assertEquals(FALSE, accRef1.DdActive__c);
		
        String deliveryRef = accRef1.DeliveryPointReference__c;
        DdMandateCreationController.ddMandateCreationHandler(deliveryRef, '4');
        Account accRef2 = [SELECT Id, DeliveryPointReference__c, DdActive__c, DirectDebitMandateRef__c FROM Account WHERE Id =:dpAccount.id];

        System.assertEquals(FALSE, accRef2.DdActive__c, 'DD Active should be false');
        System.assertNotEquals(deliveryRef, accRef2.DirectDebitMandateRef__c);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_WeeklyFrequencyMondayForDeliveryDate() {
        Date today = Date.newInstance(2023, 1, 4);
        Date startDate = Date.newInstance(2023, 1, 2);
        Date expectedDeliveryDate = Date.newInstance(2023, 1, 9);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '1C7201MOW', PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_WeeklyFrequencyTuesdayForDeliveryDate() {
        Date today = Date.newInstance(2023, 1, 4);
        Date startDate = Date.newInstance(2023, 1, 2);
        Date expectedDeliveryDate = Date.newInstance(2023, 1, 10);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '2C7201MOW', PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_WeeklyFrequencyWednesdayForDeliveryDate() {
        Date today = Date.newInstance(2023, 1, 4);
        Date startDate = Date.newInstance(2023, 1, 2);
        Date expectedDeliveryDate = Date.newInstance(2023, 1, 4);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MOW', PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_WeeklyFrequencyThursdayForDeliveryDate() {
        Date today = Date.newInstance(2023, 1, 4);
        Date startDate = Date.newInstance(2023, 1, 2);
        Date expectedDeliveryDate = Date.newInstance(2023, 1, 5);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '4C7201MOW', PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_WeeklyFrequencyFridayForDeliveryDate() {
        Date today = Date.newInstance(2023, 1, 4);
        Date startDate = Date.newInstance(2023, 1, 2);
        Date expectedDeliveryDate = Date.newInstance(2023, 1, 6);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '5C7201MOW', PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_BiWeeklyFrequencyMondayForCurrentWeekDay() {
        Date today = Date.newInstance(2023, 1, 16);
        Date startDate = Date.newInstance(2023, 1, 2);
        Date expectedDeliveryDate = Date.newInstance(2023, 1, 18);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MOW', SecondaryGridNumber__c = '5C7201WEW',
                PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_BiWeeklyFrequencyTuesdayForCurrentWeekDay() {
        Date today = Date.newInstance(2023, 1, 17);
        Date startDate = Date.newInstance(2023, 1, 2);
        Date expectedDeliveryDate = Date.newInstance(2023, 1, 18);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MOW', SecondaryGridNumber__c = '5C7201WEW',
                PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_BiWeeklyFrequencyWednesdayForCurrentWeekDay() {
        Date today = Date.newInstance(2023, 1, 18);
        Date startDate = Date.newInstance(2023, 1, 2);
        Date expectedDeliveryDate = Date.newInstance(2023, 1, 18);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MOW', SecondaryGridNumber__c = '5C7201WEW',
                PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_BiWeeklyFrequencyThursdayForCurrentWeekDay() {
        Date today = Date.newInstance(2023, 1, 19);
        Date startDate = Date.newInstance(2023, 1, 2);
        Date expectedDeliveryDate = Date.newInstance(2023, 1, 20);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MOW', SecondaryGridNumber__c = '5C7201WEW',
                PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_BiWeeklyFrequencyFridayForCurrentWeekDay() {
        Date today = Date.newInstance(2023, 1, 20);
        Date startDate = Date.newInstance(2023, 1, 2);
        Date expectedDeliveryDate = Date.newInstance(2023, 1, 20);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MOW', SecondaryGridNumber__c = '5C7201WEW',
                PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_FortnightlyFrequencyEvenWeekMondayForCurrentWeekDay() {
        Date today = Date.newInstance(2023, 1, 9);
        Date startDate = Date.newInstance(2023, 1, 2);
        Date expectedDeliveryDate = Date.newInstance(2023, 1, 18);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MO1', PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_FortnightlyFrequencyEvenWeekTuesdayForCurrentWeekDay() {
        Date today = Date.newInstance(2023, 1, 10);
        Date startDate = Date.newInstance(2023, 1, 2);
        Date expectedDeliveryDate = Date.newInstance(2023, 1, 18);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MO1', PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_FortnightlyFrequencyEvenWeekWednesdayForCurrentWeekDay() {
        Date today = Date.newInstance(2023, 1, 11);
        Date startDate = Date.newInstance(2023, 1, 2);
        Date expectedDeliveryDate = Date.newInstance(2023, 1, 18);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MO1', PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_FortnightlyFrequencyEvenWeekThursdayForCurrentWeekDay() {
        Date today = Date.newInstance(2023, 1, 12);
        Date startDate = Date.newInstance(2023, 1, 2);
        Date expectedDeliveryDate = Date.newInstance(2023, 1, 18);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MO1', PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_FortnightlyFrequencyEvenWeekFridayForCurrentWeekDay() {
        Date today = Date.newInstance(2023, 1, 13);
        Date startDate = Date.newInstance(2023, 1, 2);
        Date expectedDeliveryDate = Date.newInstance(2023, 1, 18);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MO1', PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_FortnightlyFrequencyOddWeekMondayForCurrentWeekDay() {
        Date today = Date.newInstance(2023, 1, 16);
        Date startDate = Date.newInstance(2023, 1, 2);
        Date expectedDeliveryDate = Date.newInstance(2023, 1, 18);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MO1', PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_FortnightlyFrequencyOddWeekTuesdayForCurrentWeekDay() {
        Date today = Date.newInstance(2023, 1, 17);
        Date startDate = Date.newInstance(2023, 1, 2);
        Date expectedDeliveryDate = Date.newInstance(2023, 1, 18);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MO1', PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_FortnightlyFrequencyOddWeekWednesdayForCurrentWeekDay() {
        Date today = Date.newInstance(2023, 1, 18);
        Date startDate = Date.newInstance(2023, 1, 2);
        Date expectedDeliveryDate = Date.newInstance(2023, 1, 18);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MO1', PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_FortnightlyFrequencyOddWeekThursdayForCurrentWeekDay() {
        Date today = Date.newInstance(2023, 1, 19);
        Date startDate = Date.newInstance(2023, 1, 2);
        Date expectedDeliveryDate = Date.newInstance(2023, 2, 1);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MO1', PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_FortnightlyFrequencyOddWeekFridayForCurrentWeekDay() {
        Date today = Date.newInstance(2023, 1, 20);
        Date startDate = Date.newInstance(2023, 1, 2);
        Date expectedDeliveryDate = Date.newInstance(2023, 2, 1);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MO1', PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_MonthlyFrequencyCurrentWeekDayInWeek1() {
        Date today = Date.newInstance(2023, 1, 2);
        Date startDate = Date.newInstance(2023, 1, 4);
        Date expectedDeliveryDate = Date.newInstance(2023, 1, 4);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MOM', PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_MonthlyFrequencyCurrentWeekDayInWeek2() {
        Date today = Date.newInstance(2023, 1, 10);
        Date startDate = Date.newInstance(2023, 1, 4);
        Date expectedDeliveryDate = Date.newInstance(2023, 2, 1);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MOM', PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_MonthlyFrequencyCurrentWeekDayInWeek3() {
        Date today = Date.newInstance(2023, 1, 18);
        Date startDate = Date.newInstance(2023, 1, 4);
        Date expectedDeliveryDate = Date.newInstance(2023, 2, 1);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MOM', PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_MonthlyFrequencyCurrentWeekDayInWeek4() {
        Date today = Date.newInstance(2023, 1, 26);
        Date startDate = Date.newInstance(2023, 1, 4);
        Date expectedDeliveryDate = Date.newInstance(2023, 2, 1);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MOM', PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_MonthlyFrequencyRepeatCycle() {
        Date today = Date.newInstance(2023, 2, 3);
        Date startDate = Date.newInstance(2023, 1, 4);
        Date expectedDeliveryDate = Date.newInstance(2023, 3, 1);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MOM', PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_MonthlyFrequencyFutureStartDate() {
        Date today = Date.newInstance(2023, 1, 2);
        Date startDate = Date.newInstance(2023, 1, 23);
        Date expectedDeliveryDate = Date.newInstance(2023, 1, 25);

        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MOM', PrimaryStartDate__c = startDate)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        AccountService.today = today;
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.areEqual(expectedDeliveryDate, computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_NoGridInformation() {
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders', PrimaryGridNumber__c = null)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.isNull(computedDeliveryDate);
    }

    @IsTest
    private static void testComputeNextDeliveryDate_MonthlyFrequencyNoPrimaryStartDate() {
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders',
                PrimaryGridNumber__c = '3C7201MOM', PrimaryStartDate__c = null)
        );

        Account insertedAccount = [
            SELECT
                Id, PrimaryGridNumber__c, SecondaryGridNumber__c, Frequency__c, PrimaryDeliveryDay__c,
                SecondaryDeliveryDay__c, PrimaryStartDate__c, SecondaryStartDate__c
            FROM Account
            WHERE Id = :dpAccount.Id
        ];

        Test.startTest();
        Date computedDeliveryDate = AccountService.computeNextDeliveryDate(insertedAccount);
        Test.stopTest();

        Assert.isNull(computedDeliveryDate);
    }
}
