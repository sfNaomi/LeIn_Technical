/**
 * Class provides functionality for creating default Account in test methods.
 *
 * Do not use this class directly.
 * Class is initialized in TDF_SObjectTemplateFactory and all its functionality is used through TDF_SObjectFactory.
 *
 * @see TdfSObjectFactory
 * @see TdfSObjectTemplate
 * @see TdfSObjectTemplateFactory
 *
 * @author  Svata Sejkoda
 * @date    2022-06-02
 *
 */
@IsTest
public with sharing class TdfAforzaOutletAssetTemplate extends TdfSObjectTemplate {
    private Id accountId;
    private Id productId;
    private String productName;

    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Svata Sejkoda
     * @date    2022-06-02
     *
     */
    public override void init() {
        aforza__Outlet_Asset__c userDefinedOutletAsset = (aforza__Outlet_Asset__c) userDefinedSObject;

        if (userDefinedOutletAsset.aforza__Account__c == null) {
            accountId = TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)).Id;
        }

        if (userDefinedOutletAsset.aforza__Product__c == null) {
            Product2 product = (Product2) TdfSObjectFactory.insertSObject(new Product2());
            productId = product.Id;
            productName = product.Name;
        }
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return template with contact record
     *
     * @author  Svata Sejkora
     * @date    2021-11-01
     *
     */
    protected override SObject createTemplateSObject() {
        aforza__Outlet_Asset__c template = new aforza__Outlet_Asset__c(
                aforza__Name__c = productName,
                aforza__Product__c = productId,
                aforza__Account__c = accountId,
                aforza__Type__c = 'Product'
        );

        return template;
    }
}
