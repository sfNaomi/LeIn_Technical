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
public with sharing class TdfContactTemplate extends TdfSObjectTemplate {
    private Id accountId;

    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Svata Sejkoda
     * @date    2022-06-02
     *
     */
    public override void init() {
        Contact userDefinedContact = (Contact) userDefinedSObject;

        if (userDefinedContact.AccountId == null) {
            accountId = TdfSObjectFactory.insertSObject(new Account()).Id;
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
        Contact template = new Contact(
                FirstName = 'John',
                LastName = 'Smith',
                AccountId = accountId,
                Email = 'testcontactemail@wubwub.com'
        );

        return template;
    }
}
