/**
 * Class provides functionality for creating default segment in test methods.
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
public with sharing class TdfAforzaSegmentTemplate extends TdfSObjectTemplate {

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
     * @return template with segment record
     *
     * @author  Magdalena Stanciu
     * @date    2022-10-27
     *
     */
    protected override SObject createTemplateSObject() {
        aforza__Segment__c template = new aforza__Segment__c(
            Name = 'Test Segment',
            aforza__Description__c = 'Test Segment'
        );
        return template;
    }
}
