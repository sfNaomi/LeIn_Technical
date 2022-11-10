/**
 * Class provides functionality for creating default content document link in test methods.
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
public with sharing class TdfContentDocumentLinkTemplate extends TdfSObjectTemplate {
    private Id contentDocumentId;

    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Magdalena Stanciu
     * @date    2022-10-25
     *
     */
    public override void init() {
        ContentDocumentLink docLink = (ContentDocumentLink) userDefinedSObject;

        if (docLink.ContentDocument == null) {
            contentDocumentId = TdfSObjectFactory.insertSObject(new ContentNote()).Id;
        }
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return template with content document link record
     *
     * @author  Magdalena Stanciu
     * @date    2022-10-25
     */
    protected override SObject createTemplateSObject() {
        ContentDocumentLink template = new ContentDocumentLink();
        template.ContentDocumentId = contentDocumentId;
        template.ShareType = 'I';
        return template;
    }
}