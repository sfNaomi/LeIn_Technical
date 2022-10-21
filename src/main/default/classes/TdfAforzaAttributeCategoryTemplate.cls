/**
 * Class provides functionality for creating default Assortment Product in test methods.
 *
 * Do not use this class directly.
 * Class is initialized in TDF_SObjectTemplateFactory and all its functionality is used through TDF_SObjectFactory.
 *
 * @see TdfSObjectFactory
 * @see TdfSObjectTemplate
 * @see TdfSObjectTemplateFactory
 * @author  Svata Sejkora
 * @date    2022-10-05
 *
 */

public with sharing class TdfAforzaAttributeCategoryTemplate extends TdfSObjectTemplate {
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
     * @return assortment product template with default values
     *
     * @author  Magdalena Stanciu
     * @date    2022-09-14
     *
     */
    protected override SObject createTemplateSObject() {
        aforza__Attribute_Category__c template = new aforza__Attribute_Category__c();
        template.Name = 'Non Stockist';
        template.aforza__Code__c = 'NonStockis';
        template.aforza__Type__c = 'Account';
        return template;
    }
}