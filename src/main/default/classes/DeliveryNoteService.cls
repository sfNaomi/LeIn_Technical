public without sharing class DeliveryNoteService {
	private static final String ORDER_EMAIL_TEMPLATE_NAME = 'AGBarrOrderEmailTemplate';

	private static final Id ORDER_EMAIL_TEMPLATE_ID {
		get {
			if (ORDER_EMAIL_TEMPLATE_ID == null) {
				List<EmailTemplate> templates = new List<EmailTemplate>(
					[SELECT Id FROM EmailTemplate WHERE DeveloperName = :ORDER_EMAIL_TEMPLATE_NAME LIMIT 1]
				);
				ORDER_EMAIL_TEMPLATE_ID = templates.isEmpty() ? null : templates[0].Id;
			}
			return ORDER_EMAIL_TEMPLATE_ID;
		}
		set;
	}

	@Future(Callout=true)
	public static void generateOrderAttachmentsAndSendDeliveryEmails(Set<Id> orderIds) {
		List<Order> orders = new List<Order>(
			[SELECT Account.DeliveryNoteEmail__c, Account.aforza__Primary_Contact__c FROM Order WHERE Id IN :orderIds]
		);
		Map<Id, ContentVersion> contentVersionByOrderId = generateOrderAttachments(orders);
		sendOrderDeliveryEmails(orders, contentVersionByOrderId);
	}

	private static Map<Id, ContentVersion> generateOrderAttachments(List<Order> orders) {
		Map<Id, Order> orderMap = new Map<Id, Order>(orders);
		return FileGenerationService.generateDocuments(
			FileGenerationService.documentType.DELIVERY_NOTE,
			orderMap.keySet()
		);
	}

	private static void sendOrderDeliveryEmails(List<Order> orders, Map<Id, ContentVersion> contentVersionByOrderId) {
		Map<Id, Order> orderMap = new Map<Id, Order>(orders);
		List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
		for (Order ord : orderMap.values()) {
			if (contentVersionByOrderId.containsKey(ord.Id)) {
				if( ord?.Account?.aforza__Primary_Contact__c != null && ord?.Account?.DeliveryNoteEmail__c != null ) {
					ContentVersion cversion = contentVersionByOrderId.get(ord.Id);
					Messaging.SingleEmailMessage message = EmailService.buildEmailMessage(
						ORDER_EMAIL_TEMPLATE_ID,
						false,
						true,
						ord.Id,
						ord?.Account?.aforza__Primary_Contact__c,
						new List<String>{ ord?.Account?.DeliveryNoteEmail__c },
						new List<String>{ cversion?.Id }
					);
					emails.add(message);
				}
			}
		}
		if (!emails.isEmpty()) {
			Messaging.sendEmail(emails);
		}
	}
}