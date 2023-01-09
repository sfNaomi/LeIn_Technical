@IsTest
private class ImageViewerControllerTest {

    @IsTest
    private static void setupData() {
        Account newAccount = (Account) TdfSObjectFactory.insertSObject(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)
        );
        aforza__Audit__c newAudit = (aforza__Audit__c) TdfSObjectFactory.insertSObject(
            new aforza__Audit__c(aforza__Account__c = newAccount.Id)
        );
        aforza__Audit_Asset__c newAsset = (aforza__Audit_Asset__c) TdfSObjectFactory.insertSObject(
            new aforza__Audit_Asset__c(aforza__Audit__c = newAudit.Id)
        );
        aforza__Visit__c newVisit = (aforza__Visit__c) TdfSObjectFactory.insertSObject(
            new aforza__Visit__c(
                aforza__Account__c = newAccount.Id,
                aforza__Status__c = 'Completed',
                RecordTypeId = RecordTypes.VISIT_REMOTE_VISIT_ID
            )
        );

        ContentVersion newContentVersion = (ContentVersion) TdfSObjectFactory.insertSObject(new ContentVersion());

        ContentVersion contentVersionDocId = [
                SELECT Id, Title, ContentDocumentId
                FROM ContentVersion
                WHERE Id = :newContentVersion.Id
                LIMIT 1
        ];

        TdfSObjectFactory.insertSObject(
            new ContentDocumentLink(
                LinkedEntityId = newAudit.Id,
                ContentDocumentId = contentVersionDocId.contentdocumentid,
                ShareType = 'V'
            )
        );
        TdfSObjectFactory.insertSObject(
            new ContentDocumentLink(
                LinkedEntityId = newAsset.Id,
                ContentDocumentId = contentVersionDocId.contentdocumentid,
                ShareType = 'V'
            )
        );
        TdfSObjectFactory.insertSObject(
            new ContentDocumentLink(
                LinkedEntityId = newVisit.Id,
                ContentDocumentId = contentVersionDocId.contentdocumentid,
                ShareType = 'V'
            )
        );

        Test.startTest();
        ImageViewerController.GenericObjectDTO result = ImageViewerController.getImageFiles(null, null, null, null, null, null);
        Test.stopTest();

        System.assertEquals(3, result.genericDto.size());
    }
}