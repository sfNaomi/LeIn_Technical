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
    public static void updateOrderFields(List<String> orderIds, Map<String, Object> fieldValues) {
        try {
            if (orderIds.isEmpty()) {
                throw new Exceptions.BadDataException('Order Id provided is empty. Please make sure there is a value');
            }
            if (fieldValues.isEmpty()) {
                throw new Exceptions.BadDataException('Field values not provided. Please make sure valid field values are provided');
            }

            List<Order> ordersToUpdate = new List<Order>();
            for (String orderId : orderIds) {
                Order orderToUpdate = new Order();
                orderToUpdate.Id = orderId;
                for (String field : fieldValues.keyset()) {
                    orderToUpdate.put(field, fieldValues.get(field));
                }
                ordersToUpdate.add(orderToUpdate);
            }
            update ordersToUpdate;

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