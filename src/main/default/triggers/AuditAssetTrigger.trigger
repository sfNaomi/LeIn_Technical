/**
 * Created by svatopluk.sejkora on 03.11.2022.
 */

trigger AuditAssetTrigger on aforza__Audit_Asset__c (before insert) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            AuditAssetTriggerHandler.populatePerfectScoreAttributes(Trigger.new);
        }
    }
}