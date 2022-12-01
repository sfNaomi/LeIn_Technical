/**
 * Class provides functionality for creating default product in test methods.
 *
 * Do not use this class directly.
 * Class is initialized in TDF_SObjectTemplateFactory and all its functionality is used through TDF_SObjectFactory.
 *
 * @see TdfSObjectFactory
 * @see TdfSObjectTemplate
 * @see TdfSObjectTemplateFactory
 *
 * @author  Eddy Ferreira
 * @date    2022-11-10
 *
 */
@IsTest
public with sharing class TdfBtStripeTransactionTemplate extends TdfSObjectTemplate {
    private Id orderId;
    private Id accountId;

    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Svata Sejkora
     * @date    2022-11-14
     *
     */
    public override void init() {
        bt_stripe__Transaction__c userDefinedTransaction = (bt_stripe__Transaction__c) userDefinedSObject;

        if (userDefinedTransaction.Order__c == null) {
            orderId = TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID)).Id;
        }

        if (userDefinedTransaction.bt_stripe__Account_Name__c == null) {
            accountId = TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)).Id;
        }
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return template with product record
     *
     * @author  Eddy Ferreira
     * @date    2022-11-10
     *
     */
    protected override SObject createTemplateSObject() {
        bt_stripe__Transaction__c template = new bt_stripe__Transaction__c(
            Order__c = orderId,
            bt_stripe__Payment_Status__c = 'Authorized',
            bt_stripe__Related_Account__c = accountId,
            bt_stripe__Amount__c = 340,
            bt_stripe__Processed_Date__c = System.now()
        );

        return template;
    }
}