/**
 * @description       :
 * @author            : Ciuca Bianca BearingPoint GmbH
 * @group             :
 * @last modified on  : 10-07-2022
 * @last modified by  : Ciuca Bianca, BearingPoint GmbH
 **/

@IsTest
public with sharing class InvoicePDFControllerTest {
	@IsTest
	static void testInvoicePDFController() {
		Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
			new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
		);
		Order newOrder = (Order) TdfSObjectFactory.insertSObject(
			new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
		);
		aforza__Invoice__c newInvoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(
			new aforza__Invoice__c(aforza__Account__c = dpAccount.Id, aforza__Order__c = newOrder.Id, aforza__Reference__c = '10')
		);
		aforza__Invoice_Line_Item__c newInvoiceLineItem = (aforza__Invoice_Line_Item__c) TdfSObjectFactory.insertSObject(
			new aforza__Invoice_Line_Item__c(aforza__Invoice__c = newInvoice.Id)
		);

		insertContentVersion();
		insertContentDocumentLink(newOrder.Id);

		Test.startTest();
		PageReference testPage = Page.AGBarrInvoice;
		Test.setCurrentPage(testPage);
		testPage.getParameters().put('id', newInvoice.Id);
		InvoicePDFController.attachPDF(newInvoice.Id);
		InvoicePDFController testPdfController = new InvoicePDFController();
		Test.stopTest();
	}

	public static void insertContentVersion() {
		ContentVersion contentVersion = new Contentversion();
		contentVersion.Title = 'Signature Test';
		contentVersion.PathOnClient = 'Test';
		Blob b = Blob.valueOf('Unit Test Attachment Body');
		contentVersion.versiondata = EncodingUtil.base64Decode('Unit Test Attachment Body');
		insert contentVersion;
	}

	public static void insertContentDocumentLink(Id linkedRecordId) {
		Id insertedContentVersion = [SELECT ContentDocumentId FROM ContentVersion].ContentDocumentId;
		ContentDocumentLink contentDocLink = new ContentDocumentLink(
			LinkedEntityId = linkedRecordId,
			ContentDocumentId = insertedContentVersion,
			ShareType = 'V'
		);
		insert contentDocLink;
	}
}
