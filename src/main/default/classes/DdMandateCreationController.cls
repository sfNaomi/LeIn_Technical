public without sharing class DdMandateCreationController {

    public static void updateMandateOnAccount(){       
        Map <string, string> callBackParameters = apexpages.currentPage().getParameters();
        ddMandateCreationHandler(callBackParameters.get('DdPlanReference'), callBackParameters.get('Stage'));
    }
    
    @TestVisible
    private static void ddMandateCreationHandler(String ddPlan, String stage) {
        Account currentAccount;
        Account[] currentAccounts = [SELECT Id, DeliveryPointReference__c, DirectDebitMandateRef__c FROM Account WHERE DeliveryPointReference__c =: ddPlan limit 1];
        
        if (currentAccounts.size() > 0) {
            currentAccount = currentAccounts[0];
        }

        if (Integer.valueOf(stage) >5){
            if(String.isBlank(currentAccount.DirectDebitMandateRef__c)){
                currentAccount.DirectDebitMandateRef__c = ddPlan;
                currentAccount.DdActive__c = TRUE;
            }
           
        update currentAccount;
        }
    }
}
