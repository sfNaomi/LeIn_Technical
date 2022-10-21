/**
 * Class provides functionality for creating default Invoice in test methods.
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
public class TdfAforzaInvoiceTemplate extends TdfSObjectTemplate {
    private Id accountId;
    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Magdalena Stanciu
     * @date    2022-10-03
     *
     */
    public override void init() {
        aforza__Invoice__c userDefinedInvoice = (aforza__Invoice__c) userDefinedSObject;
        if (userDefinedInvoice.aforza__Account__c == null) {
            accountId = TdfSObjectFactory.insertSObject(new Account(
                    RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID
            )).Id;
        }
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return Invoice template with default values
     *
     * @author  Magdalena Stanciu
     * @date    2022-10-03
     *
     */
    protected override SObject createTemplateSObject() {
        aforza__Invoice__c template = new aforza__Invoice__c();
        template.aforza__Account__c = accountId;
        template.InvoiceType__c = 'Invoice';
        template.aforza__Reference__c = 'Test';
        return template;
    }
}