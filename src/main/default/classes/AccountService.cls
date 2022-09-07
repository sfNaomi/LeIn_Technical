/**
 * @description       : Service class implementing account specific operations
 **/

public with sharing class AccountService {
    public static void copyContactDetailsFromPrimaryContact(List<Account> newAccounts) {
        Set<Id> primaryContactIds = new Set<Id>();
        for (Account newAccount : newAccounts) {
            primaryContactIds.add(newAccount.aforza__Primary_Contact__c);
        }
        primaryContactIds.remove(null);

        Map<Id, Contact> primaryContacts = new Map<Id, Contact>([
                SELECT Id, Email, Phone
                FROM Contact
                WHERE Id IN :primaryContactIds
        ]);

        for (Account newAccount : newAccounts) {
            Contact primaryContact = primaryContacts.get(newAccount.aforza__Primary_Contact__c);
            newAccount.Phone = primaryContact?.Phone;
            newAccount.Email__c = primaryContact?.Email;
        }
    }
}