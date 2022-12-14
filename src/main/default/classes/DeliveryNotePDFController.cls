public without sharing class DeliveryNotePDFController {
    public Order associatedOrder { get; set; }
    public Account associatedAccount { get; set; }
    public List<OrderItem> orderLineItems { get; set; }
    public ContentDocumentLink signature { get; set; }

    public String strOrderIdsContainsOrdItem { get; set; }
    public String strOrderIdsContainsSig { get; set; }

    public Map<Id, Order> mapIdOrder { get; set; }
    public Map<Id, Account> mapOrderIdAccount { get; set; }
    public Map<Id, List<OrderItem>> mapOrderIdlstOrderItem { get; set; }
    public Map<Id, ContentDocumentLink> mapOrderIdContentDoc { get; set; }

    public DeliveryNotePDFController() {
        String orderID = ApexPages.currentPage().getParameters().get('p');
        this.mapIdOrder = new Map<Id, Order>();
        this.mapOrderIdAccount = new Map<Id, Account>();
        this.mapOrderIdlstOrderItem = new Map<Id, List<OrderItem>>();
        this.mapOrderIdContentDoc = new Map<Id, ContentDocumentLink>();
        Set<Id> accountIds = new Set<Id>();
        List<String> lstOrders = orderID.split(',');
        for (Order ord : [
            SELECT
                Id,
                OrderNumber,
                OrderReferenceNumber,
                AccountName__c,
                DeliveryPointReference__c,
                OrderInstructions__c,
                ShippingStreet,
                ShippingCity,
                ShippingState,
                ShippingPostalCode,
                ShippingCountry,
                PrintName__c,
                PoNumber,
                AccountId,
                DeliveryDate__c
            FROM Order
            WHERE Id IN :lstOrders
        ]) {
            mapIdOrder.put(ord.Id, ord);
            accountIds.add(ord.AccountId);
        }

        for (Account acc : [
            SELECT Name, CustomerShopNumber__c, FixedDeliveryInstructions__c, Phone
            FROM Account
            WHERE Id IN :accountIds
        ]) {
            mapOrderIdAccount.put(acc.Id, acc);
        }

        for (OrderItem ordItem : [
            SELECT Id, Product2Id, Product2.StockKeepingUnit, Product2.Name, Quantity, OrderId
            FROM OrderItem
            WHERE OrderId IN :mapIdOrder.keySet() AND aforza__Type__c NOT IN ('Tax', 'Discount', 'Promotion')
        ]) {
            strOrderIdsContainsOrdItem = strOrderIdsContainsOrdItem + ';' + ordItem.OrderId;
            if (mapOrderIdlstOrderItem.containsKey(ordItem.OrderId)) {
                List<OrderItem> lstOrderItem = mapOrderIdlstOrderItem.get(ordItem.OrderId);
                lstOrderItem.add(ordItem);
                mapOrderIdlstOrderItem.put(ordItem.OrderId, lstOrderItem);
            } else {
                mapOrderIdlstOrderItem.put(ordItem.OrderId, new List<OrderItem>{
                    ordItem
                });
            }
        }

        for (ContentDocumentLink contentDocLink : [
            SELECT
                Id,
                ContentDocumentId,
                LinkedEntityId,
                ContentDocument.LatestPublishedVersionId,
                ContentDocument.LatestPublishedVersion.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :mapIdOrder.keySet() AND ContentDocument.Title LIKE 'Signature%'
        ]) {
            mapOrderIdContentDoc.put(contentDocLink.LinkedEntityId, contentDocLink);
            strOrderIdsContainsSig = strOrderIdsContainsSig + ';' + contentDocLink.LinkedEntityId;
        }
    }
}