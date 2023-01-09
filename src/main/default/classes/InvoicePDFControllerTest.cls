/**
 * @description       :
 * @author            : Ciuca Bianca BearingPoint GmbH
 * @group             :
 * @last modified on  : 10-07-2022
 * @last modified by  : Ciuca Bianca, BearingPoint GmbH
 **/

@IsTest
private with sharing class InvoicePDFControllerTest {
	@IsTest
	private static void testInvoicePDFController() {
		Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
			new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
		);
		Order newOrder = (Order) TdfSObjectFactory.insertSObject(
			new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
		);
		aforza__Invoice__c newInvoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(
			new aforza__Invoice__c(aforza__Account__c = dpAccount.Id, aforza__Order__c = newOrder.Id, aforza__Reference__c = '10')
		);
		TdfSObjectFactory.insertSObject(
			new aforza__Invoice_Line_Item__c(aforza__Invoice__c = newInvoice.Id)
		);
		ContentVersion signature = (ContentVersion) TdfSObjectFactory.insertSObject(
			new ContentVersion(Title = 'Signature Test', PathOnClient = 'Test', VersionData = EncodingUtil.base64Decode('Body'))
		);
		String signatureDocId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :signature.Id].ContentDocumentId;
		TdfSObjectFactory.insertSObject(
			new ContentDocumentLink(ContentDocumentId = signatureDocId, LinkedEntityId = newOrder.Id, ShareType = 'V')
		);

		PageReference pageRef = Page.AGBarrInvoice;
		Test.setCurrentPage(pageRef);

		ApexPages.currentPage().getParameters().put('p', newInvoice.Id);

		Test.startTest();
		InvoicePDFController ctrl = new InvoicePDFController();
		Test.stopTest();

		Assert.areEqual(1, ctrl.invoices.size());
	}
}
