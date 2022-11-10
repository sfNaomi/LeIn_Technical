public class AforzaLabsSegmentToolHelper {
	
    public static boolean updatedByTrigger = false;    
    public static boolean updatedByBatch = false;
    
    private static Map<Id, Mapping> attributeMap;
    private static List<String> accountFieldNames;

    public static void generateAttributeMap() {

        attributeMap = new Map<Id, Mapping>();
        accountFieldNames = new List<String>();

        Map<String,Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Account.fields.getMap();
        Map<String,Id> codeToAttributeId = getCodeToAttributeId(configs);

        for(AforzaLabsSegmentToolConfig__mdt config : configs) {
            if(codeToAttributeId.containsKey(config.Attribute_Code__c) &&
               fieldMap.containsKey(config.Field__r.QualifiedApiName)) {
                Id attributeId = codeToAttributeId.get(config.Attribute_Code__c);
                attributeMap.put(attributeId, 
                    new Mapping(attributeId,
                                config.Attribute_Code__c,
                                fieldMap.get(config.Field__r.QualifiedApiName),
                                getRecordTypeIds(config.Record_Types__c, recordTypes)));
                accountFieldNames.add(config.Field__r.QualifiedApiName);
            }

        }
    }

    public static Map<Id, Mapping> getAttributeMappingConfig() {
        if(attributeMap == null) {
            generateAttributeMap();
        }
        return attributeMap;
    }

    public static List<String> getAccountFieldNames() {
        if(accountFieldNames == null) {
            generateAttributeMap();
        }
        return accountFieldNames;
    }

    @TestVisible
    private static List<AforzaLabsSegmentToolConfig__mdt> configs {
        get {
            if (configs == null) {
                configs = [
                    SELECT Id, Field__r.QualifiedApiName,
                           Attribute_Code__c, Record_Types__c
                    FROM AforzaLabsSegmentToolConfig__mdt
                    WHERE Active__c = TRUE];
            }
    
            return configs;
        }
        private set;
    }

    private static Set<Id> getRecordTypeIds(String csv, Map<String,Schema.RecordTypeInfo> recordTypes) {
        Set<Id> ids = new Set<Id>();

        if(!String.isBlank(csv)) {
            for(String recordType : csv.split(',')) {
                if(recordTypes.containskey(recordType.trim())) {
                    ids.add(recordTypes.get(recordType.trim()).getRecordTypeId());
                }
            }
        }

        return ids;
    }

    private static Map<String,Id> getCodeToAttributeId(List<AforzaLabsSegmentToolConfig__mdt> configs) {
        Map<String,Id> codeToAttributeId = new Map<String,Id>();
        Set<String> codes = new Set<String>();
        
        for(AforzaLabsSegmentToolConfig__mdt config : configs) {
            codes.add(config.Attribute_Code__c);
        }

        for(aforza__Attribute__c attr : [SELECT Id, aforza__Code__c FROM aforza__Attribute__c WHERE aforza__Code__c IN :codes]){
            codeToAttributeId.put(attr.aforza__Code__c, attr.Id);
        }

        return codeToAttributeId;
    }

    public class Mapping {
        public String attributeId;
        public String attributeCode;
        public SObjectField accountField;
        public DisplayType accountFieldType;
        public Set<Id> recordTypeIds;
        public Map<String, String> picklistLabelToValue;
        public Map<String, String> picklistValueToLabel;

        public Mapping(String attributeId, String attributeCode, SObjectField accountField, Set<Id> recordTypeIds) {
            this.attributeCode = attributeCode;
            this.attributeId = attributeId;
            this.accountField = accountField;
            this.accountFieldType = accountField.getDescribe().getType();
            this.recordTypeIds = recordTypeIds;
            if(accountFieldType == DisplayType.PICKLIST) {
                picklistLabelToValue = new Map<String, String>();
                picklistValueToLabel = new Map<String, String>();
                for(PickListEntry ple : accountField.getDescribe().getPicklistValues()) {
                    picklistLabelToValue.put(ple.label, ple.value);
                    picklistValueToLabel.put(ple.value, ple.label);
                }
            }
        }
    }
}