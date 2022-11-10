/**
 * Class provides functionality for creating default audit asset in test methods.
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
public with sharing class TdfAforzaAuditAssetTemplate extends TdfSObjectTemplate {
    private Id auditId;

    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Magdalena Stanciu
     * @date    2022-10-27
     *
     */
    public override void init() {
        aforza__Audit_Asset__c userDefinedAuditAsset = (aforza__Audit_Asset__c) userDefinedSObject;

        if (userDefinedAuditAsset.aforza__Audit__c == null) {
            auditId = TdfSObjectFactory.insertSObject(new aforza__Audit__c()).Id;
        }
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return template with audit asset record
     *
     * @author  Magdalena Stanciu
     * @date    2022-10-27
     */
    protected override SObject createTemplateSObject() {
        aforza__Audit_Asset__c template = new aforza__Audit_Asset__c();
        template.aforza__Name__c = 'Test Audit Asset';
        template.aforza__Audit__c = auditId;
        return template;
    }
}
