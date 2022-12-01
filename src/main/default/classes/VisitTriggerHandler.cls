/**
 * Created by magdalena.stanciu on 28.11.2022.
 */

public with sharing class VisitTriggerHandler {
    private final static String COMPLETED_STATUS = 'Completed';
    private final static String FILE_TYPE = 'SNote';
    private final static Integer NUMBER_OF_VISITS_TO_COPY = 4;

    /**
     * @description related to the inserted visits, the notes from the last 4 completed visits (if any)
     *
     * @param newVisits map of inserted visits
     *
     *
     * @author Magdalena Stanciu, BearingPoint
     * @date 2022-11-29
     */
    public static void copyLast4VisitNotesOnVisit(Map<Id, aforza__Visit__c> newVisits) {
        Map<Id, Set<Id>> accountIdsToVisitIds = new Map<Id, Set<Id>>();
        for (aforza__Visit__c newVisit : newVisits.values()) {
            if (!accountIdsToVisitIds.containsKey(newVisit.aforza__Account__c)) {
                Set<Id> temp = new Set<Id>();
                temp.add(newVisit.Id);
                accountIdsToVisitIds.put(newVisit.aforza__Account__c, temp);
            } else {
                accountIdsToVisitIds.get(newVisit.aforza__Account__c).add(newVisit.Id);
            }
        }

        List<Account> accountsToCompletedVisits = getAccountsWithRelatedCompletedVisits(accountIdsToVisitIds.keyset(), newVisits.keySet());

        Set<Id> completedVisitIds = new Set<Id>();
        for (Account parentAccount : accountsToCompletedVisits) {
            for (aforza__Visit__c visit : parentAccount.aforza__Visits__r) {
                completedVisitIds.add(visit.Id);
            }
        }

        Map<Id, aforza__Visit__c> completedVisitsWithNotes = getVisitsWithRelatedNotes(completedVisitIds);

        Integer count = 0;
        List<ContentDocumentLink> contentDocumentLinksToInsert = new List<ContentDocumentLink>();
        Set<Id> preventDuplicateDocuments = new Set<Id>();

        for(Account parentAccount : accountsToCompletedVisits) {
            for (aforza__Visit__c visit : parentAccount.aforza__Visits__r) {
                for (ContentDocumentLink relatedFile : completedVisitsWithNotes.get(visit.Id).ContentDocumentLinks) {
                    if (relatedFile.LinkedEntityId.getSObjectType() == aforza__Visit__c.SObjectType &&
                        !preventDuplicateDocuments.contains(relatedFile.ContentDocumentId) &&
                        relatedFile.ContentDocument.FileType == FILE_TYPE) {

                        for(Id visId : accountIdsToVisitIds.get(parentAccount.Id)) {
                            if (count < NUMBER_OF_VISITS_TO_COPY) {
                                ContentDocumentLink newDocLink = mapContentDocumentLink(visId, relatedFile);
                                contentDocumentLinksToInsert.add(newDocLink);
                            }
                        }

                        preventDuplicateDocuments.add(relatedFile.ContentDocumentId);
                        count++;
                    }

                    if (count == NUMBER_OF_VISITS_TO_COPY) {
                        break;
                    }
                }
            }

            count = 0;
        }

        insert contentDocumentLinksToInsert;
    }

    /**
     * @description retrieves accounts with last n completed visits
     *
     * @param accountIds set of account ids to query the visits for
     * @param visitIds set of visit ids to exclude from query
     *
     * @return list of retrieved accounts
     *
     * @author Magdalena Stanciu, BearingPoint
     * @date 2022-11-29
     */
    private static List<Account> getAccountsWithRelatedCompletedVisits(Set<Id> accountIds, Set<Id> visitIds) {
        List<Account> accounts = [
            SELECT Id,
            (
                SELECT Id
                FROM aforza__Visits__r
                WHERE aforza__Status__c = :COMPLETED_STATUS AND Id NOT IN :visitIds
                ORDER BY aforza__Planned_Time__c DESC
                LIMIT :NUMBER_OF_VISITS_TO_COPY
            )
            FROM Account
            WHERE Id IN :accountIds
        ];
        return accounts;
    }

    /**
     * @description retrieves visits with related files
     *
     * @param visitIds set of visit ids to retrieve files for
     *
     * @return map of retrieved visits
     *
     * @author Magdalena Stanciu, BearingPoint
     * @date 2022-11-29
     */
    private static Map<Id, aforza__Visit__c> getVisitsWithRelatedNotes(Set<Id> visitIds) {
        Map<Id, aforza__Visit__c> visits = new Map<Id, aforza__Visit__c>([
            SELECT Id, aforza__Account__c,
                (
                    SELECT Id, ContentDocumentId, ContentDocument.FileType, LinkedEntityId, ShareType, Visibility
                    FROM ContentDocumentLinks
                    ORDER BY ContentDocument.CreatedDate DESC
                )
            FROM aforza__Visit__c
            WHERE Id IN :visitIds
        ]);
        return visits;
    }

    /**
     * @description creates a content document link based on an existing content document link and relates it to the entity
     *              provided as parameter
     *
     * @param linkedEntityId id of record to relate the document to
     * @param existingDocLink existing
     *
     * @return created content document link
     *
     * @author Magdalena Stanciu, BearingPoint
     * @date 2022-11-29
     */
    private static ContentDocumentLink mapContentDocumentLink(Id linkedEntityId, ContentDocumentLink existingDocLink) {
        ContentDocumentLink newDocLink = new ContentDocumentLink(
            ContentDocumentId = existingDocLink.ContentDocumentId,
            LinkedEntityId = linkedEntityId,
            ShareType = existingDocLink.ShareType,
            Visibility = existingDocLink.Visibility
        );
        return newDocLink;
    }
}