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
    private Id orderRecordTypeId;
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
        orderRecordTypeId = userDefinedOrder.RecordTypeId;
        if (userDefinedOrder.AccountId == null) {
            accountId = TdfSObjectFactory.insertSObject(new Account()).Id;
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
        template.RecordTypeId = orderRecordTypeId;
        template.Status = 'Draft';
        template.EffectiveDate = system.today();
        return template;
    }
}
