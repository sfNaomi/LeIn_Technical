/**
 * Created by magdalena.stanciu on 13.09.2022.
 */

trigger OrderTrigger on Order (after insert) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            OrderTriggerHandler.determineIfOrderCreationRequiresRelatedAccountStatusUpdate(Trigger.new);
        }
    }
}