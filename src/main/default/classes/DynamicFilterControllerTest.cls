/**
 * Created by svatopluk.sejkora on 26.09.2022.
 */

@IsTest
private class DynamicFilterControllerTest {
    @IsTest
    private static void testPopulateOperand_Equals() {
        String operand = 'equals';

        Test.startTest();
        String returnedOperand = DynamicFilterController.populateOperand(operand);
        Test.stopTest();

        System.assertEquals(' = ', returnedOperand, 'We expect = for equals to be returned');
    }

    @IsTest
    private static void testPopulateOperand_EqualGreater() {
        String operand = 'equalGreater';

        Test.startTest();
        String returnedOperand = DynamicFilterController.populateOperand(operand);
        Test.stopTest();

        System.assertEquals(' >= ', returnedOperand, 'We expect >= for equalGreater to be returned');
    }

    @IsTest
    private static void testPopulateOperand_EqualSmaller() {
        String operand = 'equalSmaller';

        Test.startTest();
        String returnedOperand = DynamicFilterController.populateOperand(operand);
        Test.stopTest();

        System.assertEquals(' <= ', returnedOperand, 'We expect <= for equalSmaller to be returned');
    }

    @IsTest
    private static void testPopulateOperand_UnknownOperand() {
        String operand = 'aaa';

        Test.startTest();
        try {
            DynamicFilterController.populateOperand(operand);
            System.assert(false, 'An exception should have been thrown here.');
        } catch (Exception e) {
            System.assertEquals('System.IllegalArgumentException', e.getTypeName());
            System.assertEquals('An unknown operand has been submitted: aaa', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    private static void testPopulateFilterCondition_Date() {
        DynamicFilterController.FilterValue filterValue = new DynamicFilterController.FilterValue();
        filterValue.value = JSON.serialize(System.today());
        filterValue.type = 'Date';
        filterValue.soqlName = 'aforza__Planned_Time__c';

        Test.startTest();
        String populatedValue = DynamicFilterController.populateFilterCondition(filterValue, 'aforza__Visit__c');
        Test.stopTest();

        System.assertEquals(filterValue.value + 'T00:00:00Z', populatedValue, 'We expect to get the same value as we sent in');
    }

    @IsTest
    private static void testPopulateFilterCondition_Integer() {
        DynamicFilterController.FilterValue filterValue = new DynamicFilterController.FilterValue();
        filterValue.value = String.valueOf(90);
        filterValue.type = 'Integer';

        Test.startTest();
        String populatedValue = DynamicFilterController.populateFilterCondition(filterValue, 'aforza__Visit__c');
        Test.stopTest();

        System.assertEquals(filterValue.value, populatedValue, 'We expect to get the same value as we sent in');
    }

    @IsTest
    private static void testPopulateFilterCondition_Picklist() {
        DynamicFilterController.FilterValue filterValue = new DynamicFilterController.FilterValue();
        filterValue.value = 'Picklist Value';
        filterValue.type = 'Picklist';

        Test.startTest();
        String populatedValue = DynamicFilterController.populateFilterCondition(filterValue, 'aforza__Visit__c');
        Test.stopTest();

        System.assertEquals('\'' + filterValue.value + '\'', populatedValue, 'We expect to get the value surrounded with apostrophes');
    }

    @IsTest
    private static void testPopulateOperand_UnknownDataType() {
        DynamicFilterController.FilterValue filterValue = new DynamicFilterController.FilterValue();
        filterValue.type = 'aaa';
        filterValue.value = 'Picklist Value';

        Test.startTest();
        try {
            DynamicFilterController.populateFilterCondition(filterValue, 'aforza__Visit__c');
            System.assert(false, 'An exception should have been thrown here.');
        } catch (Exception e) {
            System.assertEquals('System.IllegalArgumentException', e.getTypeName());
            System.assertEquals('An unknown data type submitted: aaa', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    private static void testBuildQuery() {
        // prepare filter definition object
        DynamicFilterController.FilterValue filter = new DynamicFilterController.FilterValue();
        filter.value = 'P2';
        filter.type = 'Picklist';
        filter.operand = 'equals';
        filter.soqlName = 'aforza__Account__r.CallPriority__c';

        List<DynamicFilterController.FilterValue> filterFieldsList = new List<DynamicFilterController.FilterValue>();
        filterFieldsList.add(filter);

        String filterFields = JSON.serialize(filterFieldsList);

        String queryFields = 'Id, aforza__Status__c,aforza__Planned_Time__c,aforza__Account__r.Owner.LastName,aforza__Owner__r.LastName,' +
                'aforza__Account__r.StoreName__c,aforza__Account__r.BillingPostalCode,aforza__Account__r.DeliveryPointReference__c,' +
                'aforza__Account__r.PrimaryGridNumber__c,aforza__Account__r.SecondaryGridNumber__c,' +
                'toLabel(aforza__Account__r.Depot__c),aforza__Account__r.CreditStatus__c,aforza__Account__r.CallPriority__c,aforza__Account__r.TradingFrequencyBucketed__c';
        List<String> queryList = queryFields.split(',');

        Test.startTest();
        String query = DynamicFilterController.buildQuery('aforza__Visit__c', queryList, filterFields, 900);
        Test.stopTest();

        String expectedQuery = 'SELECT Id, aforza__Status__c,aforza__Planned_Time__c,aforza__Account__r.Owner.LastName,' +
                'aforza__Owner__r.LastName,aforza__Account__r.StoreName__c,aforza__Account__r.BillingPostalCode,aforza__Account__r.DeliveryPointReference__c,' +
                'aforza__Account__r.PrimaryGridNumber__c,aforza__Account__r.SecondaryGridNumber__c,toLabel(aforza__Account__r.Depot__c),' +
                'aforza__Account__r.CreditStatus__c,aforza__Account__r.CallPriority__c,aforza__Account__r.TradingFrequencyBucketed__c ' +
                'FROM aforza__Visit__c WHERE  (aforza__Account__r.CallPriority__c = \'P2\' ) LIMIT 900';
        System.assertEquals(expectedQuery, query);
    }

    @IsTest
    private static void testBuildQuery_MultipleFilters() {
        // prepare filter definition object
        List<DynamicFilterController.FilterValue> filterFieldsList = new List<DynamicFilterController.FilterValue>();
        DynamicFilterController.FilterValue filter = new DynamicFilterController.FilterValue();
        filter.value = 'P2';
        filter.type = 'Picklist';
        filter.operand = 'equals';
        filter.soqlName = 'aforza__Account__r.CallPriority__c';
        filterFieldsList.add(filter);

        DynamicFilterController.FilterValue filter2 = new DynamicFilterController.FilterValue();
        filter2.value = '14-20';
        filter2.type = 'Picklist';
        filter2.operand = 'equals';
        filter2.soqlName = 'aforza__Account__r.TradingFrequencyBucketed__c';
        filterFieldsList.add(filter2);

        String filterFields = JSON.serialize(filterFieldsList);

        String queryFields = 'Id, aforza__Status__c,aforza__Planned_Time__c,aforza__Account__r.Owner.LastName,aforza__Owner__r.LastName,' +
                'aforza__Account__r.StoreName__c,aforza__Account__r.BillingPostalCode,aforza__Account__r.DeliveryPointReference__c,' +
                'aforza__Account__r.PrimaryGridNumber__c,aforza__Account__r.SecondaryGridNumber__c,' +
                'toLabel(aforza__Account__r.Depot__c),aforza__Account__r.CreditStatus__c,aforza__Account__r.CallPriority__c,aforza__Account__r.TradingFrequencyBucketed__c';
        List<String> queryList = queryFields.split(',');

        Test.startTest();
        String query = DynamicFilterController.buildQuery('aforza__Visit__c', queryList, filterFields, 900);
        Test.stopTest();

        System.debug(query);
        String expectedQuery = 'SELECT Id, aforza__Status__c,aforza__Planned_Time__c,aforza__Account__r.Owner.LastName,' +
                'aforza__Owner__r.LastName,aforza__Account__r.StoreName__c,aforza__Account__r.BillingPostalCode,' +
                'aforza__Account__r.DeliveryPointReference__c,aforza__Account__r.PrimaryGridNumber__c,' +
                'aforza__Account__r.SecondaryGridNumber__c,toLabel(aforza__Account__r.Depot__c),' +
                'aforza__Account__r.CreditStatus__c,aforza__Account__r.CallPriority__c,aforza__Account__r.TradingFrequencyBucketed__c ' +
                'FROM aforza__Visit__c WHERE  (aforza__Account__r.CallPriority__c = \'P2\'  AND aforza__Account__r.TradingFrequencyBucketed__c = \'14-20\' ) LIMIT 900';
        System.assertEquals(expectedQuery, query);

    }

    @IsTest
    private static void testGetResult() {
        // get some visits
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        List<aforza__Recurring_Record__c> recurringRecords = [SELECT Id FROM aforza__Recurring_Record__c WHERE Account__c = :acc.Id LIMIT 1];
        System.assert(recurringRecords.size() == 1);

        TdfSObjectFactory.insertSObjects(new aforza__Visit__c(aforza__Account__c = acc.Id, aforza__Recurring_Record__c = recurringRecords[0].Id,
                RecordTypeId = RecordTypes.VISIT_REMOTE_VISIT_ID), 20);

        // prepare filter definition object
        List<DynamicFilterController.FilterValue> filterFieldsList = new List<DynamicFilterController.FilterValue>();
        DynamicFilterController.FilterValue filter = new DynamicFilterController.FilterValue();
        filter.value = 'P2';
        filter.type = 'Picklist';
        filter.operand = 'equals';
        filter.soqlName = 'aforza__Account__r.CallPriority__c';
        filterFieldsList.add(filter);

        DynamicFilterController.FilterValue filter2 = new DynamicFilterController.FilterValue();
        filter2.value = '0-4';
        filter2.type = 'Picklist';
        filter2.operand = 'equals';
        filter2.soqlName = 'aforza__Account__r.TradingFrequencyBucketed__c';
        filterFieldsList.add(filter2);

        String filterFields = JSON.serialize(filterFieldsList);

        String queryFields = 'Id, aforza__Status__c,aforza__Planned_Time__c,aforza__Account__r.Owner.LastName,aforza__Owner__r.LastName,' +
                'aforza__Account__r.StoreName__c,aforza__Account__r.BillingPostalCode,aforza__Account__r.DeliveryPointReference__c,' +
                'aforza__Account__r.PrimaryGridNumber__c,aforza__Account__r.SecondaryGridNumber__c,' +
                'toLabel(aforza__Account__r.Depot__c),aforza__Account__r.CreditStatus__c,aforza__Account__r.CallPriority__c,aforza__Account__r.TradingFrequencyBucketed__c';
        List<String> queryList = queryFields.split(',');

        Test.startTest();
        List<SObject> records = DynamicFilterController.getResults('aforza__Visit__c', queryList, filterFields, 40);
        Test.stopTest();

        System.assertEquals(20, records.size());
    }

    @IsTest
    private static void testGetResult_NoData() {
        // get some visits
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        List<aforza__Recurring_Record__c> recurringRecords = [SELECT Id FROM aforza__Recurring_Record__c WHERE Account__c = :acc.Id LIMIT 1];
        System.assert(recurringRecords.size() == 1);

        TdfSObjectFactory.insertSObjects(new aforza__Visit__c(aforza__Account__c = acc.Id, aforza__Recurring_Record__c = recurringRecords[0].Id,
                RecordTypeId = RecordTypes.VISIT_REMOTE_VISIT_ID), 20);

        // prepare filter definition object
        List<DynamicFilterController.FilterValue> filterFieldsList = new List<DynamicFilterController.FilterValue>();
        DynamicFilterController.FilterValue filter = new DynamicFilterController.FilterValue();
        filter.value = 'P3';
        filter.type = 'Picklist';
        filter.operand = 'equals';
        filter.soqlName = 'aforza__Account__r.CallPriority__c';
        filterFieldsList.add(filter);

        DynamicFilterController.FilterValue filter2 = new DynamicFilterController.FilterValue();
        filter2.value = '0-4';
        filter2.type = 'Picklist';
        filter2.operand = 'equals';
        filter2.soqlName = 'aforza__Account__r.TradingFrequencyBucketed__c';
        filterFieldsList.add(filter2);

        String filterFields = JSON.serialize(filterFieldsList);

        String queryFields = 'Id, aforza__Status__c,aforza__Planned_Time__c,aforza__Account__r.Owner.LastName,aforza__Owner__r.LastName,' +
                'aforza__Account__r.StoreName__c,aforza__Account__r.BillingPostalCode,aforza__Account__r.DeliveryPointReference__c,' +
                'aforza__Account__r.PrimaryGridNumber__c,aforza__Account__r.SecondaryGridNumber__c,' +
                'toLabel(aforza__Account__r.Depot__c),aforza__Account__r.CreditStatus__c,aforza__Account__r.CallPriority__c,aforza__Account__r.TradingFrequencyBucketed__c';
        List<String> queryList = queryFields.split(',');

        Test.startTest();
        List<SObject> records = DynamicFilterController.getResults('aforza__Visit__c', queryList, filterFields, 40);
        Test.stopTest();

        System.assertEquals(0, records.size());
    }

    @IsTest
    private static void testGetResult_Exception() {
        Test.startTest();
        try {
            DynamicFilterController.getResults(null, null, null, 40);
            System.assert(false);
        } catch (Exception e) {
            System.assertEquals('System.AuraHandledException', e.getTypeName());
            System.assertEquals('null input to JSON parser', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    private static void testGetFilterFieldSfDataType() {
        DynamicFilterController.FilterValue filter = new DynamicFilterController.FilterValue();
        filter.soqlName = 'aforza__Account__r.CreatedDate';

        Test.startTest();
        String fieldType = DynamicFilterController.getFilterFieldSfDataType(filter, 'aforza__Visit__c');
        Test.stopTest();

        System.assertEquals('DATETIME', fieldType);
    }

    @IsTest
    private static void testGetFilterFieldSfDataType_Date() {
        DynamicFilterController.FilterValue filter = new DynamicFilterController.FilterValue();
        filter.soqlName = 'aforza__Account__r.ClosedDate__c';

        Test.startTest();
        String fieldType = DynamicFilterController.getFilterFieldSfDataType(filter, 'aforza__Visit__c');
        Test.stopTest();

        System.assertEquals('DATE', fieldType);
    }
}