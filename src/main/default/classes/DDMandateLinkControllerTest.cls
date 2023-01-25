@IsTest
public with sharing class DDMandateLinkControllerTest {
    
    @IsTest
    private static void testPopulateDDUrlBasedOnMappings_Agent(){
        String agentUrl;        
      
               // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders' )
        );
     
        List<Account> storedAccounts = new List <Account>();
        Map<Id, Account> oldAccount = new Map <Id, Account> ([SELECT Id, DeliveryPointReference__c, DdActive__c, DirectDebitMandateRef__c FROM Account WHERE Id =:dpAccount.id]);
        
        Test.startTest();
        agentUrl = DDMandateLinkController.populateDDUrlBasedOnMappings(dpAccount.Id);
        Test.stopTest();

        System.assertEquals(FALSE, String.isBlank(agentUrl));
        System.assertEquals(TRUE, agentUrl.contains('agbarrplc/agent'));

    }
	
    @IsTest
    private static void testPopulateDDUrlBasedOnMappings_Customer(){
        List<UserRole> role = [SELECT Id FROM UserRole WHERE DeveloperName = 'FieldSalesController'];
        System.assertEquals(1, role.size());

        User user = (User) TdfSObjectFactory.insertSObject(new User(UserRoleId = role[0].Id));

        // assign proper permission set to user
        PermissionSet fieldSalesPermSet = [SELECT Id, name FROM PermissionSet WHERE Name = 'FieldSalesUser'][0];
        insert new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = fieldSalesPermSet.Id);

        String customerUrl;

        System.runAs(user) {
         // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders' )
        );
       
        List<Account> storedAccounts = new List <Account>();
        Map<Id, Account> oldAccount = new Map <Id, Account> ([SELECT Id, DeliveryPointReference__c, DdActive__c, DirectDebitMandateRef__c FROM Account WHERE Id =:dpAccount.id]);
                
        Test.startTest();
        customerUrl = DDMandateLinkController.populateDDUrlBasedOnMappings(dpAccount.Id);
        Test.stopTest();
        }
        
        System.assertEquals(FALSE, String.isBlank(customerUrl));      
        System.assertEquals(TRUE, customerUrl.contains('agbarrplc/debit'));

    }
}
