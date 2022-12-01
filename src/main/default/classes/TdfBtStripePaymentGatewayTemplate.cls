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
public with sharing class TdfBtStripePaymentGatewayTemplate extends TdfSObjectTemplate {

    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Eddy Ferreira
     * @date    2022-11-10
     *
     */
    public override void init() {
        bt_stripe__Payment_Gateway__c userDefinedPaymentGateway = (bt_stripe__Payment_Gateway__c) userDefinedSObject;
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
        bt_stripe__Payment_Gateway__c template = new bt_stripe__Payment_Gateway__c(
            	Name='Test', 
            	bt_stripe__Provider__c = 'Stripe', 
                bt_stripe__Test_Mode__c = true, 
                bt_stripe__Default__c = true
        );
        
        return template;
    }
}