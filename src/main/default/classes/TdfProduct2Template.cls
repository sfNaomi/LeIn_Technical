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
 * @author  Magdalena Stanciu
 * @date    2022-09-20
 *
 */
@IsTest
public with sharing class TdfProduct2Template extends TdfSObjectTemplate {
    private static Integer counter = 0;

    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Magdalena Stanciu
     * @date    2022-09-20
     *
     */
    public override void init() {
        Product2 userDefinedPricebook = (Product2) userDefinedSObject;
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return template with product record
     *
     * @author  Magdalena Stanciu
     * @date    2022-09-20
     *
     */
    protected override SObject createTemplateSObject() {
        Product2 template = new Product2(
                Name = 'Test Product',
                IsActive = true,
                StockKeepingUnit = 'uniqueSKU' + ++counter,
                ProductCode = 'uniqueCode' + ++counter
        );

        return template;
    }
}