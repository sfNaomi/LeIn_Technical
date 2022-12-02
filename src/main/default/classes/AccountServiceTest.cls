@IsTest
public class AccountServiceTest {	
@IsTest
    private static void testDdMandateCreationHandlerStageOver6(){
         // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );
    
        Account accRef1 = [SELECT Id, DeliveryPointReference__c, DdActive__c, DirectDebitMandateRef__c FROM Account WHERE Id =:dpAccount.id];
        
        System.assertEquals(FALSE, accRef1.DdActive__c);
		
        String deliveryRef = accRef1.DeliveryPointReference__c;
        DdMandateCreationController.ddMandateCreationHandler(deliveryRef, '9');
        Account accRef2 = [SELECT Id, DeliveryPointReference__c, DdActive__c, DirectDebitMandateRef__c FROM Account WHERE Id =:dpAccount.id];

        System.assertEquals(TRUE, accRef2.DdActive__c);
        System.assertEquals(deliveryRef, accRef2.DirectDebitMandateRef__c);
    }
	
    @IsTest
    private static void testDdMandateCreationHandlerStage6OrBelow(){
         // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );
    
        Account accRef1 = [SELECT Id, DeliveryPointReference__c, DdActive__c, DirectDebitMandateRef__c FROM Account WHERE Id =:dpAccount.id];
        
        System.assertEquals(FALSE, accRef1.DdActive__c);
		
        String deliveryRef = accRef1.DeliveryPointReference__c;
        DdMandateCreationController.ddMandateCreationHandler(deliveryRef, '4');
        Account accRef2 = [SELECT Id, DeliveryPointReference__c, DdActive__c, DirectDebitMandateRef__c FROM Account WHERE Id =:dpAccount.id];

        System.assertEquals(FALSE, accRef2.DdActive__c, 'DD Active should be false');
        System.assertNotEquals(deliveryRef, accRef2.DirectDebitMandateRef__c);
    }
}
