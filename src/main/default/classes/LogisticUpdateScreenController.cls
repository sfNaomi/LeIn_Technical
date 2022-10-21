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
    public static void updateOrderStatus(List<String> orderIds, String newStatus) {
        try {
            if (orderIds.isEmpty()) {
                throw new Exceptions.BadDataException('Order Id provided is empty. Please make sure there is a value');
            }
            if (String.isEmpty(newStatus)) {
                throw new Exceptions.BadDataException('Order Status provided is empty. Please make sure there is a value');
            }

            List<Order> ordersToUpdate = new List<Order>();
            for (String orderId : orderIds) {
                Order order = new Order();
                order.Id = orderId;
                order.Status = newStatus;
                if (newStatus == 'Cancelled') {
                    order.DeliveryFailed__c = true;
                }
                if (newStatus == 'Unplanned') {
                    order.Replanned__c = true;
                }
                ordersToUpdate.add(order);
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