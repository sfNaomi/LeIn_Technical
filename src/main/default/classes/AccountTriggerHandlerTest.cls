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
    private static void testPrimaryContactAutomationPrimaryContactMisingContactDetails() {
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
}