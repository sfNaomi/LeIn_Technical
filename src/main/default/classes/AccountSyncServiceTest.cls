/**
 * Created by magdalena.stanciu on 05.10.2022.
 */

@IsTest
private with sharing class AccountSyncServiceTest {

    @IsTest
    public static void testSetFieldToDefaultValue() {
        Account customerAccount = (Account) TdfSObjectFactory.createSObject(
                new Account(
                        RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID,
                        BillingStreet = 'Test 1',
                        NumberOfEmployees = 0,
                        DefaultInvoiceBillingAddress__c = false,
                        aforza__Credit_Amount__c = 0,
                        LastOrderDate__c = System.today()
                )
        );

        AccountSyncService.setFieldToDefaultValue(customerAccount, 'BillingStreet', 'Test 2');
        System.assertEquals('Test 2', customerAccount.BillingStreet);

        AccountSyncService.setFieldToDefaultValue(customerAccount, 'NumberOfEmployees', '20');
        System.assertEquals(20, customerAccount.NumberOfEmployees);

        AccountSyncService.setFieldToDefaultValue(customerAccount, 'DefaultInvoiceBillingAddress__c', 'true');
        System.assertEquals(true, customerAccount.DefaultInvoiceBillingAddress__c);

        AccountSyncService.setFieldToDefaultValue(customerAccount, 'aforza__Credit_Amount__c', '2000.0');
        System.assertEquals(2000, customerAccount.aforza__Credit_Amount__c);

        AccountSyncService.setFieldToDefaultValue(customerAccount, 'LastOrderDate__c', '2015-01-01');
        System.assertEquals(Date.valueOf('2015-01-01'), customerAccount.LastOrderDate__c);
    }

    @IsTest
    public static void testGetRelatedAccounts() {
        Account customerAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_CUSTOMER_ID, PORequired__c = false)
        );
        List<Account> dpAccounts = (List<Account>) TdfSObjectFactory.insertSObjects(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, ParentId = customerAccount.Id), 2
        );

        System.assertEquals(2, AccountSyncService.getRelatedAccounts(new List<Account>{customerAccount},AccountSyncService.AccountType.PARENT).size());
        System.assertEquals(1, AccountSyncService.getRelatedAccounts(dpAccounts, AccountSyncService.AccountType.CHILD).size());
    }
}