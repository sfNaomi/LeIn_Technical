/**
 * Class provides functionality for creating default Account in test methods.
 *
 * Do not use this class directly.
 * Class is initialized in TDF_SObjectTemplateFactory and all its functionality is used through TDF_SObjectFactory.
 *
 * @see TdfSObjectFactory
 * @see TdfSObjectTemplate
 * @see TdfSObjectTemplateFactory
 * @author  Svata Sejkora
 * @date    2021-11-01
 *
 */
@IsTest
public class TdfAccountTemplate extends TdfSObjectTemplate {
    private Id accountRecordTypeId;

    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Svata Sejkora
     * @date    2021-11-01
     *
     */
    public override void init() {
        Account userDefinedAccount = (Account) userDefinedSObject;
        accountRecordTypeId = userDefinedAccount.RecordTypeId;
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return account template with default values
     *
     * @author  Svata Sejkora
     * @date    2021-11-01
     *
     */
    protected override SObject createTemplateSObject() {
        Account template = new Account();
        template.Name = 'Account Name';
        template.BillingCity = 'Best City';
        template.BillingPostalCode = '56789';
        template.BillingStreet = 'Awesome Street 234';
        template.ShippingCity = 'Best City';
        template.ShippingPostalCode = '56789';
        template.ShippingStreet = 'Awesome Street 234';
        template.RecordTypeId = accountRecordTypeId;
        return template;
    }
}
