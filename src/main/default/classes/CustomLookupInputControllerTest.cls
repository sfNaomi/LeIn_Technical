/**
 * @description Test class for CustomLookupInputController class
 *
 * @author Svata Sejkora, BearingPoint
 * @date 2022-10-10
 */
@IsTest
private with sharing class CustomLookupInputControllerTest {

    /**
     * @description Tests if method throw correct exception, when record Id is null.
     *
     * @author Svata Sejkora, BearingPoint
     * @date 2022-10-10
     */
    @IsTest
    private static void testGetInitRecord_RecordDoesNotExist() {
        String sobjectName = 'Account';
        String mainFieldName = 'Name';

        try {
            Test.startTest();
            CustomLookupInputController.getInitRecord(null, sobjectName, mainFieldName);
            System.assert(false);
        } catch (Exception ex) {
            System.assert(ex instanceof AuraHandledException);
        } finally {
            Test.stopTest();
        }
    }

    /**
     * @description Tests if method throw correct exception, when main field is null.
     *
     * @author Svata Sejkora, BearingPoint
     * @date 2022-10-10
     */
    @IsTest
    private static void testGetInitRecord_MainFieldNameDoesNotExist() {
        String sobjectName = 'Account';
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        try {
            Test.startTest();
            CustomLookupInputController.getInitRecord(acc.Id, sobjectName, null);
            System.assert(false);
        } catch (Exception ex) {
            System.assert(ex instanceof AuraHandledException);
        } finally {
            Test.stopTest();
        }
    }

    /**
     * @description Tests if method throw correct exception, when sobject is null.
     *
     * @author Svata Sejkora, BearingPoint
     * @date 2022-10-10
     */
    @IsTest
    private static void testGetInitRecord_SobjectDoesNotExist() {
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        String mainFieldName = 'Name';

        try {
            Test.startTest();
            CustomLookupInputController.getInitRecord(acc.Id, null, mainFieldName);
            System.assert(false);
        } catch (Exception ex) {
            System.assert(ex instanceof AuraHandledException);
        } finally {
            Test.stopTest();
        }
    }

    /**
     * @description Tests if method return records correctly. Not encrypted.
     *
     * @author Svata Sejkora, BearingPoint
     * @date 2022-10-10
     */
    @IsTest
    private static void testGetResults_AllInputDataNotEncrypted() {
        TdfSObjectFactory.insertSObjects(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID), 20);

        String sObjectName = 'Account';
        List<String> returnFields = new List<String>{
                'Name', 'AccountNumber'
        };
        List<String> queryFields = new List<String>{
                'Name'
        };
        String searchText = 'Account';
        Integer maxResults = 10;
        String mainField = 'Name';

        Test.startTest();
        List<Account> accountRecords = (List<Account>) CustomLookupInputController.getResults(sObjectName, returnFields, queryFields, searchText, maxResults, null, mainField);
        Test.stopTest();

        System.assertEquals(maxResults, accountRecords.size());
    }

    @IsTest
    private static void testGetRecentlyViewed() {
        TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));
        String sObjectName = 'Account';
        String lookupFieldName = 'OwnerId';
        List<String> selectFields = new List<String>{
                'Name'
        };

        Test.startTest();
        List<SObject> objects = CustomLookupInputController.getRecentlyViewed(sObjectName, lookupFieldName, selectFields, 0, null);
        Test.stopTest();

        //System.assert(!objects.isEmpty());
    }
}