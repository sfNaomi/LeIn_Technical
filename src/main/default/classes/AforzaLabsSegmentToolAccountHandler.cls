public class AforzaLabsSegmentToolAccountHandler {
    
    public static void afterInsert(Map<Id, Account> accountsNew) {
        if(!AforzaLabsSegmentToolHelper.updatedByTrigger) {
            main(accountsNew);
        }
    }
    
    public static void afterUpdate(List<Account> accountsNew, List<Account> accountsOld) {  
        if(!AforzaLabsSegmentToolHelper.updatedByTrigger) {

            Map<Id, Account> accounts = new Map<Id, Account>();
            try {
                for (Integer i = 0; i < accountsNew.size(); i++) {
                    
                    for(AforzaLabsSegmentToolHelper.Mapping mapping : AforzaLabsSegmentToolHelper.getAttributeMappingConfig().values()) {
                        
                        if (accountsNew[i].get(mapping.accountField) != accountsOld[i].get(mapping.accountField)) {
                            accounts.put(accountsNew[i].Id, accountsNew[i]);
                        } 
                    }
                }
            
            	main(accounts);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'ERROR: ' + e);
            }
        }
    }
    
    public static void beforeDelete(Map<Id, Account> accountsOld) {
        delete [SELECT Id FROM aforza__Attribute_Assignment__c WHERE aforza__Account__c IN : accountsOld.keySet()];
    }

    /************************************
     * Main method for class to be run from afterInstert && afterUpdate
     ***********************************/
    private static void main(Map<Id, Account> accounts) {        
        if (accounts.keySet().size() > 0) {
            AforzaLabsSegmentToolHelper.updatedByTrigger = true;
            try {
                List<List<aforza__Attribute_Assignment__c>> resultList = attributeAssignmentsToCUD(accounts);
                database.insert(resultList[0]);
                database.update(resultList[1]);
                if (resultList[2].size() > 0) 
                    database.delete(resultList[2]);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'ERROR: ' + e);
            }
            
            AforzaLabsSegmentToolHelper.updatedByTrigger = false;
            AforzaLabsSegmentToolHelper.updatedByBatch = false;
        }        
    }

    /************************************
     * For each account create a Map of the AttributeCode to Attribute Assignments: attributesToAssignments
     * Then Map Each account to the accountToAssignments Map
     ***********************************/
    private static Map<Id, Map<String, aforza__Attribute_Assignment__c>> mapAccountToAttributeAssignments(Set<Id> accountIds) {
        Map<Id, Map<String, aforza__Attribute_Assignment__c>> accountToAssignments = new Map<Id, Map<String, aforza__Attribute_Assignment__c>>();        
        
        List<Account> accountsWithAssignments = [SELECT Id, (SELECT Id, aforza__Attribute__r.aforza__Code__c, aforza__Value__c
                                                             FROM aforza__Attribute_Assignments__r)
                                                 FROM Account 
                                                 WHERE Id IN :accountIds];
        
        for (Account a: accountsWithAssignments) {
            Map<String, aforza__Attribute_Assignment__c> attributeToAssignment = new Map<String, aforza__Attribute_Assignment__c>();
            
            for (Integer i = 0; i < a.aforza__Attribute_Assignments__r.size(); i++) {
                attributeToAssignment.put(a.aforza__Attribute_Assignments__r[i].aforza__Attribute__r.aforza__Code__c, a.aforza__Attribute_Assignments__r[i]);
            }
            accountToAssignments.put(a.Id, attributeToAssignment);
        }
        return accountToAssignments;
    }
    
    private static List<aforza__Attribute__c> getAttributes(Set<String> attributeCodes) {
        return [SELECT Id, aforza__Code__c FROM aforza__Attribute__c 
                WHERE aforza__Code__c IN :attributeCodes
                AND aforza__Active__c = true];
    }
    
    /************************************
     * This method loops over the accounts that have updated
     * Decides which fields need their Attribute Assignments Created
     * Decides which fields need their Attribute Assignments Updated
     * Decides which fields need their Attribute Assignments Deleted
     ***********************************/
    private static List<List<aforza__Attribute_Assignment__c>> attributeAssignmentsToCUD(Map<Id, Account> accounts) {
       	List<List<aforza__Attribute_Assignment__c>> returnList = new List<List<aforza__Attribute_Assignment__c>>();
        Map<Id, Map<String, aforza__Attribute_Assignment__c>> accountToAttributeAssignments = mapAccountToAttributeAssignments(accounts.keySet());
        
        Map<Id, AforzaLabsSegmentToolHelper.Mapping> attrMapping = AforzaLabsSegmentToolHelper.getAttributeMappingConfig();

        List<aforza__Attribute_Assignment__c> assignmentsToCreate = new List<aforza__Attribute_Assignment__c>();
        List<aforza__Attribute_Assignment__c> assignmentsToUpdate = new List<aforza__Attribute_Assignment__c>();
        List<aforza__Attribute_Assignment__c> assignmentsToDelete = new List<aforza__Attribute_Assignment__c>();
        
        for (Account acc : accounts.values()) {
            Map<String, aforza__Attribute_Assignment__c> attributeCodesToAttributeAssignments = accountToAttributeAssignments.get(acc.Id);

            for(AforzaLabsSegmentToolHelper.Mapping mapping:  attrMapping.values()) {
                if(mapping.recordTypeIds.isEmpty() || mapping.recordTypeIds.contains(acc.RecordTypeId)) {
                    Object fieldValue = acc.get(mapping.accountField);
                    //if attribute assignment already exists
                    if(attributeCodesToAttributeAssignments.keySet().contains(mapping.attributeCode)) {
                        aforza__Attribute_Assignment__c ass = attributeCodesToAttributeAssignments.get(mapping.attributeCode);
                        if (fieldValue == null || fieldValue == false) {
                            assignmentsToDelete.add(ass);
                        }
                        else if(ass.aforza__Value__c != String.valueOf(fieldValue)){
                            if(mapping.accountFieldType == DisplayType.PICKLIST) {
                                if(ass.aforza__Value__c != mapping.picklistValueToLabel.get(String.valueOf(fieldValue))){
                                    ass.aforza__Value__c = mapping.picklistValueToLabel.get(String.valueOf(fieldValue));
                                    assignmentsToUpdate.add(ass);
                                }
                            }
                            else {
                                ass.aforza__Value__c = String.valueOf(fieldValue);
                                assignmentsToUpdate.add(ass);
                            }
                        }
                    }
                    else if(fieldValue != null && fieldValue != false) {
                        aforza__Attribute_Assignment__c newAss = new aforza__Attribute_Assignment__c(
                            aforza__Account__c = acc.Id,
                            aforza__Attribute__c = mapping.attributeId);
                        newAss.aforza__Value__c = (mapping.accountFieldType == DisplayType.PICKLIST) ?
                            mapping.picklistValueToLabel.get((String)fieldValue) :
                            String.valueOf(fieldValue);
                        assignmentsToCreate.add(newAss);
                    }

                }
            }
        }

        returnList.add(assignmentsToCreate);
        returnList.add(assignmentsToUpdate);
        returnList.add(assignmentsToDelete);
        return returnList;
    }
}