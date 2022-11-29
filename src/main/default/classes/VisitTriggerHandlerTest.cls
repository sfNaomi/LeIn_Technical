/**
 * Created by magdalena.stanciu on 28.11.2022.
 */

@IsTest
private class VisitTriggerHandlerTest {
    @IsTest
    static void testVisitInsert_ExistingCompletedVisitsWithNotes() {
        Account newAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        aforza__Visit__c existingVisit = (aforza__Visit__c) TdfSObjectFactory.insertSObject(
            new aforza__Visit__c(RecordTypeId = RecordTypes.VISIT_DIRECT_VISIT_ID, aforza__Account__c = newAccount.Id,
                aforza__Type__c = 'Outlet Visit', aforza__Status__c = 'Completed'));

        List<ContentVersion> newDocs = (List<ContentVersion>) TdfSObjectFactory.insertSObjects(
            new ContentVersion(PathOnClient = 'Test.sNote'), 5);

        List<ContentVersion> insertedDocs = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :newDocs];

        for (Integer index = 0; index < insertedDocs.size(); index++) {
            TdfSObjectFactory.insertSObject(new ContentDocumentLink(LinkedEntityId = existingVisit.Id,
                ContentDocumentId = insertedDocs[index].ContentDocumentId));
        }

        Test.startTest();
        aforza__Visit__c newVisit = (aforza__Visit__c) TdfSObjectFactory.insertSObject(
            new aforza__Visit__c(RecordTypeId = RecordTypes.VISIT_DIRECT_VISIT_ID, aforza__Account__c = newAccount.Id,
                aforza__Type__c = 'Outlet Visit', aforza__Status__c = 'Not Started'));
        Test.stopTest();

        List<ContentDocumentLink> result = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :newVisit.Id];

        Assert.areEqual(4, result.size());
    }

    @IsTest
    static void testVisitInsert_ExistingNotStartedVisitsWithNotes() {
        Account newAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        aforza__Visit__c existingVisit = (aforza__Visit__c) TdfSObjectFactory.insertSObject(
            new aforza__Visit__c(RecordTypeId = RecordTypes.VISIT_DIRECT_VISIT_ID, aforza__Account__c = newAccount.Id,
                aforza__Type__c = 'Outlet Visit', aforza__Status__c = 'Not Started'));

        List<ContentVersion> newDocs = (List<ContentVersion>) TdfSObjectFactory.insertSObjects(
            new ContentVersion(PathOnClient = 'Test.sNote'), 5);

        List<ContentVersion> insertedDocs = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :newDocs];

        for (Integer index = 0; index < insertedDocs.size(); index++) {
            TdfSObjectFactory.insertSObject(new ContentDocumentLink(LinkedEntityId = existingVisit.Id,
                ContentDocumentId = insertedDocs[index].ContentDocumentId));
        }

        Test.startTest();
        aforza__Visit__c newVisit = (aforza__Visit__c) TdfSObjectFactory.insertSObject(
            new aforza__Visit__c(RecordTypeId = RecordTypes.VISIT_DIRECT_VISIT_ID, aforza__Account__c = newAccount.Id,
                aforza__Type__c = 'Outlet Visit', aforza__Status__c = 'Not Started'));
        Test.stopTest();

        List<ContentDocumentLink> result = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :newVisit.Id];

        Assert.areEqual(0, result.size());
    }

    @IsTest
    static void testVisitInsert_ExistingCompletedVisitsWithRelatedDocDifferentFromNotes() {
        Account newAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        aforza__Visit__c existingVisit = (aforza__Visit__c) TdfSObjectFactory.insertSObject(
            new aforza__Visit__c(RecordTypeId = RecordTypes.VISIT_DIRECT_VISIT_ID, aforza__Account__c = newAccount.Id,
                aforza__Type__c = 'Outlet Visit', aforza__Status__c = 'Completed'));

        List<ContentVersion> newDocs = (List<ContentVersion>) TdfSObjectFactory.insertSObjects(
            new ContentVersion(PathOnClient = 'Test.pdf'), 5
        );

        List<ContentVersion> insertedDocs = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :newDocs];

        for (Integer index = 0; index < insertedDocs.size(); index++) {
            TdfSObjectFactory.insertSObject(new ContentDocumentLink(LinkedEntityId = existingVisit.Id,
                ContentDocumentId = insertedDocs[index].ContentDocumentId));
        }

        Test.startTest();
        aforza__Visit__c newVisit = (aforza__Visit__c) TdfSObjectFactory.insertSObject(
            new aforza__Visit__c(RecordTypeId = RecordTypes.VISIT_DIRECT_VISIT_ID, aforza__Account__c = newAccount.Id,
                aforza__Type__c = 'Outlet Visit', aforza__Status__c = 'Not Started'));
        Test.stopTest();

        List<ContentDocumentLink> result = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :newVisit.Id];

        Assert.areEqual(0, result.size());
    }

    @IsTest
    static void testVisitInsert_NoExistingVisits() {
        Account newAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        Test.startTest();
        aforza__Visit__c newVisit = (aforza__Visit__c) TdfSObjectFactory.insertSObject(
            new aforza__Visit__c(RecordTypeId = RecordTypes.VISIT_DIRECT_VISIT_ID, aforza__Account__c = newAccount.Id,
                aforza__Type__c = 'Outlet Visit', aforza__Status__c = 'Not Started'));
        Test.stopTest();

        List<ContentDocumentLink> result = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :newVisit.Id];

        Assert.areEqual(0, result.size());
    }
}