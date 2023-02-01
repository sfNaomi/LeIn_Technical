/**
 * Created by svatopluk.sejkora on 23.09.2022.
 */

public with sharing class CallBaseManagementController {
    /**
     * @description queries all users with specified role.
     *
     * @return list of user including Id and first and last name
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    @AuraEnabled
    public static List<User> fetchTamUsers() {
        try {
            List<User> users = [SELECT Id, FirstName, LastName, Name FROM User WHERE UserRole.DeveloperName = 'TAM' AND IsActive = TRUE];
            return users.isEmpty() ? null : users;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            throw PopulateAuraHandledException.newMessageException(e.getMessage());
        }
    }

    /**
     * @description updates owner of visits
     *
     * @param visits list of visits ids -> owner will be changed for them
     * @param newOwner id of the new owner
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    @AuraEnabled
    public static void changeOwnerOfVisits(List<Id> visits, String newOwner) {
        try {
            if (String.isEmpty(newOwner)) {
                throw new IllegalArgumentException('A new owner Id is required please pass in valid Id : ' + newOwner);
            }
            if (visits.size() == 0) {
                throw new IllegalArgumentException('At least one visit has to be provided');
            }
            List<aforza__Visit__c> visitsToUpdate = new List<aforza__Visit__c>();
            for (Id visitId : visits) {
                aforza__Visit__c visit = new aforza__Visit__c(
                        Id = visitId,
                        aforza__Owner__c = newOwner
                );
                visitsToUpdate.add(visit);
            }
            update visitsToUpdate;
        } catch (Exception e) {
            throw PopulateAuraHandledException.newMessageException(e.getMessage());
        }
    }
}