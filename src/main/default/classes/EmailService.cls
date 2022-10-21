/**
 * Created by magdalena.stanciu on 10.10.2022.
 */

public with sharing class EmailService {

    public static final Id ORG_WIDE_EMAIL_ADDRESS_ID {
        get {
            if (ORG_WIDE_EMAIL_ADDRESS_ID == null) {
                List<OrgWideEmailAddress> addresses = [
                        SELECT Id
                        FROM OrgWideEmailAddress
                        WHERE Address = 'fusion-no-reply@agbarr.co.uk'
                ];
                if (!addresses.isEmpty()) {
                    ORG_WIDE_EMAIL_ADDRESS_ID = addresses[0].Id;
                } else {
                    ORG_WIDE_EMAIL_ADDRESS_ID = null;
                }
            }
            return ORG_WIDE_EMAIL_ADDRESS_ID;
        }
        set;
    }

    public static void send(List<Messaging.SingleEmailMessage> emails) {
        try {
            if (!emails.isEmpty()) {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(emails);
            }
        } catch (Exception e) {
            throw new EmailException(e.getMessage());
        }
    }

    public static Messaging.SingleEmailMessage buildEmailMessage(
            String templateId,
            Boolean treatTargetObjectAsRecipient,
            Boolean saveActivity,
            String whatId,
            String targetObjectId,
            List<String> toAddresses,
            List<String> attachmentsIds
    ) {
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setTemplateID(templateId);
        message.setWhatId(whatId);
        message.setTargetObjectId(targetObjectId);
        message.setTreatTargetObjectAsRecipient(treatTargetObjectAsRecipient);
        message.setToAddresses(toAddresses);
        message.setOrgWideEmailAddressId(ORG_WIDE_EMAIL_ADDRESS_ID);
        message.setSaveAsActivity(saveActivity);
        message.setEntityAttachments(attachmentsIds);
        return message;
    }

    public class EmailException extends Exception {

    }
}