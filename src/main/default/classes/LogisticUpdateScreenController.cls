/**
 * Created by svatopluk.sejkora on 05.10.2022.
 */

public with sharing class LogisticUpdateScreenController {

    @AuraEnabled
    public static List<PicklistDto> fetchNeededPicklistValues(String objectName, List<String> fieldNames) {
        try {
            List<PicklistDto> picklistDtos = new List<PicklistDto>();
            for (String fieldName : fieldNames) {
                for (PicklistEntry picklistEntry : DescriptionSobjectService.getPicklistEntries(fieldName, objectName)) {
                    PicklistDto picklistDto = new PicklistDto();
                    picklistDto.value = picklistEntry.getValue();
                    picklistDto.label = picklistEntry.getLabel();
                    picklistDto.fieldName = fieldName;
                    picklistDtos.add(picklistDto);
                }
            }
            return picklistDtos;
        } catch (Exception e) {
            throw new PopulateAuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateRecords(List<Id> recordIds, Map<String, Object> fieldValues) {
        try {
            if (recordIds.isEmpty()) {
                throw new Exceptions.BadDataException('List of ids provided is empty. Please make sure there is a value');
            }
            if (fieldValues.isEmpty()) {
                throw new Exceptions.BadDataException('Field values not provided. Please make sure valid field values are provided');
            }

            List<SObject> recordsToUpdate = new List<SObject>();
            for (Id recordId : recordIds) {
                String sObjName = DescriptionSobjectService.getSObjectName(recordId);

                Type objectType = Type.forName(sObjName);
                SObject recordToUpdate = (SObject) objectType.newInstance();

                recordToUpdate.put('Id', recordId);
                for (String field : fieldValues.keyset()) {
                    recordToUpdate.put(field, fieldValues.get(field));
                }

                recordsToUpdate.add(recordToUpdate);
            }

            update recordsToUpdate;
        } catch (Exception e) {
            throw new PopulateAuraHandledException(e.getMessage());
        }
    }

    public class PicklistDto {
        @AuraEnabled public String fieldName;
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }
}