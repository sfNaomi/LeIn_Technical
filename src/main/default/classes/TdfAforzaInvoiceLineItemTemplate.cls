/**
 * @description       :
 * @author            : Ciuca Bianca BearingPoint GmbH
 * @group             :
 * @last modified on  : 10-06-2022
 * @last modified by  : Ciuca Bianca, BearingPoint GmbH
 **/
@IsTest
public with sharing class TdfAforzaInvoiceLineItemTemplate extends TdfSObjectTemplate {
	private Id invoiceRecordId;

	public override void init() {
		aforza__Invoice_Line_Item__c userDefinedVisitRecord = (aforza__Invoice_Line_Item__c) userDefinedSObject;

		if (userDefinedVisitRecord.aforza__Invoice__c == null) {
			invoiceRecordId = TdfSObjectFactory.insertSObject(new aforza__Invoice__c()).Id;
		}
	}
	protected override SObject createTemplateSObject() {
		aforza__Invoice_Line_Item__c template = new aforza__Invoice_Line_Item__c(aforza__Invoice__c = invoiceRecordId);

		return template;
	}
}
