/**
 * Created by svatopluk.sejkora on 27.09.2022.
 */

public with sharing class DescriptionSobjectService {

    public static Schema.DescribeFieldResult getSobjectDescribe(String fieldName, String sObjectName) {
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe()
                .get(sObjectName)
                .getDescribe()
                .fields
                .getMap()
                .get(fieldName)
                .getDescribe();
        return fieldResult;
    }

    public static String getFieldDataType(String fieldName, String sObjectName) {
        Schema.DisplayType displayType = Schema.getGlobalDescribe()
                .get(sObjectName)
                .getDescribe()
                .fields
                .getMap()
                .get(fieldName)
                .getDescribe()
                .getType();
        return String.valueOf(displayType);
    }

    public static List<PicklistEntry> getPicklistEntries(String fieldName, String sObjectName) {
        List<PicklistEntry> picklistEntries = Schema.getGlobalDescribe()
                .get(sObjectName)
                .getDescribe()
                .fields
                .getMap()
                .get(fieldName)
                .getDescribe()
                .getPicklistValues();
        return picklistEntries;
    }

    public static String getSObjectName(Id recordId) {
        return recordId.getSObjectType().getDescribe().getName();
    }
}