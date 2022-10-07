/**
 * @description       :
 * @author            : Ciuca Bianca BearingPoint GmbH
 * @group             :
 * @last modified on  : 10-07-2022
 * @last modified by  : Ciuca Bianca, BearingPoint GmbH
 **/
@IsTest
public with sharing class InvoiceServiceTest {
	@IsTest
	static void testPdfGeneration() {
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

		InvoicePDFControllerTest.insertContentVersion();
		InvoicePDFControllerTest.insertContentDocumentLink(newOrder.Id);

		Test.startTest();
		InvoiceService.generatePdfDocument(new List<Id>{ newInvoice.Id }, Page.AGBarrInvoice);
		Test.stopTest();
		List<ContentDocumentLink> attachmentLink = [
			SELECT Id, ContentDocumentId
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :newInvoice.Id
		];
		System.assertEquals(attachmentLink.size(), 1, 'The attachment was not created or linked.');
	}
	@IsTest
	static void testEmailSending() {
		Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
			new Account(
				RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
				AccountStatus__c = 'Traders',
				aforza__Invoice_Email_Address__c = 'test@test.com',
				InvoiceType__c = 'Email'
			)
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

		InvoicePDFControllerTest.insertContentVersion();
		InvoicePDFControllerTest.insertContentDocumentLink(newOrder.Id);

		Test.startTest();
		InvoiceService.sendEmailWithInvoiceAttachment(new List<Id>{ newInvoice.Id });
		Test.stopTest();
	}

	/* Created by magdalena.stanciu on 06.10.2022.
	 */
	@IsTest
	public static void testCreateInvoicesForOrders() {
		Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
			new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
		);

		Order newOrder = (Order) TdfSObjectFactory.insertSObject(
			new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
		);
		Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product'));
		OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
			new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id)
		);

		Test.startTest();
		InvoiceService.createInvoicesForOrders(new Set<Id>{ newOrder.Id });
		Test.stopTest();

		// retrieve invoice and invoice line items, validate results
		List<aforza__Invoice__c> invoices = [SELECT Id FROM aforza__Invoice__c WHERE aforza__Order__c = :newOrder.Id];
		List<aforza__Invoice_Line_Item__c> invoiceLineItems = [
			SELECT Id
			FROM aforza__Invoice_Line_Item__c
			WHERE aforza__Invoice__c IN :invoices
		];
		System.assertEquals(1, invoices.size());
		System.assertEquals(1, invoiceLineItems.size());
	}

	@IsTest
	public static void testGetPaymentTransactions() {
		Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
			new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
		);

		Order newOrder = (Order) TdfSObjectFactory.insertSObject(
			new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
		);

		aforza__Payment_Transaction__c newPayment = (aforza__Payment_Transaction__c) TdfSObjectFactory.insertSObject(
			new aforza__Payment_Transaction__c(aforza__Account__c = dpAccount.Id, OrderNumber__c = newOrder.Id)
		);

		// retrieve payment and validate result
		List<aforza__Payment_Transaction__c> transactions = InvoiceService.getPaymentTransactions(new Set<Id>{ newOrder.Id });
		System.assertEquals(1, transactions.size());
	}

	@IsTest
	public static void testPopulateInvoiceFromOrder() {
		Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
			new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
		);

		Order newOrder = (Order) TdfSObjectFactory.insertSObject(
			new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
		);
		Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(new Product2(Name = 'Test Product'));
		OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
			new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id)
		);

		aforza__Invoice__c newInvoice = new aforza__Invoice__c();

		InvoiceService.populateInvoiceFromOrder(newInvoice, newOrder);
		System.assertEquals(newOrder.Id, newInvoice.aforza__Order__c);
	}

	@IsTest
	public static void testGetOrders() {
		Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
			new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
		);

		Order newOrder = (Order) TdfSObjectFactory.insertSObject(
			new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
		);

		System.assertEquals(1, InvoiceService.getOrders(new Set<Id>{ newOrder.Id }).size());
	}

	@IsTest
	public static void getInvoices() {
		// create dp account
		Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
			new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
		);

		// create related order
		Order newOrder = (Order) TdfSObjectFactory.insertSObject(
			new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
		);

		// create Invoice
		aforza__Invoice__c newInvoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(
			new aforza__Invoice__c(aforza__Account__c = dpAccount.Id, aforza__Order__c = newOrder.Id)
		);

		System.assertEquals(1, InvoiceService.getInvoices(new Set<Id>{ newOrder.Id }).size());
	}
}
