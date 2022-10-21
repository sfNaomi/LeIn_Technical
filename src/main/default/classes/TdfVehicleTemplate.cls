/**
 * Class provides functionality for creating default vehicle in test methods.
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
public with sharing class TdfVehicleTemplate extends TdfSObjectTemplate {
    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Magdalena Stanciu
     * @date    2022-10-15
     *
     */
    public override void init() {
        Vehicle__c userDefinedVehicle = (Vehicle__c) userDefinedSObject;
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return template with vehicle record
     *
     * @author  Magdalena Stanciu
     * @date    2022-10-15
     */
    protected override SObject createTemplateSObject() {
        Vehicle__c template = new Vehicle__c(
                VehicleRegistration__c = 'AA11 AAA',
                AssociatedDepot__c = 'D',
                LoadCapacityWeight__c = 3000,
                LoadLimitCases__c = 100
        );

        return template;
    }
}