/**
 * Created by svatopluk.sejkora on 01.10.2022.
 */

trigger AccountTeamMemberTrigger on AccountTeamMember (before insert, before update, after insert, after update, after delete) {
    try {
        switch on Trigger.operationType {
            when BEFORE_INSERT {
                AccountTeamMemberTriggerHandler.allowOnlyOneTamUserPerAccount(Trigger.new);
            }
            when BEFORE_UPDATE {
                AccountTeamMemberTriggerHandler.allowOnlyOneTamUserPerAccount(Trigger.new);
            }
            when AFTER_INSERT {
                AccountTeamMemberTriggerHandler.manageReoccurrenceRecord(Trigger.new, Trigger.oldMap);
                AccountTeamMemberTriggerHandler.updateDriverNameOnAccountFromDriverAccountTeamMember(Trigger.new, Trigger.oldMap);
            }
            when AFTER_UPDATE {
                AccountTeamMemberTriggerHandler.manageReoccurrenceRecord(Trigger.new, Trigger.oldMap);
                AccountTeamMemberTriggerHandler.updateDriverNameOnAccountFromDriverAccountTeamMember(Trigger.new, Trigger.oldMap);
            }
            when AFTER_DELETE {
                AccountTeamMemberTriggerHandler.deleteReoccurrenceRecord(Trigger.oldMap);
                AccountTeamMemberTriggerHandler.deleteDriversNameFromAccount(Trigger.oldMap);
            }
        }
    } catch (Exception e) {
        throw e;
    }
}