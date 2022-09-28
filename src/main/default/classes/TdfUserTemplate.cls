/**
 * Class provides functionality for creating default Event in test methods.
 *
 * Do not use this class directly.
 * Class is initialized in TDF_SObjectTemplateFactory and all its functionality is used through TDF_SObjectFactory.
 *
 * @see TdfSObjectFactory
 * @see TdfSObjectTemplate
 * @see TdfSObjectTemplateFactory
 * @author  Svata Sejkora
 * @date    2022-09-27
 *
 */
@IsTest
public class TdfUserTemplate extends TdfSObjectTemplate {

    private static Integer usernameCounter = 0;
    Id baseProfileId;
    Id roleId;

    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Svata Sejkora
     * @date    2022-09-27
     *
     */
    public override void init() {
        User userDefinedUser = (User) userDefinedSObject;

        if (userDefinedUser.ProfileId == null) {
            baseProfileId = [SELECT Id FROM Profile WHERE Name = 'AG Barr Profile'].Id;
        }

        roleId = userDefinedUser.UserRoleId;
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return sobject template
     *
     * @author  Svata Sejkora
     * @date    2022-09-27
     *
     */
    protected override SObject createTemplateSObject() {
        User template = new User();
        template.LastName = 'TestAgBarrUser';
        template.FirstName = 'Test';
        template.Alias = 'ttteee';
        template.Email = 'jason.liveston@asdf.com';
        template.Username = 'testuserName' + ++usernameCounter + '@agbarrtestusercreatedintest.com';
        template.ProfileId = baseProfileId;
        template.TimeZoneSidKey = 'GMT';
        template.LanguageLocaleKey = 'en_US';
        template.EmailEncodingKey = 'UTF-8';
        template.LocaleSidKey = 'en_US';

        if (roleId != null) {
            template.UserRoleId = roleId;
        }
        return template;
    }
}