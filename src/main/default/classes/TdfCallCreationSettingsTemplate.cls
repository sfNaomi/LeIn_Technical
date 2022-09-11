/**
 * Class provides functionality for creating default Account in test methods.
 *
 * Do not use this class directly.
 * Class is initialized in TDF_SObjectTemplateFactory and all its functionality is used through TDF_SObjectFactory.
 *
 * @see TdfSObjectFactory
 * @see TdfSObjectTemplate
 * @see TdfSObjectTemplateFactory
 * @author  Svata Sejkora
 * @date    2021-11-01
 *
 */
@IsTest
public class TdfCallCreationSettingsTemplate extends TdfSObjectTemplate {

    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Svata Sejkora
     * @date    2021-11-01
     *
     */
    public override void init() {
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return account template with default values
     *
     * @author  Svata Sejkora
     * @date    2021-11-01
     *
     */
    protected override SObject createTemplateSObject() {
        CallCreationSettings__c template = new CallCreationSettings__c();
        template.AllowedStatuses__c = 'Traders, At Risk, Win Back, Lapsed';
        template.CallStatus__c = 'Not Started';
        template.CallType__c = 'Call';
        template.SetupOwnerId = UserInfo.getOrganizationId();

        return template;
    }
}
