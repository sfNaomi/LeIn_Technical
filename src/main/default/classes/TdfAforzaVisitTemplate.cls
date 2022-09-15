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
public with sharing class TdfAforzaVisitTemplate extends TdfSObjectTemplate {
    private Id recurringRecordId;
    private Id accountRecordId;

    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Svata Sejkoda
     * @date    2022-06-02
     *
     */
    public override void init() {
        aforza__Visit__c userDefinedVisitRecord = (aforza__Visit__c) userDefinedSObject;

        if (userDefinedVisitRecord.aforza__Account__c == null) {
            accountRecordId = TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)).Id;
        }

        if (userDefinedVisitRecord.aforza__Recurring_Record__c == null) {
            recurringRecordId = TdfSObjectFactory.insertSObject(new aforza__Recurring_Record__c(Account__c = accountRecordId)).Id;
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
        aforza__Visit__c template = new aforza__Visit__c(
                RecordTypeId = RecordTypes.VISIT_REMOTE_VISIT_ID,
                aforza__Account__c = accountRecordId,
                aforza__Owner__c = UserInfo.getUserId(),
                aforza__Type__c = 'Phone Call',
                aforza__Status__c = 'Not Started',
                aforza__Recurring_Record__c = recurringRecordId,
                aforza__Start_Time__c = System.now().addDays(1),
                aforza__End_Time__c = System.now().addDays(1).addMinutes(6)
        );

        return template;
    }
}
