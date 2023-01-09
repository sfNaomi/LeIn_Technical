/**
 * @description       : Service class implementing contact specific operations
 **/

public with sharing class ContactService {
    public static void copyContactDetailsToRelatedAccounts(List<Contact> newContacts) {
        List<Contact> contactsWithRelatedAccounts = [
                SELECT Id, Phone, Email, (SELECT Id FROM aforza__Accounts__r)
                FROM Contact
                WHERE Id IN :newContacts
        ];

        List<Account> accountsToUpdate = new List<Account>();
        for (Contact newContact : contactsWithRelatedAccounts) {
            for (Account relatedAccount : newContact.aforza__Accounts__r) {
                relatedAccount.Phone = newContact.Phone;
                relatedAccount.Email__c = newContact.Email;
                accountsToUpdate.add(relatedAccount);
            }
        }

        update accountsToUpdate;
    }
}