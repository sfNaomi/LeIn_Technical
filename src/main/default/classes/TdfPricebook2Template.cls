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
public with sharing class TdfPricebook2Template extends TdfSObjectTemplate {
    public static final Id standardPricebookId {
        get {
            if (standardPricebookId == null) {
                // activate standard pricebook when used first time
                Pricebook2 standardPricebook = new Pricebook2(
                    Id = Test.getStandardPricebookId(),
                    IsActive = true
                );
                update standardPricebook;

                standardPricebookId = standardPricebook.Id;
            }
            return standardPricebookId;
        }
        set;
    }

    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Svata Sejkoda
     * @date    2022-06-02
     *
     */
    public override void init() {
        Pricebook2 userDefinedPricebook = (Pricebook2) userDefinedSObject;
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
        Pricebook2 template = new Pricebook2(
                Name = 'My test pricebook',
                IsActive = true
        );

        return template;
    }
}