/**
 * @description       : Service class implementing contact specific operations
 **/

public with sharing class ContactService {
    public static void updatePrimaryContactOnParentAccount(List<Contact> newContacts) {
        List<Account> parentAccountsToUpdate = new List<Account>();
        for (Contact newContact : newContacts) {
            if (newContact.AccountId == null) {
                continue;
            }

            Id primaryContactId = newContact.PrimaryContact__c ? newContact.Id : null;

            Account newAccountToUpdate = new Account (
                    Id = newContact.AccountId,
                    aforza__Primary_Contact__c = primaryContactId
            );
            parentAccountsToUpdate.add(newAccountToUpdate);
        }

        try {
            update parentAccountsToUpdate;
        } catch (Exception ex) {
            // to do: introduce logging
        }
    }
}