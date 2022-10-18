/**
 * @description       :
 * @author            : Ciuca Bianca BearingPoint GmbH
 * @group             :
 * @last modified on  : 10-07-2022
 * @last modified by  : Ciuca Bianca, BearingPoint GmbH
 **/
@IsTest
private with sharing class InvoiceServiceTest {
	@IsTest
	private static void testCreateInvoicesFromOrders_NoDocumentGenerated() {
		// create product
		Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(
				new Product2(Name = 'Test Product', ProductCode = 'SKU1')
		);

		// add new product to standard PB
		TdfSObjectFactory.insertSObject(
				new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
		);

		// create pricebook and add products to pricebook
		Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
		PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
				new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
		);

		// create account
		Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
				new Account(
						RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
						AccountStatus__c = 'Traders',
						aforza__Default_Price_Book__c = newPricebook.Id
				)
		);

		// create order and add items to the order
		Order newOrder = (Order) TdfSObjectFactory.insertSObject(
				new Order(
						RecordTypeId = RecordTypes.ORDER_TELESALES_ID,
						AccountId = dpAccount.Id,
						Status = 'Draft',
						Pricebook2Id = newPricebook.Id
				)
		);
		OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
				new OrderItem(
						OrderId = newOrder.Id,
						Product2Id = newProduct.Id,
						PricebookEntryId = newPricebookEntry.Id
				)
		);

		Test.startTest();
		InvoiceService.createInvoicesFromOrders(new Set<Id>{ newOrder.Id });
		Test.stopTest();

		// retrieve invoice and invoice line items, validate results
		List<aforza__Invoice__c> invoices = [SELECT Id FROM aforza__Invoice__c WHERE aforza__Order__c = :newOrder.Id];
		System.assertEquals(1, invoices.size());

		List<aforza__Invoice_Line_Item__c> invoiceLineItems = [
			SELECT Id
			FROM aforza__Invoice_Line_Item__c
			WHERE aforza__Invoice__c IN :invoices
		];
		System.assertEquals(1, invoiceLineItems.size());

		List<ContentDocumentLink> relatedFiles = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :invoices[0].Id];
		System.assertEquals(0, relatedFiles.size());

		List<Task> relatedActivities = [SELECT Id FROM Task WHERE WhatId = :invoices[0].Id];
		System.assertEquals(0, relatedActivities.size());
	}

	@IsTest
	private static void testCreateInvoicesFromOrders_DocumentGenerated() {
		// create product
		Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(
				new Product2(Name = 'Test Product', ProductCode = 'SKU1')
		);

		// add new product to standard PB
		TdfSObjectFactory.insertSObject(
				new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
		);

		// create pricebook and add products to pricebook
		Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
		PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
				new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
		);

		// create account
		Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
				new Account(
						RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
						AccountStatus__c = 'Traders',
						InvoiceType__c = 'Email',
						aforza__Invoice_Email_Address__c = 'test@test.com',
						aforza__Default_Price_Book__c = newPricebook.Id
				)
		);

		Contact newContact = (Contact) TdfSObjectFactory.insertSObject(
				new Contact(AccountId = dpAccount.Id, Email = 'test@test.com')
		);
		dpAccount.aforza__Primary_Contact__c = newContact.Id;
		update dpAccount;

		// create order and add items to the order
		Order newOrder = (Order) TdfSObjectFactory.insertSObject(
				new Order(
						RecordTypeId = RecordTypes.ORDER_TELESALES_ID,
						AccountId = dpAccount.Id,
						Status = 'Draft',
						Pricebook2Id = newPricebook.Id
				)
		);
		OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
				new OrderItem(
						OrderId = newOrder.Id,
						Product2Id = newProduct.Id,
						PricebookEntryId = newPricebookEntry.Id
				)
		);

		Test.startTest();
		InvoiceService.createInvoicesFromOrders(new Set<Id>{ newOrder.Id });
		Test.stopTest();

		// retrieve invoice and invoice line items, validate results
		List<aforza__Invoice__c> invoices = [SELECT Id FROM aforza__Invoice__c WHERE aforza__Order__c = :newOrder.Id];
		System.assertEquals(1, invoices.size());

		List<aforza__Invoice_Line_Item__c> invoiceLineItems = [
				SELECT Id
				FROM aforza__Invoice_Line_Item__c
				WHERE aforza__Invoice__c IN :invoices
		];
		System.assertEquals(1, invoiceLineItems.size());

		List<ContentDocumentLink> relatedFiles = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :invoices[0].Id];
		System.assertEquals(1, relatedFiles.size());

		List<Task> relatedActivities = [SELECT Id FROM Task WHERE WhatId = :invoices[0].Id];
		System.assertEquals(1, relatedActivities.size());
	}

	@IsTest
	private static void testGetPaymentTransactions() {
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
	private static void testGenerateInvoiceFromOrder() {
		// create product
		Product2 newProduct = (Product2) TdfSObjectFactory.insertSObject(
				new Product2(Name = 'Test Product', ProductCode = 'SKU1')
		);

		// add new product to standard PB
		TdfSObjectFactory.insertSObject(
				new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = TdfPricebook2Template.standardPricebookId)
		);

		// create pricebook and add products to pricebook
		Pricebook2 newPricebook = (Pricebook2) TdfSObjectFactory.insertSObject(new Pricebook2());
		PricebookEntry newPricebookEntry = (PricebookEntry) TdfSObjectFactory.insertSObject(
				new PricebookEntry(Product2Id = newProduct.Id, Pricebook2Id = newPricebook.Id)
		);

		// create account
		Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
				new Account(
						RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
						AccountStatus__c = 'Traders',
						aforza__Default_Price_Book__c = newPricebook.Id
				)
		);

		// create order and add items to the order
		Order newOrder = (Order) TdfSObjectFactory.insertSObject(
				new Order(
						RecordTypeId = RecordTypes.ORDER_TELESALES_ID,
						AccountId = dpAccount.Id,
						Status = 'Draft',
						Pricebook2Id = newPricebook.Id
				)
		);
		OrderItem newOrderItem = (OrderItem) TdfSObjectFactory.insertSObject(
				new OrderItem(
						OrderId = newOrder.Id,
						Product2Id = newProduct.Id,
						PricebookEntryId = newPricebookEntry.Id
				)
		);

		aforza__Invoice__c newInvoice = new aforza__Invoice__c();

		Test.startTest();
		InvoiceService.generateInvoiceFromOrder(newInvoice, newOrder);
		Test.stopTest();

		System.assertEquals(newOrder.Id, newInvoice.aforza__Order__c);
	}

	@IsTest
	private static void testGetOrders() {
		Account dpAccount = (Account) TdfSObjectFactory.insertSObject(
			new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID, AccountStatus__c = 'Traders')
		);

		Order newOrder = (Order) TdfSObjectFactory.insertSObject(
			new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID, AccountId = dpAccount.Id, Status = 'Draft')
		);

		Test.startTest();
		List<Order> orders = InvoiceService.getOrders(new Set<Id>{ newOrder.Id });
		Test.stopTest();

		System.assertEquals(1, orders.size());
	}

	@IsTest
	private static void getInvoices() {
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

		Test.startTest();
		List<aforza__Invoice__c> invoices = InvoiceService.getInvoices(new Set<Id>{ newOrder.Id });
		Test.stopTest();

		System.assertEquals(1, invoices.size());
	}
}