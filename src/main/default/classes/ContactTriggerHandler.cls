/**
 * @description       : Handler class for ContactTrigger
 **/

public with sharing class ContactTriggerHandler {
    public static void validateUniquePrimaryContactForParentAccount(List<Contact> newContacts) {
        List<Contact> contactsWhichRequireValidation = new List<Contact>();
        List<Id> parentAccountIds = new List<Id>();
        for (Contact newContact : newContacts) {
            if (newContact.PrimaryContact__c) {
                contactsWhichRequireValidation.add(newContact);
                parentAccountIds.add(newContact.AccountId);
            }
        }

        Map<Id, Account> parentAccounts = new Map<Id, Account>([
                SELECT Id, aforza__Primary_Contact__c
                FROM Account
                WHERE Id IN :parentAccountIds
        ]);

        for (Contact newContact : contactsWhichRequireValidation) {
            Account parentAccount = parentAccounts.get(newContact.AccountId);
            if (parentAccount?.aforza__Primary_Contact__c != null) {
                newContact.addError(Label.UniquePrimaryContactOnAccountValidationErrorMessage);
            }
        }
    }

    public static void validateUniquePrimaryContactForParentAccount(List<Contact> newContacts, List<Contact> oldContacts) {
        List<Contact> contactsWithPrimaryContactFieldUpdated = new List<Contact>();
        for (Integer index = 0; index < newContacts.size(); index++) {
            if (newContacts[index].PrimaryContact__c != oldContacts[index].PrimaryContact__c) {
                contactsWithPrimaryContactFieldUpdated.add(newContacts[index]);
            }
        }
        validateUniquePrimaryContactForParentAccount(contactsWithPrimaryContactFieldUpdated);
    }

    public static void updatePrimaryContactOnParentAccount(List<Contact> newContacts) {
        List<Contact> contactsToUpdatePrimaryContactOnParentAccount = new List<Contact>();
        for (Integer index = 0; index < newContacts.size(); index++) {
            if (newContacts[index].PrimaryContact__c) {
                contactsToUpdatePrimaryContactOnParentAccount.add(newContacts[index]);
            }
        }
        ContactService.updatePrimaryContactOnParentAccount(contactsToUpdatePrimaryContactOnParentAccount);
    }

    public static void updatePrimaryContactOnParentAccount(List<Contact> newContacts, List<Contact> oldContacts) {
        List<Contact> contactsToUpdatePrimaryContactOnParentAccount = new List<Contact>();
        for (Integer index = 0; index < newContacts.size(); index++) {
            if (newContacts[index].PrimaryContact__c != oldContacts[index].PrimaryContact__c) {
                contactsToUpdatePrimaryContactOnParentAccount.add(newContacts[index]);
            }
        }
        ContactService.updatePrimaryContactOnParentAccount(contactsToUpdatePrimaryContactOnParentAccount);
    }
}