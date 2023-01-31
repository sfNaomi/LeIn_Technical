/**
 * Created by eddy.ferreira on 09.11.2022.
 */
@IsTest
private with sharing class BtPaymentMethodTriggerHandlerTest {
    @IsTest
    private static void testCreateAforzaPaymentMethodFromBlackthornPaymentMethod() {
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        bt_stripe__Payment_Gateway__c testPaymentGateway = (bt_stripe__Payment_Gateway__c) TdfSObjectFactory.insertSObject(new bt_stripe__Payment_Gateway__c());

        Test.startTest();
        //new Payment Method
        bt_stripe__Payment_Method__c btPaymentMethod = (bt_stripe__Payment_Method__c) TdfSObjectFactory.insertSObject(new bt_stripe__Payment_Method__c(
            RecordTypeId = RecordTypes.BT_PAYMENT_METHOD_CARD_ID,
            bt_stripe__Account__c = dpAccount.Id,
            bt_stripe__Payment_Gateway__c = testPaymentGateway.Id
        ));
        Test.stopTest();

        List<aforza__Payment_Method__c> newAforzaPaymentMethod = [
            SELECT Id, BtPaymentMethod__c
            FROM aforza__Payment_Method__c
            WHERE BtPaymentMethod__c = :btPaymentMethod.Id
        ];
        System.debug(newAforzaPaymentMethod.size());
        System.assertNotEquals(null, newAforzaPaymentMethod[0].Id);
    }

    @IsTest
    private static void testCreatedAforzaPaymentMethodFromBlackthornPaymentMethod_checkMappedFields() {
        // create account
        Account dpAccount = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        bt_stripe__Payment_Gateway__c testPaymentGateway = (bt_stripe__Payment_Gateway__c) TdfSObjectFactory.insertSObject(new bt_stripe__Payment_Gateway__c());

        Test.startTest();
        //new Payment Method
        bt_stripe__Payment_Method__c btPaymentMethod = (bt_stripe__Payment_Method__c) TdfSObjectFactory.insertSObject(new bt_stripe__Payment_Method__c(
            RecordTypeId = RecordTypes.BT_PAYMENT_METHOD_CARD_ID,
            bt_stripe__Account__c = dpAccount.Id,
            bt_stripe__Card_Expiration_Month__c = '12',
            bt_stripe__Card_Expiration_Year__c = '2022',
            bt_stripe__Card_Holder_Name__c = 'John Smith',
            bt_stripe__Brand__c = 'Visa',
            bt_stripe__CVV__c = '123',
            bt_stripe__Payment_Gateway__c = testPaymentGateway.Id
        ));
        Test.stopTest();

        List<aforza__Payment_Method__c> newAforzaPaymentMethod = [
            SELECT Id, RecordTypeId, aforza__Account__c, BtPaymentMethod__c, aforza__Active__c, aforza__Payment_Card_Type__c,
                aforza__Payment_Card_Holder_Name__c, aforza__Payment_Card_Expiration_Month__c, aforza__Payment_Card_Expiration_Year__c
            FROM aforza__Payment_Method__c
            WHERE BtPaymentMethod__c = :btPaymentMethod.Id
        ];
        System.debug(newAforzaPaymentMethod.size());

        System.assertEquals(RecordTypes.PAYMENT_METHOD_CREDIT_CARD_ID, newAforzaPaymentMethod[0].RecordTypeId, 'Expecting a different Record Type Id.');
        System.assertEquals(dpAccount.Id, newAforzaPaymentMethod[0].aforza__Account__c, 'Expecting a different account Id.');
        System.assertEquals(btPaymentMethod.Id, newAforzaPaymentMethod[0].BtPaymentMethod__c, 'Expecting a different bt payment method Id.');
        System.assertEquals(true, newAforzaPaymentMethod[0].aforza__Active__c, 'Expecting this payment method to be active.');
        System.assertEquals('Visa', newAforzaPaymentMethod[0].aforza__Payment_Card_Type__c, 'Expecting a different card brand/type.');
        System.assertEquals('John Smith', newAforzaPaymentMethod[0].aforza__Payment_Card_Holder_Name__c, 'Expecting a different card holder name.');
        System.assertEquals('12', newAforzaPaymentMethod[0].aforza__Payment_Card_Expiration_Month__c, 'Expecting a different card expiration month.');
        System.assertEquals('2022', newAforzaPaymentMethod[0].aforza__Payment_Card_Expiration_Year__c, 'Expecting a different card expiration year.');
    }
}