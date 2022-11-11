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
public with sharing class TdfBtStripePaymentMethodTemplate extends TdfSObjectTemplate {

    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Eddy Ferreira
     * @date    2022-11-10
     *
     */
    public override void init() {
        bt_stripe__Payment_Method__c userDefinedPaymentMethod = (bt_stripe__Payment_Method__c) userDefinedSObject;
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
        bt_stripe__Payment_Method__c template = new bt_stripe__Payment_Method__c(
            	RecordTypeId = RecordTypes.BT_PAYMENT_METHOD_CARD_ID,
            	bt_stripe__Card_Expiration_Month__c = '12', 
                bt_stripe__Card_Expiration_Year__c = '2024',
                bt_stripe__Card_Holder_Name__c = 'John Smith',
                bt_stripe__Brand__c = 'Visa',
                bt_stripe__CVV__c = '123',
            	bt_stripe__Billing_Postal_Code__c = '0000111'
        );
        
        return template;
    }
}