/**
 * Created by magdalena.stanciu on 10.10.2022.
 */

public with sharing class FileGenerationService {
    public enum documentType {
        INVOICE,
        DELIVERY_NOTE
    }

    /**
    * @description generate documents of the specified type for the specified records
    *
    * @param docType type of document to be generated
    * @param recordIds ids of records to generate documents for
    *
    * @return Map<Id, ContentVersion> map with record ids as keys and generated content versions as values
    *
    * @author Magdalena Stanciu
    * @date 2022-10-10
    */
    public static Map<Id, ContentVersion> generateDocuments(documentType docType, Set<Id> recordIds) {
        if (recordIds.isEmpty()) {
            return null;
        }
        List<SObject> records = getRecords(recordIds);

        // generate files
        Map<Id, ContentVersion> contentVersionsByLinkedRecordId = new Map<Id, ContentVersion>();
        for (SObject record : records) {
            ContentVersion newContentVersion = generateContentVersion(docType, record);
            contentVersionsByLinkedRecordId.put((Id) record.get('Id'), newContentVersion);
        }
        insert contentVersionsByLinkedRecordId.values();

        // link files to records
        Map<Id, ContentVersion> insertedContentVersions = new Map<Id, ContentVersion>([
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id IN :contentVersionsByLinkedRecordId.values()
        ]);

        List<ContentDocumentLink> contentDocumentsLinksToInsert = new List<ContentDocumentLink>();
        for (Id recordId : contentVersionsByLinkedRecordId.keySet()) {
            Id contentVersionId = contentVersionsByLinkedRecordId.get(recordId)?.Id;
            ContentVersion insertedContentVersion = insertedContentVersions.get(contentVersionId);

            if (insertedContentVersion != null) {
                ContentDocumentLink newContentDocumentLink = generateContentDocumentLink(insertedContentVersion?.ContentDocumentId, recordId);
                contentDocumentsLinksToInsert.add(newContentDocumentLink);
            }
        }
        insert contentDocumentsLinksToInsert;

        return contentVersionsByLinkedRecordId;
    }

    /**
    * @description generates a content version of the specified type for the specified record
    *
    * @param docType type of document
    * @param record record to generate the document for
    *
    * @return N/A
    *
    * @author Magdalena Stanciu
    * @date 2022-10-10
    */
    @TestVisible
    private static ContentVersion generateContentVersion(documentType docType, SObject record) {
        PageReference pageRef = null;
        String documentName = null;
        String documentType = null;

        switch on docType {
            when INVOICE {
                pageRef = Page.AGBarrInvoice;
                documentName = 'Invoice ' + record?.getSObject('aforza__Order__r')?.get('OrderNumber') + ' ' + System.today().format() + '.pdf';
                documentType = 'Invoice';
            }
            when DELIVERY_NOTE {
                pageRef = Page.DeliveryNotePDF;
                documentName = 'Delivery Note ' + record.get('OrderNumber') + ' ' + System.today().format() + '.pdf';
                documentType = 'Delivery Note';
            }
            when else {
                throw new FileGenerationException('Invalid document type');
            }
        }

        Blob pdfContentBlob = getContentAsBlob((Id) record.get('Id'), pageRef);
        ContentVersion newContentVersion = new ContentVersion();
        newContentVersion.ContentLocation = 'S';
        newContentVersion.Origin = 'C';
        newContentVersion.OwnerId = UserInfo.getUserId();
        newContentVersion.VersionData = pdfContentBlob;
        newContentVersion.PathOnClient = documentName;
        newContentVersion.Title = documentName;
        newContentVersion.DocumentType__c = documentType;

        return newContentVersion;
    }

    /**
    * @description generates a content document link between a content document and a record
    *
    * @param contentDocumentId id of content document
    * @param linkedEntityId id of record (to link the content document to)
    *
    * @return ContentDocumentLink generated contend document link record
    *
    * @author Magdalena Stanciu
    * @date 2022-10-10
    */
    @TestVisible
    private static ContentDocumentLink generateContentDocumentLink(Id contentDocumentId, Id linkedEntityId) {
        ContentDocumentLink newContentDocumentLink = new ContentDocumentLink();
        newContentDocumentLink.ShareType = 'V';
        newContentDocumentLink.ContentDocumentId = contentDocumentId;
        newContentDocumentLink.LinkedEntityId = linkedEntityId;
        return newContentDocumentLink;
    }

    /**
    * @description retrieves records
    *
    * @param recordIds record ids
    *
    * @return List<SObject> retrieved records
    *
    * @author Magdalena Stanciu
    * @date 2022-10-10
    */
    @TestVisible
    private static List<SObject> getRecords(Set<Id> recordIds) {
        String objectName = getSObjectType((new List<Id>(recordIds)).get(0));
        String fieldsToQuery = 'Id';

        switch on objectName {
            when 'aforza__Invoice__c' {
                fieldsToQuery += ',aforza__Order__r.OrderNumber';
            }
            when 'Order' {
                fieldsToQuery += ',OrderNumber';
            }
        }

        String query = 'SELECT ' + fieldsToQuery + ' FROM ' + objectName + ' WHERE Id IN :recordIds';
        return Database.query(query);
    }

    /**
    * @description returns the sobject name based on record id
    *
    * @param recordId id of a record
    *
    * @return String name of the sobject type corresponding to the record id
    *
    * @author Magdalena Stanciu
    * @date 2022-10-10
    */
    @TestVisible
    private static String getSObjectType(Id recordId) {
        return recordId.getSobjectType().getDescribe().getName();
    }

    /**
    * @description gets the content of a rendered VF page as blob
    *
    * @param recordId id of a record
    * @param pageRef the page used to generate the file
    *
    * @return Blob page content as blob
    *
    * @author Magdalena Stanciu
    * @date 2022-10-10
    */
    @TestVisible
    private static Blob getContentAsBlob(Id recordId, PageReference pageRef) {
        pageRef.getParameters().put('p', recordId);
        Blob pdfBlob = Test.isRunningTest() ? Blob.valueOf('Test Page') : pageRef.getContent();
        return pdfBlob;
    }

    public class FileGenerationException extends Exception {

    }
}