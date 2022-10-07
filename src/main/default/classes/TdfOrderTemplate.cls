/**
 * Class provides functionality for creating default Order in test methods.
 *
 * Do not use this class directly.
 * Class is initialized in TDF_SObjectTemplateFactory and all its functionality is used through TDF_SObjectFactory.
 *
 * @see TdfSObjectFactory
 * @see TdfSObjectTemplate
 * @see TdfSObjectTemplateFactory
 * @author  Magdalena Stanciu
 * @date    2022-09-14
 *
 */
@IsTest
public class TdfOrderTemplate extends TdfSObjectTemplate {
    private Id accountId;

    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Magdalena Stanciu
     * @date    2022-09-14
     *
     */
    public override void init() {
        Order userDefinedOrder = (Order) userDefinedSObject;
        if (userDefinedOrder.AccountId == null) {
            accountId = TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')).Id;
        }
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return order template with default values
     *
     * @author  Magdalena Stanciu
     * @date    2022-09-14
     *
     */
    protected override SObject createTemplateSObject() {
        Order template = new Order();
        template.Name = 'Order Name';
        template.RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID;
        template.Status = 'Draft';
        template.EffectiveDate = System.today();
        template.Pricebook2Id = TdfPricebook2Template.standardPricebookId;
        template.AccountId = accountId;
        return template;
    }
}