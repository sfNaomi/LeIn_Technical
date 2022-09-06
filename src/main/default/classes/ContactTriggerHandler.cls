/**
 * @description       : Handler class for ContactTrigger
 **/

public with sharing class ContactTriggerHandler {
    public static void copyContactDetailsToRelatedAccounts(List<Contact> newContacts, List<Contact> oldContacts) {
        List<Contact> contactsToUpdateRelatedAccounts = new List<Contact>();
        for (Integer index = 0; index < newContacts.size(); index++) {
            if (newContacts.get(index).Email != oldContacts?.get(index)?.Email ||
                    newContacts.get(index).Phone != oldContacts?.get(index)?.Phone) {
                contactsToUpdateRelatedAccounts.add(newContacts[index]);
            }
        }

        ContactService.copyContactDetailsToRelatedAccounts(contactsToUpdateRelatedAccounts);
    }
}