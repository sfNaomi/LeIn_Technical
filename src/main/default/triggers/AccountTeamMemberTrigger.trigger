/**
 * Created by svatopluk.sejkora on 01.10.2022.
 */

trigger AccountTeamMemberTrigger on AccountTeamMember (before insert, before update, after insert, after update, after delete) {
    try {
        switch on Trigger.operationType {
            when BEFORE_INSERT {
                AccountTeamMemberTriggerHandler.allowOnlyOneUserWithSpecifiedRolePerAccount(Trigger.new);
            }
            when BEFORE_UPDATE {
                AccountTeamMemberTriggerHandler.allowOnlyOneUserWithSpecifiedRolePerAccount(Trigger.new);
            }
            when AFTER_INSERT {
                AccountTeamMemberTriggerHandler.manageReoccurrenceRecord(Trigger.new, Trigger.oldMap);
                AccountTeamMemberTriggerHandler.copyInformationFromAccountTeamMemberToAccount(Trigger.new);
            }
            when AFTER_UPDATE {
                AccountTeamMemberTriggerHandler.manageReoccurrenceRecord(Trigger.new, Trigger.oldMap);
                AccountTeamMemberTriggerHandler.copyInformationFromAccountTeamMemberToAccount(Trigger.new);
            }
            when AFTER_DELETE {
                AccountTeamMemberTriggerHandler.deleteReoccurrenceRecord(Trigger.oldMap);
                AccountTeamMemberTriggerHandler.copyInformationFromAccountTeamMemberToAccount(Trigger.old);
            }
        }
    } catch (Exception e) {
        throw e;
    }
}