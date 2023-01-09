/**
 * Created by magdalena.stanciu on 28.11.2022.
 */

trigger VisitTrigger on aforza__Visit__c (after insert) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            VisitTriggerHandler.copyLast4VisitNotesOnVisit(Trigger.newMap);
        }
    }
}