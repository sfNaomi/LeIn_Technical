public with sharing class DdMandateLinkController {
    /*@AuraEnabled
    public static String populateDDUrlBasedOnMappings(String accountId) { 
        Account thisAccount = [SELECT Id, BillingPostalCode, BillingStreet, BillingCity, DeliveryPointReference__c,
                              aforza__Primary_Contact__c, aforza__Primary_Contact__r.FirstName,aforza__Primary_Contact__r.Email,
                              aforza__Primary_Contact__r.LastName, BottomlineRefNumber__c FROM Account WHERE Id =:accountId limit 1];
            
        UrlMapping__mdt agentUrlMapping = AccountService.AGENT_MANDATE_URL_MAPPING;
        UrlMapping__mdt customerUrlMapping = AccountService.CUSTOMER_MANDATE_URL_MAPPING;
        
        Set <String> agentUrlFields = CommonUtility.urlGetFieldsToQuery(agentUrlMapping);
        Set <String> customerUrlFields = CommonUtility.urlGetFieldsToQuery(customerUrlMapping);
        agentUrlFields.addAll(customerUrlFields);
        
        List <String> allUrlFields = new List <String> (agentUrlFields);
        Map <Id, Account> agentAccountsWithFieldData = AccountService.getAccountDetailsFromFields(allUrlFields, accountId);

        String agentMandateUrl = CommonUtility.createUrlMethod(thisAccount, agentUrlMapping);
        String customerMandateUrl = CommonUtility.createUrlMethod(thisAccount, customerUrlMapping);
                
        String returnedUrl;

        if (FeatureManagement.checkPermission('FieldSalesUser')){
           returnedUrl = customerMandateUrl;
        }
         else{
            returnedUrl = agentMandateUrl;
        }
        return returnedUrl;         
    }*/
}
