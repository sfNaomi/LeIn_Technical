/**
 * Class provides functionality for creating default Assortment in test methods.
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
public class TdfAforzaAssortmentTemplate extends TdfSObjectTemplate {
    private Id recordTypeId;
    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Magdalena Stanciu
     * @date    2022-09-14
     *
     */
    public override void init() {
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return assortment template with default values
     *
     * @author  Magdalena Stanciu
     * @date    2022-09-14
     *
     */
    protected override SObject createTemplateSObject() {
        aforza__Assortment__c template = new aforza__Assortment__c();
        template.Name = 'Test Assortment';
        template.RecordTypeId = recordTypeId;
        return template;
    }
}