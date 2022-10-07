/**
 * @description       :
 * @author            : Ciuca Bianca BearingPoint GmbH
 * @group             :
 * @last modified on  : 10-06-2022
 * @last modified by  : Ciuca Bianca, BearingPoint GmbH
 **/
public with sharing class InvoicePDFController {
	public aforza__Invoice__c currentInvoice { get; set; }
	public Order associatedOrder { get; set; }
	public Account associatedAccount { get; set; }
	public List<aforza__Invoice_Line_Item__c> invoiceLineItems { get; set; }
	public Decimal vatRate { get; set; }
	public ContentDocumentLink signature { get; set; }

	public InvoicePDFController() {
		Id invoiceId = ApexPages.currentPage().getParameters().get('id');
		this.currentInvoice = [
			SELECT
				Name,
				CreatedDate,
				aforza__Order__c,
				aforza__Due_Date__c,
				NetTotal__c,
				TotalQuantity__c,
				Vat__c,
				Gross__c,
				(
					SELECT Name, SkuCode__c, SkuName__c, Quantity__C, UnitPrice__c, VatRate__c, Vat__c, NetPrice__c
					FROM aforza__Billing_Statement_Line_Items__r
				)
			FROM aforza__Invoice__c
			WHERE Id = :invoiceId
		];
		this.invoiceLineItems = this.currentInvoice.aforza__Billing_Statement_Line_Items__r;
		this.vatRate = this.invoiceLineItems[0].VatRate__c;
		this.associatedOrder = [
			SELECT
				Id,
				BillingStreet,
				BillingCity,
				BillingState,
				BillingPostalCode,
				BillingCountry,
				ShippingStreet,
				ShippingCity,
				ShippingState,
				ShippingPostalCode,
				ShippingCountry,
				AccountId,
				PoNumber,
				DiscountTotal__c,
				PrintName__c
			FROM Order
			WHERE Id = :this.currentInvoice.aforza__Order__c
		];
		this.associatedAccount = [
			SELECT Name, DeliveryPointReference__c, PrimaryPaymentMethod__c, BillToReference__c, CustomerShopNumber__c
			FROM Account
			WHERE Id = :this.associatedOrder.AccountId
		];
		this.signature = [
			SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersionId, ContentDocument.Title
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :associatedOrder.Id AND ContentDocument.Title LIKE 'Signature%'
		];
	}
	@AuraEnabled
	public static void attachPDF(Id invoiceId) {
		try {
			List<Id> invoicesList = new List<Id>();
			invoicesList.add(invoiceId);
			InvoiceService.generatePdfDocument(invoicesList, Page.AGBarrInvoice);
		} catch (Exception e) {
			System.debug(LoggingLevel.Error, e.getStackTraceString());
			throw new AuraHandledException(e.getMessage());
		}
	}
}
