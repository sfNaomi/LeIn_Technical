/**
 * Class provides functionality for creating default audit in test methods.
 *
 * Do not use this class directly.
 * Class is initialized in TDF_SObjectTemplateFactory and all its functionality is used through TDF_SObjectFactory.
 *
 * @see TdfSObjectFactory
 * @see TdfSObjectTemplate
 * @see TdfSObjectTemplateFactory
 *
 * @author  Magdalena Stanciu
 * @date    2022-10-27
 *
 */
@IsTest
public with sharing class TdfAforzaAuditTemplate extends TdfSObjectTemplate {
    private Id accountId;

    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Magdalena Stanciu
     * @date    2022-10-27
     *
     */
    public override void init() {
        aforza__Audit__c userDefinedAudit = (aforza__Audit__c) userDefinedSObject;

        if (userDefinedAudit.aforza__Account__c == null) {
            accountId = TdfSObjectFactory.insertSObject(new Account()).Id;
        }
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return template with audit record
     *
     * @author  Magdalena Stanciu
     * @date    2022-10-27
     */
    protected override SObject createTemplateSObject() {
        aforza__Audit__c template = new aforza__Audit__c();
        template.aforza__Account__c = accountId;
        template.aforza__Status__c = 'Completed';
        template.aforza__Type__c = 'Stock Check';
        template.aforza__Submitted_Date__c = System.Now().date();
        return template;
    }
}
