/**
 * Class provides functionality for creating default Assortment Product in test methods.
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
public class TdfAforzaAssortmentProductTemplate extends TdfSObjectTemplate {
    private Id assortmentId;
    private Id product2Id;
    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Magdalena Stanciu
     * @date    2022-09-14
     *
     */
    public override void init() {
        aforza__Assortment_Product__c userDefinedOrder = (aforza__Assortment_Product__c) userDefinedSObject;
        if (userDefinedOrder.aforza__Assortment__c == null) {
            assortmentId = TdfSObjectFactory.insertSObject(new aforza__Assortment__c(
                    RecordTypeId = RecordTypes.ASSORTMENT_SEGMENT_ASSORTMENT_ID
            )).Id;
        }
        if (userDefinedOrder.aforza__Product__c == null) {
            product2Id = TdfSObjectFactory.insertSObject(new Product2()).Id;
        }
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
        aforza__Assortment_Product__c template = new aforza__Assortment_Product__c();
        template.aforza__Assortment__c = assortmentId;
        template.aforza__Product__c = product2Id;
        return template;
    }
}