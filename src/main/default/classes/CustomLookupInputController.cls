/**
 * @description Controller for component that mimics lightning input for lookup and allows more customizations,
 * provides records selecting.
 *
 * @author Svatopluk Sejkora, BearingPoint
 * @date 2022-10-08
 */
public with sharing class CustomLookupInputController {

    /**
     * @description Fetches record based on Id and SObjectName
     *
     * @param recordId input filter
     * @param sObjectName input filter
     * @param mainField input filter
     *
     * @return SObject with corresponding Id and Type
     *
     * @author Svatopluk Sejkora, BearingPoint
     * @date 2022-10-08
     */
    @AuraEnabled
    public static SObject getInitRecord(Id recordId, String sObjectName, String mainField) {
        try {
            String query = 'SELECT Id, ' + mainField + ' FROM ' + sObjectName + ' WHERE Id = \'' + recordId + '\'';
            List<SObject> records = Database.query(query);
            return records.isEmpty() ? null : records[0];
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Fetches records based on searchText and SObjectName
     *
     * @param sObjectName input filter
     * @param returnFields input filter
     * @param queryFields input filter
     * @param searchText input filter
     * @param maxResults input filter
     * @param filter input filter
     * @param mainField input filter
     *
     * @return List of SObjects which contains searchText in one of queryFields
     *
     * @author Svatopluk Sejkora, BearingPoint
     * @date 2022-10-08
     */
    @AuraEnabled
    public static List<SObject> getResults(String sObjectName, List<String> returnFields, List<String> queryFields,
            String searchText, Integer maxResults, String filter, String mainField) {
        try {
            String sQuery = buildQuery(sObjectName, returnFields, queryFields, searchText, maxResults, filter, mainField);
            return Database.query(sQuery);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description build a complete query.
     *
     * @param sObjectName input filter
     * @param returnFields input filter
     * @param queryFields input filter
     * @param searchText input filter
     * @param maxResults input filter
     * @param filter input filter
     * @param mainField input filter
     *
     * @return query string
     *
     * @author Svatopluk Sejkora, BearingPoint
     * @date 2022-10-08
     */
    private static String buildQuery(String sObjectName, List<String> returnFields, List<String> queryFields,
            String searchText, Integer maxResults, String filter, String mainField) {
        //always put a limit on the results
        if (maxResults == null || maxResults <= 0) {
            maxResults = 5;
        }
        searchText = '%' + searchText + '%';
        String sQuery = 'SELECT Id, ';
        if (returnFields != null && returnFields.size() > 0) {
            sQuery += String.join(returnFields, ',');
        } else {
            sQuery += mainField;
        }
        sQuery += ' FROM ' + sObjectName + ' WHERE ';
        if (queryFields == null || queryFields.isEmpty()) {
            sQuery += ' ' + mainField + ' LIKE \'' + searchText + '\' ';
        } else {
            String likeField = '';
            for (String field : queryFields) {
                likeField += ' OR ' + field + ' LIKE \'' + searchText + '\' ';
            }
            sQuery += ' (' + likeField.removeStart(' OR ') + ') ';
        }
        if (String.isNotBlank(filter)) {
            sQuery += ' AND ' + filter;
        }

        sQuery += ' LIMIT ' + maxResults;
        return sQuery;
    }

    /**
     * @description Fetches records from recently viewed
     *
     * @param sObjectName input filter
     * @param mainField input filter
     * @param returnFields input filter
     * @param maxResults input filter
     * @param filter input filter
     *
     * @return List of SObjects which contains searchText in one of queryFields
     *
     * @author Svatopluk Sejkora, BearingPoint
     * @date 2022-10-08
     */
    @AuraEnabled
    public static List<SObject> getRecentlyViewed(String sObjectName, String mainField, List<String> returnFields,
            Integer maxResults, String filter) {
        try {
            String sQuery = buildRecentlyViewedQuery(sObjectName, mainField, returnFields, maxResults, filter);
            return Database.query(sQuery);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description build a complete 'recently viewed' query.
     *
     * @param sObjectName input filter
     * @param mainField input filter
     * @param returnFields input filter
     * @param maxResults input filter
     * @param filter input filter
     *
     * @return query string
     *
     * @author Svatopluk Sejkora, BearingPoint
     * @date 2022-10-08
     */
    private static String buildRecentlyViewedQuery(String sObjectName, String mainField, List<String> returnFields, Integer maxResults, String filter) {
        if (maxResults == null || maxResults <= 0) {
            maxResults = 5;
        }
        String sQuery = 'SELECT Id, ';
        if (returnFields != null && returnFields.size() > 0) {
            sQuery += String.join(returnFields, ',');
        } else {
            sQuery += mainField;
        }

        sQuery += ' FROM ' + sObjectName;
        if (String.isNotBlank(filter)) {
            sQuery += ' WHERE ' + filter;
        }

        sQuery += ' ORDER BY LastViewedDate DESC LIMIT ' + maxResults;

        return sQuery;
    }
}