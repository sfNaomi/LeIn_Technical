/**
 * Class provides functionality for creating default inventory product in test methods.
 *
 * Do not use this class directly.
 * Class is initialized in TDF_SObjectTemplateFactory and all its functionality is used through TDF_SObjectFactory.
 *
 * @see TdfSObjectFactory
 * @see TdfSObjectTemplate
 * @see TdfSObjectTemplateFactory
 * @author  Magdalena Stanciu
 * @date    2022-10-15
 *
 */
@IsTest
public with sharing class TdfAforzaInventoryProductTemplate extends TdfSObjectTemplate {
    private Id productId;
    private Id inventoryId;

    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Magdalena Stanciu
     * @date    2022-10-15
     *
     */
    public override void init() {
        aforza__Inventory_Product__c userDefinedInventoryProduct = (aforza__Inventory_Product__c) userDefinedSObject;
        if (userDefinedInventoryProduct.aforza__Product__c == null) {
            productId = ((Product2) TdfSObjectFactory.insertSObject(new Product2())).Id;
        }
        if (userDefinedInventoryProduct.aforza__Inventory__c == null) {
            inventoryId = ((aforza__Inventory__c) TdfSObjectFactory.insertSObject(new aforza__Inventory__c())).Id;
        }
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return Inventory Product template with default values
     *
     * @author  Magdalena Stanciu
     * @date    2022-10-15
     *
     */
    protected override SObject createTemplateSObject() {
        aforza__Inventory_Product__c template = new aforza__Inventory_Product__c();
        template.aforza__Inventory__c = inventoryId;
        template.aforza__Product__c = productId;
        template.PickingLocation__c = 'A1';
        return template;
    }
}