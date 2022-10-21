/**
 * Created by magdalena.stanciu on 14.09.2022.
 */

@IsTest
public with sharing class CommonUtilityTest {
    @IsTest
    public static void testIsMoreThanXWeeksAgo() {
        System.assertEquals(FALSE, CommonUtility.isMoreThanXWeeksAgo(System.today(), 1));
        System.assertEquals(TRUE, CommonUtility.isMoreThanXWeeksAgo(System.today().addDays(-8), 1));
    }

    @IsTest
    public static void testGetFieldMapping() {
        System.assertNotEquals(null, CommonUtility.getFieldMapping('ORDER_TO_INVOICE'));
        System.assertNotEquals(null, CommonUtility.getFieldMapping('ORDER_ITEM_TO_INVOICE_ITEM'));
        System.assertEquals(null, CommonUtility.getFieldMapping('TEST'));
        System.assertEquals(null, CommonUtility.getFieldMapping(null));
    }

    @IsTest
    public static void testPopulateTargetSObjectFromSourceSObjectBasedOnMapping() {
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
    public static void testGetFieldsToQueryFromMapping_NotNullMapping() {
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
    public static void testGetFieldsToQueryFromMapping_NullMapping() {
        Set<String> fields = CommonUtility.getFieldsToQueryFromMapping(null, CommonUtility.QueryFieldType.TARGET);
        System.assertEquals(1, fields.size(), 'Expecting only the id field to be returned');
    }
}