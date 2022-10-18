/**
 * Class provides functionality for creating default inventory in test methods.
 *
 * Do not use this class directly.
 * Class is initialized in TDF_SObjectTemplateFactory and all its functionality is used through TDF_SObjectFactory.
 *
 * @see TdfSObjectFactory
 * @see TdfSObjectTemplate
 * @see TdfSObjectTemplateFactory
 *
 * @author  Magdalena Stanciu
 * @date    2022-10-15
 *
 */
@IsTest
public with sharing class TdfAforzaInventoryTemplate extends TdfSObjectTemplate {
    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Magdalena Stanciu
     * @date    2022-10-15
     *
     */
    public override void init() {
        aforza__Inventory__c userDefinedInventory = (aforza__Inventory__c) userDefinedSObject;
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return template with inventory record
     *
     * @author  Magdalena Stanciu
     * @date    2022-10-15
     */
    protected override SObject createTemplateSObject() {
        aforza__Inventory__c template = new aforza__Inventory__c();
        template.aforza__State__c = 'Test';
        template.aforza__Street__c = 'Test';
        template.Name = 'Test Inventory';
        return template;
    }
}
