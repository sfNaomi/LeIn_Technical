/**
 * Created by svatopluk.sejkora on 05.10.2022.
 */

public with sharing class TdfAforzaAttributeAssignmentTemplate extends TdfSObjectTemplate {
    private Id attributeId;
    private Id accountId;
    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Svata Sejkora
     * @date    2022-10-04
     *
     */
    public override void init() {
        aforza__Attribute_Assignment__c userDefinedAttributeAssignment = (aforza__Attribute_Assignment__c) userDefinedSObject;

        if (userDefinedAttributeAssignment.aforza__Attribute__c == null) {
            attributeId = TdfSObjectFactory.insertSObject(new aforza__Attribute_Category__c()).Id;
        }

        if (userDefinedAttributeAssignment.aforza__Account__c == null) {
            accountId = TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)).Id;
        }
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return attribute template with default values
     *
     * @author  Svata Sejkora
     * @date    2022-10-04
     *
     */
    protected override SObject createTemplateSObject() {
        aforza__Attribute_Assignment__c template = new aforza__Attribute_Assignment__c(
                aforza__Account__c = accountId,
                aforza__Attribute__c = attributeId
        );
        return template;
    }
}