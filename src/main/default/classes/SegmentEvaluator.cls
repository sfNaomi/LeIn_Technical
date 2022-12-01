public with sharing class SegmentEvaluator {

    @AuraEnabled(Cacheable=true)
    public static List<Account> displayAccounts(Id recordId, String searchTerm) {
        List<SegmentationRule> segmentRules = getSegmentRules(recordId);
        Set<Id> accountIds = getAccountsForSegment(segmentRules);
        return getAccounts(accountIds, searchTerm);
    }

    @AuraEnabled(Cacheable=true)
    public static List<SegmentationRule> getSegmentRules(Id recordId) {
        String objectType = recordId.getSobjectType().getDescribe().getName();
        Set<String> supportedObjects = new Set<String>{
            'aforza__Visit__c', 'aforza__Promotion__c', 'aforza__Assortment__c'
        };

        List<SegmentationRule> rules = new List<SegmentationRule>();

        String segmentQuery = 'SELECT aforza__Segmentation_Rules__c FROM aforza__Segment__c WHERE Id =';
        String relatedSegmentQuery = 'SELECT aforza__Segmentation_Rules__c, aforza__Target_Segment__r.aforza__Segmentation_Rules__c FROM ';

        if (objectType == 'aforza__Segment__c') {

            aforza__Segment__c segment = Database.query(segmentQuery + '\'' + recordId + '\'');

            String segmentRules = (String) segment.get('aforza__Segmentation_Rules__c');
            System.debug('segmentRules' + segmentRules);

            if (String.isNotBlank(segmentRules)) {
                rules.addAll((List<SegmentationRule>) System.JSON.deserialize(segmentRules, List<SegmentationRule>.class));
            }
        }

        else if (supportedObjects.contains(objectType)) {
            SObject segment = Database.query(relatedSegmentQuery + objectType + ' WHERE Id =' + '\'' + recordId + '\'');
            String objectRules = (String) segment.get('aforza__Segmentation_Rules__c');
            System.debug('objectRules' + objectRules);

            if (String.isNotBlank(objectRules)) {
                rules.addAll((List<SegmentationRule>) System.JSON.deserialize(objectRules, List<SegmentationRule>.class));
            }

            if (segment.getSObject('aforza__Target_Segment__r') != null) {
                String segmentRules = (String) segment.getSObject('aforza__Target_Segment__r').get('aforza__Segmentation_Rules__c');
                System.debug('segmentRules' + segmentRules);
                if (String.isNotBlank(segmentRules)) {
                    rules.addAll((List<SegmentationRule>) System.JSON.deserialize(segmentRules, List<SegmentationRule>.class));
                }
            }
        }
        System.debug(rules);
        return rules;
    }

    public static Set<Id> getAccountsForSegment(List<SegmentationRule> srs) {

        Set<Id> accountIds = new Set<Id>();

        for (Integer i = 0; (i < srs.size() && !(i > 0 && accountIds.isEmpty())); i += 2) {
            String query = 'SELECT Id FROM Account WHERE ' + srs[i].getQuery();

            if (srs.size() > (i + 1)) {
                query += ' AND ' + srs[i + 1].getQuery();
            }

            if (!accountIds.isEmpty()) {
                query += ' AND Id IN :accountIds';
            }
            Map<Id, SObject> accounts = new Map<Id, SObject>(Database.query(query));

            accountIds = accounts.keySet();
        }

        return accountIds;
    }

    public static List<Account> getAccounts(Set<Id> accountIds, String searchTerm) {
        List<String> vals = (List<String>) JSON.deserialize(JSON.serialize(accountIds), List<String>.class);

        List<String> selectFields = new List<String>();
        for (Schema.FieldSetMember f : getFields()) {
            if (f.getType() == Schema.DisplayType.PICKLIST) {
                selectFields.add('ToLabel(' + f.getFieldPath() + ')');
            } else if (f.getType() == Schema.DisplayType.REFERENCE) {
                if (f.getFieldPath().endsWith('__c')) {
                    selectFields.add(f.getFieldPath().replace('__c', '__r') + '.Name');
                } else {
                    selectFields.add(f.getFieldPath().removeEnd('Id') + '.Name');
                }
            } else {
                selectFields.add(f.getFieldPath());
            }
        }

        String query = 'SELECT ' + String.join(selectFields, ', ') +
            ' FROM Account WHERE Id IN' + '(' + '\'' + String.join(vals, '\', \'') + '\')';
        if (searchTerm != null && searchTerm != '') {
            query += ' AND Name LIKE ' + '\'%' + searchTerm + '%\'';
        }

        return Database.query(query);
    }

    public static List<Schema.FieldSetMember> getFields() {
        return SObjectType.Account.fieldSets.SegmentViewerDynamic.getFields();
    }
}