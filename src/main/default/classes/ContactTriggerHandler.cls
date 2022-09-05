/**
 * @description       : Handler class for ContactTrigger
 **/

public with sharing class ContactTriggerHandler {
    public static void copyContactDetailsToRelatedAccounts(List<Contact> newContacts, List<Contact> oldContacts) {
        List<Contact> contactsToUpdateRelatedAccounts = new List<Contact>();
        for (Integer index = 0; index < newContacts.size(); index++) {
            if (newContacts[index].Email != oldContacts[index].Email || newContacts[index].Phone != oldContacts[index].Phone) {
                contactsToUpdateRelatedAccounts.add(newContacts[index]);
            }
        }

        ContactService.copyContactDetailsToRelatedAccounts(contactsToUpdateRelatedAccounts);
    }
}