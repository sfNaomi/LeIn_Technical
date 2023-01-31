public without sharing class DdMandateCreationController {

    public static void updateMandateOnAccount(){       
        Map <String, String> callBackParameters = ApexPages.currentPage().getParameters();
        ddMandateCreationHandler(callBackParameters.get('DdPlanReference'), callBackParameters.get('Stage'));
    }
    
    @TestVisible
    private static void ddMandateCreationHandler(String ddPlan, String stage) {
        Account currentAccount;
        Account[] currentAccounts = [SELECT Id, DeliveryPointReference__c, DirectDebitMandateRef__c FROM Account WHERE DeliveryPointReference__c =: ddPlan LIMIT 1];
        List<aforza__Payment_Method__c> aforzaPaymentMethodsToCreate = new List<aforza__Payment_Method__c>();

        if (currentAccounts.size() > 0) {
            currentAccount = currentAccounts[0];
        }

        if (Integer.valueOf(stage) > 5){
            if(String.isBlank(currentAccount.DirectDebitMandateRef__c)){
                currentAccount.DirectDebitMandateRef__c = ddPlan;
                currentAccount.DdActive__c = true;
		currentAccount.PrimaryPaymentMethod__c = 'Direct Debit';
                
                aforzaPaymentMethodsToCreate.add(createNewAforzaPaymentMethodAndPopulateNecessaryFields(currentAccount.Id));

            }
           insert aforzaPaymentMethodsToCreate; 
        update currentAccount;
       
        }
    }
    private static aforza__Payment_Method__c createNewAforzaPaymentMethodAndPopulateNecessaryFields(Id parentAccountId){
            aforza__Payment_Method__c newAforzaPaymentMethod = new aforza__Payment_Method__c();
            newAforzaPaymentMethod.RecordTypeId=RecordTypes.PAYMENT_METHOD_DIRECT_CARD_ID;
            newAforzaPaymentMethod.aforza__Account__c = parentAccountId;
            newAforzaPaymentMethod.aforza__Active__c = true;
            newAforzaPaymentMethod.aforza__Primary__c = true;
        	
            return newAforzaPaymentMethod;    
	}
}
