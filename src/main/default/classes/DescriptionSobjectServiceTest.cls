/**
 * Created by svatopluk.sejkora on 27.09.2022.
 */

@IsTest
private class DescriptionSobjectServiceTest {
    @IsTest
    static void testGetSobjectDescribe() {
        String fieldName = 'ClosedDate__c';
        String sObjectName = 'Account';

        Test.startTest();
        Schema.DescribeFieldResult result = DescriptionSobjectService.getSobjectDescribe(fieldName, sObjectName);
        Test.stopTest();

        System.assertEquals('DATE', String.valueOf(result.getSoapType()));
    }

    @IsTest
    static void testGetFieldDataType() {
        String fieldName = 'ClosedDate__c';
        String sObjectName = 'Account';

        Test.startTest();
        String result = DescriptionSobjectService.getFieldDataType(fieldName, sObjectName);
        Test.stopTest();

        System.assertEquals('DATE', result);
    }

    @IsTest
    static void testGetPicklistEntries() {
        String fieldName = 'Rating';
        String sObjectName = 'Account';

        Test.startTest();
        List<PicklistEntry> result = DescriptionSobjectService.getPicklistEntries(fieldName, sObjectName);
        Test.stopTest();

        System.assertEquals(false, result.isEmpty());
    }
}