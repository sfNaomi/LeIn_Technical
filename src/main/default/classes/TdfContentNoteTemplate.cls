/**
 * Class provides functionality for creating default content note in test methods.
 *
 * Do not use this class directly.
 * Class is initialized in TDF_SObjectTemplateFactory and all its functionality is used through TDF_SObjectFactory.
 *
 * @see TdfSObjectFactory
 * @see TdfSObjectTemplate
 * @see TdfSObjectTemplateFactory
 *
 * @author  Magdalena Stanciu
 * @date    2022-10-25
 *
 */
@IsTest
public with sharing class TdfContentNoteTemplate extends TdfSObjectTemplate {

    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Magdalena Stanciu
     * @date    2022-10-25
     *
     */
    public override void init() {
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return template with content note record
     *
     * @author  Magdalena Stanciu
     * @date    2022-10-25
     */
    protected override SObject createTemplateSObject() {
        ContentNote template = new ContentNote();
        template.Content = Blob.valueOf('Test');
        template.Title = 'Content Note';
        return template;
    }
}