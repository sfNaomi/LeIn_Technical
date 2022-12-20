/**
 * Created by magdalena.stanciu on 14.09.2022.
 */

public with sharing class CommonUtility {
    public enum QueryFieldType {
        SOURCE, TARGET
    }

    public static Boolean isMoreThanXWeeksAgo(Date referenceDate, Integer numberOfWeeks) {
        return referenceDate.daysBetween(System.today())> numberOfWeeks * 7;
    }

    public static FieldMapping__mdt getFieldMapping(String developerName) {
        if (developerName == null) {
            return null;
        }

        List<FieldMapping__mdt> mappings = [
            SELECT Id,
                (
                    SELECT Id, SourceField__c, StaticValue__c, TargetField__c
                    FROM FieldMappingItems__r
                )
            FROM FieldMapping__mdt
            WHERE DeveloperName = :developerName
            LIMIT 1
        ];

        return mappings.isEmpty() ? null : mappings.get(0);
    }

    public static UrlMapping__mdt getUrlMapping(String developerName) {
        if (developerName == null) {
            return null;
        }

        List<UrlMapping__mdt> mappings = [
            SELECT Id, BaseUrl__c,
                (
                    SELECT Id, SourceField__c, ParameterValue__c, StaticValue__c FROM UrlMappingItems__r

                )
            FROM UrlMapping__mdt
            WHERE DeveloperName = :developerName
            LIMIT 1
        ];

        return mappings.isEmpty() ? null : mappings.get(0);
    }

    public static void populateTargetSObjectFromSourceSObjectBasedOnMapping(
            SObject targetSObject,
            SObject sourceSObject,
            FieldMapping__mdt mapping
    ) {
        if (targetSObject == null || sourceSObject == null || mapping == null) {
            return;
        }

        for (FieldMappingItem__mdt mappingItem : mapping.FieldMappingItems__r) {
            // if value exists - don't overwrite
            if (targetSObject.get(mappingItem.TargetField__c) != null) {
                continue;
            }

            Object newValue = mappingItem.StaticValue__c;

            if (String.isEmpty(mappingItem.SourceField__c)) {
                targetSObject.put(mappingItem.TargetField__c, newValue);
                continue;
            }

            List<String> relatedRecordFields = mappingItem.SourceField__c.split('\\.');

            sObject nextObject = sourceSObject;
            for (Integer index = 0; index <relatedRecordFields.size() - 1; index++) {
                nextObject = nextObject?.getSObject(relatedRecordFields[index]);
            }
            newValue = nextObject?.get(relatedRecordFields.get(relatedRecordFields.size() - 1));

            targetSObject.put(mappingItem.TargetField__c, newValue);
        }
    }
    
     public static Set<String> getFieldsToQueryFromMapping(FieldMapping__mdt mapping, QueryFieldType fieldType) {
        Set<String> fields = new Set<String>{'Id'};

        if (mapping == null) {
            return fields;
        }

        String fieldName = null;
        switch on fieldType {
            when SOURCE {
                fieldName = 'SourceField__c';
            }
            when TARGET {
                fieldName = 'TargetField__c';
            }
        }

        for (FieldMappingItem__mdt mappingItem : mapping.FieldMappingItems__r) {
            if (String.isEmpty((String) mappingItem.get(fieldName))) {
                continue;
            }
            fields.add((String) mappingItem.get(fieldName));
        }

        return fields;
    }

    public static Set <String> urlGetFieldsToQuery(UrlMapping__mdt mapping) {
        Set <String> fields = new Set <String>{'Id'};

        if (mapping == null) {
           return fields;
        }

        for (UrlMappingItem__mdt mappingItem: mapping.UrlMappingItems__r) {
            if (String.isEmpty((String) mappingItem.get('SourceField__c'))) {
                continue;
            }
            fields.add((String) mappingItem.get('SourceField__c'));
        }    
        return fields;
    }

    public static String createUrlMethod(Sobject record, UrlMapping__mdt mapping){
         Map <String, String> mappedValuesAndParameters = urlMapFieldsToParameterValues(record, mapping);
         String url;
         String parameterString ='';
         String baseUrl;
        
         for (String urlMap: mappedValuesAndParameters.keyset()) {
             parameterString += (urlMap + '=' + mappedValuesAndParameters.get(urlMap) + '&');
         }
         parameterString += ('ddplanreference=' +  mappedValuesAndParameters.get('dddebtorreference'));

         parameterString = parameterString.trim();
         baseUrl = String.valueOf(mapping.BaseUrl__c).trim();
         url = baseUrl + '?' + parameterString;
         url = url.removeEnd('&');
         return url;     
     }
    
     public static Map <String, String> urlMapFieldsToParameterValues(SObject sourceSObject,UrlMapping__mdt mapping) {
         Map <String, String> mapFieldApiToFieldValue = new Map <String, String> ();
         List <UrlMappingItem__mdt> urlMdtValues = UrlMappingItem__mdt.getAll().values();
         Map <String, String> sourceFieldToParameterMap = new Map <String, String> ();
         Map <String, String> staticValueToParameterMap = new Map <String, String> ();
         Set <String> fieldValueNames = new Set <String> ();

         for (UrlMappingItem__mdt mappingItem: mapping.UrlMappingItems__r) {
             if (String.isNotBlank(mappingItem.staticValue__c)) {
                 String relatedRecord = mappingItem?.StaticValue__c;
                 mapFieldApiToFieldValue.put(mappingItem.ParameterValue__c, mappingItem.StaticValue__c);
             }
             
             else if (String.isNotBlank(mappingItem.SourceField__c)){
                 List <String> relatedRecordFields = mappingItem?.SourceField__c.split('\\.');
                 for (UrlMappingItem__mdt urlMdtValue: urlMdtValues) {
                     sourceFieldToParametermap.put(urlMdtValue.SourceField__c, urlMdtValue.ParameterValue__c);
                 }

                 Object newValue;
                 sObject nextObject = sourceSObject;
                 for (Integer index = 0; index <relatedRecordFields.size() - 1; index++) {
                     nextObject = nextObject?.getSObject(relatedRecordFields[index]);
                 }
                 
                 newValue = nextObject?.get(relatedRecordFields.get(relatedRecordFields.size() - 1));

                 if(String.isNotBlank(String.valueOf(newValue))){
                     mapFieldApiToFieldValue.put(sourceFieldToParametermap.get(mappingItem.SourceField__c), (String.valueOf(newValue)));
                 }
             }
         }
         return (mapFieldApiToFieldValue);
     }
}
