/**
 * Class provides functionality for creating default pricebook entry in test methods.
 * Template will ensure that if no product is passed in the template, the new product that is created will be
 * added to the standard pricebook first, before creating an entry in a custom pricebook for it. If product
 * is provided as input, creation of pricebook entries for standard and eventually custom pricebook,
 * should be done outside the template.
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
public with sharing class TdfPricebookEntryTemplate extends TdfSObjectTemplate {
    private Id pricebook2Id;
    private Id product2Id;
    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Magdalena Stanciu
     * @date    2022-09-20
     *
     */
    public override void init() {
        PricebookEntry userDefinedPricebookEntry = (PricebookEntry) userDefinedSObject;
        if (userDefinedPricebookEntry.Product2Id == null) {
            product2Id = TdfSObjectFactory.insertSObject(new Product2()).Id;
            TdfSObjectFactory.insertSObject(
                    new PricebookEntry(Product2Id = product2Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
            );
        }
        if (userDefinedPricebookEntry.Pricebook2Id == null) {
            pricebook2Id = TdfSObjectFactory.insertSObject(new Pricebook2()).Id;
        }
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return template with pricebook entry record
     *
     * @author  Magdalena Stanciu
     * @date    2022-09-20
     *
     */
    protected override SObject createTemplateSObject() {
        PricebookEntry template = new PricebookEntry(
                Pricebook2Id = pricebook2Id,
                Product2Id = product2Id,
                UnitPrice = 10
        );
        return template;
    }
}