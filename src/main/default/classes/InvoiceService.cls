/**
 * @description       :
 * @author            : Ciuca Bianca BearingPoint GmbH
 * @group             :
 * @last modified on  : 10-07-2022
 * @last modified by  : Ciuca Bianca, BearingPoint GmbH
 **/
public with sharing class InvoiceService {
	private static final String INVOICE_OBJECT_NAME = 'aforza__Invoice__c';

	public static final FieldMapping__mdt ORDER_TO_INVOICE_MAPPING {
		get {
			if (ORDER_TO_INVOICE_MAPPING == null) {
				ORDER_TO_INVOICE_MAPPING = CommonUtility.getFieldMapping('ORDER_TO_INVOICE');
			}
			return ORDER_TO_INVOICE_MAPPING;
		}
		set;
	}

	public static final FieldMapping__mdt ORDER_ITEM_TO_INVOICE_ITEM_MAPPING {
		get {
			if (ORDER_ITEM_TO_INVOICE_ITEM_MAPPING == null) {
				ORDER_ITEM_TO_INVOICE_ITEM_MAPPING = CommonUtility.getFieldMapping('ORDER_ITEM_TO_INVOICE_ITEM');
			}
			return ORDER_ITEM_TO_INVOICE_ITEM_MAPPING;
		}
		set;
	}
	public static String getSObjectType(Id recordId) {
		return recordId.getSObjectType().getDescribe().getName();
	}

	public static Blob getPdfContentBlob(Id recordId, PageReference pdfDocumentPageRef) {
		pdfDocumentPageRef.getParameters().put('id', recordId);
		Blob pdfBlob = Test.isRunningTest() ? Blob.valueOf('Test Page') : pdfDocumentPageRef.getContent();
		return pdfBlob;
	}

	public static void generatePdfDocument(List<Id> recordIds, PageReference pdfDocumentPageRef) {
		String sObjectType = getSObjectType(recordIds[0]);
		sendEmailWithInvoiceAttachment(recordIds);
		if (sObjectType == 'aforza__Invoice__c') {
			List<aforza__Invoice__c> invoicePdfsToGenerate = [SELECT Name FROM aforza__Invoice__c WHERE Id IN :recordIds];
			insertPdfAsFileForSObject(invoicePdfsToGenerate, pdfDocumentPageRef, sObjectType);
		} else {
			//List<Order> orderPdfsToGenerate = [SELECT Name FROM Order WHERE Id IN :recordIds];
			//insertPdfAsFileForSObject(orderPdfsToGenerate, pdfDocumentPageRef, sObjectType);
		}
	}

	public static void insertPdfAsFileForSObject(
		List<SObject> sObjectPdfsToGenerate,
		PageReference pdfDocumentPageRef,
		String sObjectType
	) {
		List<ContentVersion> newContentVersionsToInsert = new List<ContentVersion>();
		for (SObject sObjectRecord : sObjectPdfsToGenerate) {
			Blob pdfContentBlob = getPdfContentBlob(sObjectRecord.Id, pdfDocumentPageRef);
			ContentVersion newContentVersion = new ContentVersion();
			newContentVersion.ContentLocation = 'S';
			newContentVersion.Origin = 'C';
			newContentVersion.OwnerId = UserInfo.getUserId();
			newContentVersion.VersionData = pdfContentBlob;
			if (sObjectType == INVOICE_OBJECT_NAME) {
				addDetailsToContentVersionSpecificToInvoice(newContentVersion, (aforza__Invoice__c) sObjectRecord);
			}

			newContentVersionsToInsert.add(newContentVersion);
		}

		insert newContentVersionsToInsert;

		List<ContentDocumentLink> contentDocumentsLinksToInsert = new List<ContentDocumentLink>();
		Set<Id> insertedContentVersionsIds = (new Map<Id, ContentVersion>(newContentVersionsToInsert)).keySet();
		for (ContentVersion insertedContentVersion : [
			SELECT InvoiceId__c, ContentDocumentId
			FROM ContentVersion
			WHERE Id IN :insertedContentVersionsIds
		]) {
			ContentDocumentLink newContentDocumentLink = new ContentDocumentLink();
			newContentDocumentLink.ContentDocumentId = insertedContentVersion.ContentDocumentId;
			newContentDocumentLink.ShareType = 'V';
			if (sObjectType == INVOICE_OBJECT_NAME) {
				newContentDocumentLink.LinkedEntityId = insertedContentVersion.InvoiceId__c;
			}
			contentDocumentsLinksToInsert.add(newContentDocumentLink);
		}
		insert contentDocumentsLinksToInsert;
	}

	public static void addDetailsToContentVersionSpecificToInvoice(ContentVersion newContentVersion, aforza__Invoice__c invoice) {
		newContentVersion.PathOnClient = 'Invoice ' + invoice.Name + ' ' + system.today().format() + '.pdf';
		newContentVersion.Title = 'Invoice ' + invoice.Name + ' ' + system.today().format() + '.pdf';
		newContentVersion.InvoiceId__c = invoice.Id;
	}

	@future(callout=true)
	public static void sendEmailWithInvoiceAttachment(List<Id> recordIds) {
		List<aforza__Invoice__c> invoicesToEmail = [
			SELECT
				id,
				aforza__Account__r.aforza__Invoice_Email_Address__c,
				aforza__Account__r.InvoiceType__c,
				aforza__Account__r.aforza__Primary_Contact__c
			FROM aforza__Invoice__c
			WHERE
				Id IN :recordIds
				AND aforza__Account__r.InvoiceType__c = 'Email'
				AND aforza__Account__r.aforza__Invoice_Email_Address__c != NULL
		];

		List<Messaging.SingleEmailMessage> emailsToBeSent = new List<Messaging.SingleEmailMessage>();
		EmailTemplate emailTemplate = [
			SELECT Id, Subject, Description, HtmlValue, DeveloperName, Body
			FROM EmailTemplate
			WHERE DeveloperName = 'AGBarrInvoiceEmailTemplate'
		];

		for (aforza__Invoice__c invoice : invoicesToEmail) {
			Messaging.EmailFileAttachment emailAttachment = buildEmailAttachment(invoice.Id, Page.AGBarrInvoice);
			Messaging.SingleEmailMessage message = buildEmailMessage(
				invoice.aforza__Account__r.aforza__Invoice_Email_Address__c,
				emailAttachment
			);
			message.setTemplateID(emailTemplate.Id);
			message.setWhatId(invoice.Id);
			message.setTargetObjectId(invoice.aforza__Account__r.aforza__Primary_Contact__c);
			message.setTreatTargetObjectAsRecipient(false);
			emailsToBeSent.add(message);
		}
		try {
			if (!emailsToBeSent.isEmpty()) {
				Messaging.SendEmailResult[] results = Messaging.sendEmail(emailsToBeSent);
			}
		} catch (Exception e) {
			System.debug(LoggingLevel.Error, e.getMessage());
			System.debug(LoggingLevel.Error, e.getStackTraceString());
		}
	}

	public static Messaging.SingleEmailMessage buildEmailMessage(String emailAddress, Messaging.EmailFileAttachment emailAttachment) {
		Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
		message.setToAddresses(new List<String>{ emailAddress });
		message.setSenderDisplayName('AgBarr');
		message.setReplyTo('fusion-no-reply@agbarr.co.uk');
		message.setUseSignature(false);
		message.setBccSender(false);
		message.setSaveAsActivity(true);
		message.setFileAttachments(new List<Messaging.EmailFileAttachment>{ emailAttachment });
		return message;
	}

	public static Messaging.EmailFileAttachment buildEmailAttachment(Id recordId, PageReference pdfDocumentPageRef) {
		String sObjectType = getSObjectType(recordId);
		Blob pdfContentBlob = getPdfContentBlob(recordId, pdfDocumentPageRef);
		Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
		emailAttachment.setContentType('application/pdf');
		emailAttachment.setInline(false);
		emailAttachment.setBody(pdfContentBlob);
		if (sObjectType == 'aforza__Invoice__c') {
			emailAttachment.setFileName('Invoice' + system.today().format() + '.pdf');
		} else {
			//emailAttachment.setFileName('Delivery Note' + system.today().format() + '.pdf');
		}
		return emailAttachment;
	}
	/* Created by magdalena.stanciu on 06.10.2022.
	 */

	public static void createInvoicesForOrders(Set<Id> orderIdsToCreateInvoiceFor) {
		List<Order> ordersToBeProcessed = getOrders(orderIdsToCreateInvoiceFor);
		List<aforza__Invoice__c> existingInvoices = getInvoices(orderIdsToCreateInvoiceFor);

		Map<Id, aforza__Invoice__c> orderIdExistingInvoice = new Map<Id, aforza__Invoice__c>();
		for (aforza__Invoice__c existingInvoice : existingInvoices) {
			orderIdExistingInvoice.put(existingInvoice.aforza__Order__c, existingInvoice);
		}

		// generate invoices
		Map<Id, aforza__Invoice__c> invoicesByOriginalOrderId = new Map<Id, aforza__Invoice__c>();
		for (Order existingOrder : ordersToBeProcessed) {
			aforza__Invoice__c newInvoice = orderIdExistingInvoice.get(existingOrder.Id);

			if (newInvoice == null) {
				newInvoice = new aforza__Invoice__c();
			}

			populateInvoiceFromOrder(newInvoice, existingOrder);
			invoicesByOriginalOrderId.put(existingOrder.Id, newInvoice);
		}
		upsert invoicesByOriginalOrderId.values();

		// generate invoice line items
		List<aforza__Invoice_Line_Item__c> invoiceLineItems = new List<aforza__Invoice_Line_Item__c>();
		for (Order existingOrder : ordersToBeProcessed) {
			aforza__Invoice__c existingInvoice = invoicesByOriginalOrderId.get(existingOrder.Id);
			for (OrderItem existingOrderItem : existingOrder.OrderItems) {
				aforza__Invoice_Line_Item__c newInvoiceLineItem = generateInvoiceLineItem(existingOrderItem, existingInvoice);

				invoiceLineItems.add(newInvoiceLineItem);
			}
		}
		insert invoiceLineItems;

		// link payments
		List<aforza__Payment_Transaction__c> transactions = getPaymentTransactions(orderIdsToCreateInvoiceFor);
		for (aforza__Payment_Transaction__c newTransaction : transactions) {
			Id invoiceId = invoicesByOriginalOrderId?.get(newTransaction.OrderNumber__c)?.Id;
			newTransaction.aforza__Invoice__c = invoiceId;
		}
		update transactions;
	}

	@TestVisible
	private static List<aforza__Payment_Transaction__c> getPaymentTransactions(Set<Id> orderIds) {
		List<aforza__Payment_Transaction__c> transactions = [
			SELECT Id, OrderNumber__c, aforza__Invoice__c
			FROM aforza__Payment_Transaction__c
			WHERE OrderNumber__c IN :orderIds
		];
		return transactions;
	}

	@TestVisible
	private static aforza__Invoice__c populateInvoiceFromOrder(aforza__Invoice__c newInvoice, Order existingOrder) {
		// set fixed fields
		newInvoice.aforza__Issued_Date__c = newInvoice.aforza__Issued_Date__c != null ? newInvoice.aforza__Issued_Date__c : System.today();
		newInvoice.aforza__Due_Date__c = newInvoice.aforza__Issued_Date__c + 28;

		// populate fields on the new invoice based on mapping
		CommonUtility.populateTargetSObjectFromSourceSObjectBasedOnMapping(newInvoice, existingOrder, ORDER_TO_INVOICE_MAPPING);

		return newInvoice;
	}

	@TestVisible
	private static aforza__Invoice_Line_Item__c generateInvoiceLineItem(OrderItem existingOrderItem, aforza__Invoice__c existingInvoice) {
		// create invoice line item
		aforza__Invoice_Line_Item__c newInvoiceLineItem = new aforza__Invoice_Line_Item__c();

		// add fixed fields - fields may be overwritten, if mappings exist for these fields
		newInvoiceLineItem.aforza__Invoice__c = existingInvoice.Id;

		// populate fields on the new invoice based on mapping
		CommonUtility.populateTargetSObjectFromSourceSObjectBasedOnMapping(
			newInvoiceLineItem,
			existingOrderItem,
			ORDER_ITEM_TO_INVOICE_ITEM_MAPPING
		);

		return newInvoiceLineItem;
	}

	@TestVisible
	private static List<Order> getOrders(Set<Id> orderIds) {
		List<String> orderFields = new List<String>(
			CommonUtility.getFieldsToQueryFromMapping(ORDER_TO_INVOICE_MAPPING, CommonUtility.QueryFieldType.SOURCE)
		);
		List<String> orderItemFields = new List<String>(
			CommonUtility.getFieldsToQueryFromMapping(ORDER_ITEM_TO_INVOICE_ITEM_MAPPING, CommonUtility.QueryFieldType.SOURCE)
		);

		String queryString =
			'SELECT ' +
			String.join(orderFields, ',') +
			', ' +
			'(SELECT ' +
			String.join(orderItemFields, ',') +
			' FROM OrderItems) ' +
			'FROM Order WHERE Id IN :orderIds';
		List<Order> orders = Database.query(queryString);

		return orders;
	}

	@TestVisible
	private static List<aforza__Invoice__c> getInvoices(Set<Id> orderIds) {
		Set<String> invoiceFields = CommonUtility.getFieldsToQueryFromMapping(
			ORDER_TO_INVOICE_MAPPING,
			CommonUtility.QueryFieldType.TARGET
		);

		// fields set to fixed values in code - not based on mapping
		Set<String> FIXED_INVOICE_FIELDS = new Set<String>{ 'aforza__Issued_Date__c', 'aforza__Due_Date__c' };
		invoiceFields.addAll(FIXED_INVOICE_FIELDS);

		List<String> allQueryFields = new List<String>(invoiceFields);

		String queryString = 'SELECT ' + String.join(allQueryFields, ',') + ' FROM aforza__Invoice__c WHERE aforza__Order__c IN :orderIds';
		List<aforza__Invoice__c> invoices = Database.query(queryString);

		return invoices;
	}
}
