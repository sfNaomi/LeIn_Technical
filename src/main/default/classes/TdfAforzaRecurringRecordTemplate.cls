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
public with sharing class TdfAforzaRecurringRecordTemplate extends TdfSObjectTemplate {
    private Id accountId;

    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Svata Sejkoda
     * @date    2022-06-02
     *
     */
    public override void init() {
        aforza__Recurring_Record__c userDefinedRecurringRecord = (aforza__Recurring_Record__c) userDefinedSObject;

        if (userDefinedRecurringRecord.Account__c == null) {
            accountId = TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID)).Id;
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
        aforza__Recurring_Record__c template = new aforza__Recurring_Record__c(
                Name = 'My test record',
                Account__c = accountId,
                aforza__Type__c = RecurringRecordService.CALL_SETTINGS.CallType__c,
                Status__c = RecurringRecordService.CALL_SETTINGS.CallStatus__c,
                aforza__Frequency__c = 'W',
                StartDate__c = Date.parse('05/09/2022'),
                Priority__c = 'P1',
                CallDayOfWeek__c = '1',
                aforza__Number_Of_Recurrences__c = 12,
                OwnerId = UserInfo.getUserId()
        );

        return template;
    }
}
