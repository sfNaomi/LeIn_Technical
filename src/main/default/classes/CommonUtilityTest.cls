/**
 * Created by magdalena.stanciu on 14.09.2022.
 */

@IsTest
private with sharing class CommonUtilityTest {
    @IsTest
    private static void testIsMoreThanXWeeksAgo() {
        System.assertEquals(FALSE, CommonUtility.isMoreThanXWeeksAgo(System.today(), 1));
        System.assertEquals(TRUE, CommonUtility.isMoreThanXWeeksAgo(System.today().addDays(-8), 1));
    }

    @IsTest
    private static void testGetFieldMapping() {
        System.assertNotEquals(null, CommonUtility.getFieldMapping('ORDER_TO_INVOICE'));
        System.assertNotEquals(null, CommonUtility.getFieldMapping('ORDER_ITEM_TO_INVOICE_ITEM'));
        System.assertEquals(null, CommonUtility.getFieldMapping('TEST'));
        System.assertEquals(null, CommonUtility.getFieldMapping(null));
    }

    @IsTest
    private static void testPopulateTargetSObjectFromSourceSObjectBasedOnMapping() {
        FieldMapping__mdt mapping = CommonUtility.getFieldMapping('ORDER_TO_INVOICE');

        // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );

        // create related order
        Order sourceOrder = (Order) TdfSObjectFactory.createSObject(
                new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
        );

        // create Invoice
        aforza__Invoice__c targetInvoice = (aforza__Invoice__c) TdfSObjectFactory.createSObject(
                new aforza__Invoice__c(aforza__Account__c = dpAccount.Id)
        );

        Test.startTest();
        CommonUtility.populateTargetSObjectFromSourceSObjectBasedOnMapping(targetInvoice, sourceOrder, mapping);
        Test.stopTest();

        System.assertEquals(sourceOrder.Id, targetInvoice.aforza__Order__c, 'Expecting invoice to be related to order');
    }

    @IsTest
    private static void testGetFieldsToQueryFromMapping_NotNullMapping() {
        System.assertEquals(
                true,
                CommonUtility.getFieldsToQueryFromMapping(CommonUtility.getFieldMapping('ORDER_TO_INVOICE'), CommonUtility.QueryFieldType.SOURCE).size() > 1,
                'Expecting fields to be returned'
        );
        System.assertEquals(
                true,
                CommonUtility.getFieldsToQueryFromMapping(CommonUtility.getFieldMapping('ORDER_TO_INVOICE'), CommonUtility.QueryFieldType.TARGET).size() > 1,
                'Expecting fields to be returned'
        );
    }

    @IsTest
    private static void testGetFieldsToQueryFromMapping_NullMapping() {
        Set<String> fields = CommonUtility.getFieldsToQueryFromMapping(null, CommonUtility.QueryFieldType.TARGET);
        System.assertEquals(1, fields.size(), 'Expecting only the id field to be returned');
    }

    @IsTest
    private static void testGetUrlMapping() {
        System.assertNotEquals(null, CommonUtility.getUrlMapping('AGENT_MANDATE_FORM'));
        System.assertNotEquals(null, CommonUtility.getUrlMapping('CUSTOMER_MANDATE_FORM'));
        System.assertEquals(null, CommonUtility.getUrlMapping('TEST'));
        System.assertEquals(null, CommonUtility.getUrlMapping(null));
    }
    
    @IsTest
    private static void testUrlMapFieldsToParameterValues() {
        UrlMapping__mdt mapping = CommonUtility.getUrlMapping('AGENT_MANDATE_FORM');

        // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );
            Map <String, String> mapFieldApiToFieldValue = new Map <String, String> ();

        Test.startTest();
        mapFieldApiToFieldValue = CommonUtility.urlMapFieldsToParameterValues(dpAccount, mapping);
        Test.stopTest();

        System.assertNotEquals(null, mapFieldApiToFieldValue, 'Expecting Mapped field returned');
        System.assertEquals('56789', mapFieldApiToFieldValue.get('currentpostcode'));
    }
    
     @IsTest
    private static void testUrlGetFieldsToQuery() {
        System.assertEquals(
                true,
                CommonUtility.urlGetFieldsToQuery(CommonUtility.getUrlMapping('AGENT_MANDATE_FORM')).size() > 1,
                'Expecting fields to be returned'
        );
        System.assertEquals(
                true,
                CommonUtility.urlGetFieldsToQuery(CommonUtility.getUrlMapping('CUSTOMER_MANDATE_FORM')).size() > 1,
                'Expecting fields to be returned'
        );
    }
	
    @IsTest
    private static void testCreateUrlMethod() {
        UrlMapping__mdt mapping = CommonUtility.getUrlMapping('AGENT_MANDATE_FORM');

        String returnedUrl ='';
        // create dp account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
                new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
        );

        Test.startTest();
        returnedUrl = CommonUtility.createUrlMethod(dpAccount, mapping);
        Test.stopTest();
        system.debug(returnedUrl.right(0));
        System.assertEquals(FALSE, String.isBlank(returnedUrl));
        System.assertEquals(FALSE, returnedUrl.right(0) == '&');
    }

    @IsTest
    private static void testGenerateUniqueIdentifier() {
        String referenceString = 'Test';
        Integer length = 18;

        Test.startTest();
        string uid = CommonUtility.generateUniqueIdentifier(referenceString, length);
        Test.stopTest();

        Assert.isNotNull(uid);
        Assert.areEqual(length, uid.length());
    }
}
