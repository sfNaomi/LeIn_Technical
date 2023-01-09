/**
 * Class provides functionality for creating default load in test methods.
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
public with sharing class TdfLoadTemplate extends TdfSObjectTemplate {
    private Id vehicleId;

    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Magdalena Stanciu
     * @date    2022-10-15
     *
     */
    public override void init() {
        Load__c userDefinedLoad = (Load__c) userDefinedSObject;
        if (userDefinedLoad.Vehicle__c == null) {
            vehicleId = ((Vehicle__c) TdfSObjectFactory.insertSObject(new Vehicle__c())).Id;
        }
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return template with load record
     *
     * @author  Magdalena Stanciu
     * @date    2022-10-15
     */
    protected override SObject createTemplateSObject() {
        Load__c template = new Load__c(
            DeliveryDate__c = System.today(),
            Driver__c = UserInfo.getUserId(),
            Vehicle__c = vehicleId,
            Depot__c = 'M'
        );

        return template;
    }
}