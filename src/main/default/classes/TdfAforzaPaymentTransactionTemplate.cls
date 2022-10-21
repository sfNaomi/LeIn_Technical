/**
 * Class provides functionality for creating default Payment Transaction in test methods.
 *
 * Do not use this class directly.
 * Class is initialized in TDF_SObjectTemplateFactory and all its functionality is used through TDF_SObjectFactory.
 *
 * @see TdfSObjectFactory
 * @see TdfSObjectTemplate
 * @see TdfSObjectTemplateFactory
 * @author  Magdalena Stanciu
 * @date    2022-10-03
 *
 */
@IsTest
public class TdfAforzaPaymentTransactionTemplate extends TdfSObjectTemplate {
    private Id accountId;
    private Id orderId;
    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Magdalena Stanciu
     * @date    2022-10-03
     *
     */
    public override void init() {
        aforza__Payment_Transaction__c userDefinedTransaction = (aforza__Payment_Transaction__c) userDefinedSObject;
        if (userDefinedTransaction.aforza__Account__c == null) {
            accountId = TdfSObjectFactory.insertSObject(new Account(
                    RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID
            )).Id;
        }
        if (userDefinedTransaction.OrderNumber__c == null) {
            orderId = TdfSObjectFactory.insertSObject(new Order(
                    RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = accountId
            )).Id;
        }
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return Payment Transaction template with default values
     *
     * @author  Magdalena Stanciu
     * @date    2022-10-03
     *
     */
    protected override SObject createTemplateSObject() {
        aforza__Payment_Transaction__c template = new aforza__Payment_Transaction__c();
        template.aforza__Account__c = accountId;
        template.OrderNumber__c = orderId;
        template.aforza__Amount__c = 100;
        return template;
    }
}