/**
 * Created by svatopluk.sejkora on 20.09.2022.
 */

public with sharing class DynamicFilterController {
    /**
     * @description Fetches records based on searchText and SObjectName
     *
     * @param sObjectName input filter
     * @param returnFields input filter
     * @param queryFields input filter
     * @param limitRows number of rows to return
     * @return List of SObjects which contains searchText in one of queryFields
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    @AuraEnabled
    public static List<SObject> getResults(String sObjectName, List<String> returnFields, String queryFields, Integer limitRows) {
        try {
            String sQuery = buildQuery(sObjectName, returnFields, queryFields, limitRows);
            return Database.query(sQuery);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            throw PopulateAuraHandledException.newMessageException(e.getMessage());
        }
    }

    /**
     * @description build a complete query.
     *
     * @param sObjectName input filter
     * @param returnFields input filter
     * @param queryFields input filter
     * @param limitRows number of rows to return
     *
     * @return query string
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    @TestVisible
    private static String buildQuery(String sObjectName, List<String> returnFields, String queryFields, Integer limitRows) {
        String sQuery = 'SELECT ';
        if (returnFields != null && returnFields.size() > 0) {
            sQuery += String.join(returnFields, ',');
        }
        sQuery += ' FROM ' + sObjectName + ' WHERE ';


        String likeField = '';
        for (FilterValue filterValueItem : (List<FilterValue>) JSON.deserialize(queryFields, List<FilterValue>.class)) {
            System.debug(filterValueItem);
            likeField += ' AND ' + filterValueItem.soqlName + populateOperand(filterValueItem.operand) +
                    populateFilterCondition(filterValueItem, sObjectName) + ' ';
        }
        sQuery += ' (' + likeField.removeStart(' AND ') + ')';
        if (limitRows != null) {
            sQuery += ' LIMIT ' + limitRows;
        }

        System.debug(sQuery);
        return sQuery;
    }

    /**
     * @description add filter condition based on type, either add apostrophes or dont
     *
     * @param filterValue - filter settings
     * @param sObjectName base object
     *
     * @return string with correct representation for value and type
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    @TestVisible
    private static String populateFilterCondition(FilterValue filterValue, String sObjectName) {
        if (filterValue.type == 'Date') {
            return addTimeValueToDateIfComparedToDatetimeField(filterValue, sObjectName);
        } else if (filterValue.type == 'Integer') {
            return filterValue.value;
        } else if (filterValue.type == 'Picklist') {
            return '\'' + filterValue.value + '\'';
        } else {
            throw  new IllegalArgumentException('An unknown data type submitted: ' + filterValue.type);
        }
    }

    /**
     * @description translates operand to something SOQL can use
     *
     * @param operand text value of operand
     *
     * @return translated operand
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    @TestVisible
    private static String populateOperand(String operand) {
        switch on operand {
            when 'equals' {
                return ' = ';
            }
            when 'equalGreater' {
                return ' >= ';
            }
            when 'equalSmaller' {
                return ' <= ';
            }
            when else {
                throw  new IllegalArgumentException('An unknown operand has been submitted: ' + operand);
            }
        }
    }

    @TestVisible
    private static String addTimeValueToDateIfComparedToDatetimeField(FilterValue filterValue, String sObjectName) {
        String fieldTypeInSF = getFilterFieldSfDataType(filterValue, sObjectName);
        if (fieldTypeInSF == 'DATETIME') {
            return filterValue.value + 'T00:00:00Z';
        } else {
            return filterValue.value;
        }
    }

    @TestVisible
    private static String getFilterFieldSfDataType(FilterValue filterValue, String sObjectName) {
        List<String> parsedSoqlName = filterValue.soqlName.split('\\.');
        String fieldName = parsedSoqlName[parsedSoqlName.size()-1];
        String sObjectNameActual;
        if (parsedSoqlName.size() == 1) {
            sObjectNameActual = sObjectName;
        } else {
            String possibleSobjectName = sObjectName;
            for (Integer i = 0; i < parsedSoqlName.size() - 1; i++) {
                String fieldNameConverted;
                if (parsedSoqlName[i].contains('__r')) {
                    fieldNameConverted = parsedSoqlName[i].replace('__r', '__c');
                } else {
                    fieldNameConverted = parsedSoqlName[i];
                }
                Schema.DescribeFieldResult schema = DescriptionSobjectService.getSobjectDescribe(fieldNameConverted, possibleSobjectName);
                possibleSobjectName = schema.getReferenceTo()[0].getDescribe().getName();
            }
            sObjectNameActual = possibleSobjectName;
        }

        return DescriptionSobjectService.getFieldDataType(fieldName, sObjectNameActual);
    }

    /**
     * @description class with definition of object received for each filter field from LWC
     *
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    @TestVisible
    private class FilterValue {
        @TestVisible private String soqlName;
        @TestVisible private String value;
        @TestVisible private String type;
        @TestVisible private String operand;
    }
}