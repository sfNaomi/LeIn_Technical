trigger AttributeAssignmentTrigger on aforza__Attribute_Assignment__c (after Insert, after Update, before Delete) {
    if (Trigger.isInsert || Trigger.isUpdate) {
        AforzaLabsSegmentToolAssignmentHandler.main(Trigger.New, false);
    } else if (Trigger.isDelete) {
        AforzaLabsSegmentToolAssignmentHandler.main(Trigger.Old, true);
    }
}