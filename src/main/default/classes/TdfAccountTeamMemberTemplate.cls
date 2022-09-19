/**
 * Class provides functionality for creating default Account Team Members in test methods.
 *
 * Do not use this class directly.
 * Class is initialized in TDF_SObjectTemplateFactory and all its functionality is used through TDF_SObjectFactory.
 *
 * @see TdfSObjectFactory
 * @see TdfSObjectTemplate
 * @see TdfSObjectTemplateFactory
 * @author  Magdalena Stanciu
 * @date    2022-09-14
 *
 */
@IsTest
public class TdfAccountTeamMemberTemplate extends TdfSObjectTemplate {
    private Id userId;
    private Id accountId;

    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Magdalena Stanciu
     * @date    2022-09-14
     *
     */
    public override void init() {
        AccountTeamMember userDefinedAccountTeamMember = (AccountTeamMember) userDefinedSObject;
        if (userDefinedAccountTeamMember.AccountId == null) {
            accountId = TdfSObjectFactory.insertSObject(new Account()).Id;
        }
        if (userDefinedAccountTeamMember.UserId == null) {
            userId = UserInfo.getUserId();
        }
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return account team member template with default values
     *
     * @author  Magdalena Stanciu
     * @date    2022-09-14
     *
     */
    protected override SObject createTemplateSObject() {
        AccountTeamMember template = new AccountTeamMember();
        template.TeamMemberRole = 'TAM';
        template.AccountId = accountId;
        template.UserId = userId;
        return template;
    }
}
