/**
 * Class provides functionality for creating default content version in test methods.
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
public with sharing class TdfContentVersionTemplate extends TdfSObjectTemplate {

    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Magdalena Stanciu
     * @date    2022-10-27
     *
     */
    public override void init() {
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return template with content version record
     *
     * @author  Magdalena Stanciu
     * @date    2022-10-27
     */
    protected override SObject createTemplateSObject() {
        ContentVersion template = new ContentVersion();
        template.VersionData = Blob.valueOf('Test');
        template.Title = 'Content Note';
        template.PathOnClient = 'SampleTitle.jpg';
        template.Origin = 'H';
        return template;
    }
}