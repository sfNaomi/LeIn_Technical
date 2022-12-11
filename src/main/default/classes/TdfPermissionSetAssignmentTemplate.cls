/**
 * Class provides functionality for creating default Permission Set Assignments in test methods.
 *
 * Do not use this class directly.
 * Class is initialized in TDF_SObjectTemplateFactory and all its functionality is used through TDF_SObjectFactory.
 *
 * @see TdfSObjectFactory
 * @see TdfSObjectTemplate
 * @see TdfSObjectTemplateFactory
 * @author  Magdalena Stanciu
 * @date    2022-12-09
 *
 */
@IsTest
public class TdfPermissionSetAssignmentTemplate extends TdfSObjectTemplate {
    private Id userId;

    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Magdalena Stanciu
     * @date    2022-12-09
     *
     */
    public override void init() {
        PermissionSetAssignment userDefinedPermissionSetAssignment = (PermissionSetAssignment) userDefinedSObject;
        if (userDefinedPermissionSetAssignment.AssigneeId == null) {
            userId = UserInfo.getUserId();
        }
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return sobject template
     *
     * @author  Magdalena Stanciu
     * @date    2022-12-09
     *
     */
    protected override SObject createTemplateSObject() {
        PermissionSetAssignment template = new PermissionSetAssignment();
        template.AssigneeId = userId;
        return template;
    }
}