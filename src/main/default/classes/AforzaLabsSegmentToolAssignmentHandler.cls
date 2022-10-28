public class AforzaLabsSegmentToolAssignmentHandler {
    
    public static void main(List<aforza__Attribute_Assignment__c> assignments, Boolean afterDelete) {
        if (!AforzaLabsSegmentToolHelper.updatedByTrigger) {
            AforzaLabsSegmentToolHelper.updatedByTrigger = true;

            Map<Id,AforzaLabsSegmentToolHelper.Mapping>  attributeIdToAccountFieldMap = AforzaLabsSegmentToolHelper.getAttributeMappingConfig();
            
            Set<Id> accountIds = new Set<Id>();
            
            for (aforza__Attribute_Assignment__c a : assignments) {
                accountIds.add(a.aforza__Account__c);
            }
                        
            try {
                List<Account> accountsToUpdate = new List<Account>();
                Map<Id, Account> accounts = getAccounts(accountIds);
                
                for (aforza__Attribute_Assignment__c ass : assignments) {
                    AforzaLabsSegmentToolHelper.Mapping mapping = attributeIdToAccountFieldMap.get(ass.aforza__Attribute__c);
                    Account acc = accounts.get(ass.aforza__Account__c);
                    if(mapping != null && acc != null) {
                        if(mapping.recordTypeIds.isEmpty() || mapping.recordTypeIds.contains(acc.RecordTypeId)) {
                        
                            if (!afterDelete) {
                                 if(mapping.accountFieldType == DisplayType.BOOLEAN) {
                                    if(acc.get(mapping.accountField) != true) {
                                        acc.put(mapping.accountField, true);
                                        accountsToUpdate.add(acc);
                                    }
                                 }
                                 else if(mapping.accountFieldType == DisplayType.PICKLIST) {
                                    String value = mapping.picklistLabelToValue.get(ass.aforza__Value__c);
                                    if(acc.get(mapping.accountField) != value) {
                                        acc.put(mapping.accountField, value);
                                        accountsToUpdate.add(acc);
                                    }
                                 }
                                 else {//if it's a number?
                                    if(String.valueOf(acc.get(mapping.accountField)) != ass.aforza__Value__c) {
                                        acc.put(mapping.accountField, ass.aforza__Value__c);
                                        accountsToUpdate.add(acc);
                                    }
                                 }
                            } else {
                                if (mapping.accountFieldType == DisplayType.BOOLEAN) {
                                    if((Boolean)acc.get(mapping.accountField)) {
                                        acc.put(mapping.accountField, false);
                                        accountsToUpdate.add(acc);
                                    }
                                } else {
                                    if(acc.get(mapping.accountField) != null) {
                                        acc.put(mapping.accountField, null);    
                                        accountsToUpdate.add(acc);
                                    }
                                }	
                            }
                       	}
                    }
            	}
            
            	update accounts.values();
            } catch (Exception e) {
                system.debug('ERROR: ' + e);
            }
            AforzaLabsSegmentToolHelper.updatedByTrigger = false;
        }
    }
    
    private static Map<Id, Account> getAccounts(Set<Id> accountIds) {
        String query = 'SELECT Id, RecordTypeId,' + String.join(AforzaLabsSegmentToolHelper.getAccountFieldNames(), ',');
        query += ' FROM Account WHERE Id IN: accountIds';
        system.debug('query====> ' + query);
        return new Map<Id, Account>((List<Account>)database.query(query));
    }
}