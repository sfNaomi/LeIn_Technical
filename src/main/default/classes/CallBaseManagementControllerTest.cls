/**
 * Created by svatopluk.sejkora on 27.09.2022.
 */

@IsTest
private class CallBaseManagementControllerTest {

    @TestSetup
    private static void recalculatePermSetGroups() {
        PermissionSetGroup adminPermSetGroup = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'Administrator'][0];

        Test.calculatePermissionSetGroup(new Id[]{
                adminPermSetGroup.Id
        });
    }

    @IsTest
    private static void fetchTamUsers() {
        // create user
        List<UserRole> role = [SELECT Id FROM UserRole WHERE DeveloperName = 'TAM'];
        System.assertEquals(1, role.size());

        TdfSObjectFactory.insertSObject(new User(UserRoleId = role[0].Id));

        Test.startTest();
        List<User> users = CallBaseManagementController.fetchTamUsers();
        Test.stopTest();

        System.assert(users.size() > 0);
    }

    @IsTest
    private static void testChangeOwnerOfVisits() {
        // create user
        List<UserRole> role = [SELECT Id FROM UserRole WHERE DeveloperName = 'TAM'];
        System.assertEquals(1, role.size());

        User user = (User) TdfSObjectFactory.insertSObject(new User(UserRoleId = role[0].Id));

        // assign proper permission set to user
        PermissionSetGroup adminPermSetGroup = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'Administrator'][0];
        insert new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetGroupId = adminPermSetGroup.Id);


        System.runAs(user) {
            // get some visits
            Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
            TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id));

            List<aforza__Recurring_Record__c> recurringRecords = [SELECT Id FROM aforza__Recurring_Record__c WHERE Account__c = :acc.Id LIMIT 1];
            System.assert(recurringRecords.size() == 1);

            TdfSObjectFactory.insertSObjects(new aforza__Visit__c(aforza__Account__c = acc.Id, aforza__Recurring_Record__c = recurringRecords[0].Id,
                    RecordTypeId = RecordTypes.VISIT_REMOTE_VISIT_ID), 5);
        }

        List<aforza__Visit__c> createdVisits = [SELECT Id, aforza__Owner__c FROM aforza__Visit__c LIMIT 5];

        System.assertEquals(5, createdVisits.size());
        for (aforza__Visit__c visit : createdVisits) {
            System.assertEquals(user.Id, visit.aforza__Owner__c);
        }

        Test.startTest();
        System.runAs([SELECT Id FROM User WHERE Id = :UserInfo.getUserId()][0]) {
            CallBaseManagementController.changeOwnerOfVisits(new List<String>{
                    createdVisits[0].Id, createdVisits[1].Id
            }, UserInfo.getUserId());
        }
        Test.stopTest();

        List<aforza__Visit__c> updatedVisits = [
                SELECT Id, aforza__Owner__c
                FROM aforza__Visit__c
                WHERE Id IN :new Set<Id>{
                        createdVisits[0].Id, createdVisits[1].Id
                }
        ];

        System.assertEquals(2, updatedVisits.size());
        System.assertEquals(UserInfo.getUserId(), updatedVisits[0].aforza__Owner__c);
        System.assertEquals(UserInfo.getUserId(), updatedVisits[1].aforza__Owner__c);

        List<aforza__Visit__c> notUpdatedVisits = [
                SELECT Id, aforza__Owner__c
                FROM aforza__Visit__c
                WHERE Id IN :new Set<Id>{
                        createdVisits[2].Id, createdVisits[3].Id, createdVisits[4].Id
                }
        ];
        System.assertEquals(3, notUpdatedVisits.size());
        System.assertEquals(user.Id, notUpdatedVisits[0].aforza__Owner__c);
        System.assertEquals(user.Id, notUpdatedVisits[1].aforza__Owner__c);
        System.assertEquals(user.Id, notUpdatedVisits[2].aforza__Owner__c);
    }

    @IsTest
    private static void testChangeOwnerOfVisits_VisitsEmpty() {
        Test.startTest();
        try {
            CallBaseManagementController.changeOwnerOfVisits(new List<String>{
            }, UserInfo.getUserId());
            System.assert(false);
        } catch (Exception e) {
            System.assertEquals('System.AuraHandledException', e.getTypeName());
            System.assertEquals('At least one visit has to be provided', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    private static void testChangeOwnerOfVisits_userEmpty() {
        // get some visits
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        TdfSObjectFactory.insertSObject(new AccountTeamMember(AccountId = acc.Id));

        List<aforza__Recurring_Record__c> recurringRecords = [SELECT Id FROM aforza__Recurring_Record__c WHERE Account__c = :acc.Id LIMIT 1];
        System.assert(recurringRecords.size() == 1);

        List<aforza__Visit__c> visits = (List<aforza__Visit__c>) TdfSObjectFactory.insertSObjects(new aforza__Visit__c(aforza__Account__c = acc.Id, aforza__Recurring_Record__c = recurringRecords[0].Id,
                RecordTypeId = RecordTypes.VISIT_REMOTE_VISIT_ID), 2);
        Test.startTest();

        try {
            CallBaseManagementController.changeOwnerOfVisits(new List<String>{visits[0].Id, visits[1].Id
            }, '');
            System.assert(false);
        } catch (Exception e) {
            System.assertEquals('System.AuraHandledException', e.getTypeName());
            System.assert(e.getMessage().contains('A new owner Id is required please pass in valid Id :'));
        }
        Test.stopTest();
    }
}