@IsTest
public class AccountServiceTest {	
    @IsTest
    private static void DdMandateCreationHandlerStageOver6(){
         // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );
    
        Account accRef1 = [SELECT Id, DeliveryPointReference__c, DdActive__c, DirectDebitMandateRef__c FROM Account WHERE Id =:dpAccount.id];
        
        System.assertEquals(FALSE, accRef1.DdActive__c);
		
        String deliveryRef = accRef1.DeliveryPointReference__c;
        DdMandateCreationController.ddMandateCreationHandler(deliveryRef, '9');
        
        aforza__Payment_Method__c newPayment = [SELECT Id, aforza__Account__c, aforza__Active__c, aforza__Primary__c, RecordTypeId
                                                FROM aforza__Payment_Method__c WHERE aforza__Account__c =:dpAccount.Id];
        Account accRef2 = [SELECT Id, DeliveryPointReference__c, DdActive__c, DirectDebitMandateRef__c FROM Account WHERE Id =:dpAccount.id];

        Assert.areEqual(true, newPayment.aforza__Active__c);
        Assert.areEqual(true, newPayment.aforza__Primary__c);
        Assert.areEqual(accRef2.Id, newPayment.aforza__Account__c);
        Assert.areEqual(RecordTypes.PAYMENT_METHOD_DIRECT_CARD_ID, newPayment.RecordTypeId);

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
