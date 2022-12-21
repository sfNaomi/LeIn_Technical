@IsTest
public class OrderRelationshipRuleValidationTest {
    private static final Integer relationshipRuleQty = 5;

    @TestSetup static void makeData() {
        Account account = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        Product2 product = (Product2) TdfSObjectFactory.insertSObject(new Product2(Family = 'Product', ProductCode = 'TP-001', StockKeepingUnit = 'TP-001'));
        Product2 depositReturnScheme = (Product2) TdfSObjectFactory.insertSObject(new Product2(Family = 'Deposit', ProductCode = 'TP-002', StockKeepingUnit = 'TP-002'));

        aforza__Relationship_Rule__c relationshipRule = new aforza__Relationship_Rule__c(
            RecordTypeId = RecordTypes.RELATIONSHIP_RULE_PRODUCT_ID,
            Name = 'Test Relationship Rule',
            aforza__Source_Product__c = product.Id,
            aforza__Target_Product__c = depositReturnScheme.Id,
            aforza__Quantity__c = relationshipRuleQty,
            aforza__Type__c = 'Addition',
            aforza__Rule_Source__c = 'Aforza Insight',
            aforza__Active__c = true
        );

        insert relationshipRule;

        PricebookEntry productPbe = (PricebookEntry) TdfSObjectFactory.insertSObject(new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = product.Id));
        PricebookEntry depositPbe = (PricebookEntry) TdfSObjectFactory.insertSObject(new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = depositReturnScheme.Id));


        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(AccountId = account.Id, EffectiveDate = System.today(),
            Status = 'Draft', Pricebook2Id = Test.getStandardPricebookId(), RecordTypeId = RecordTypes.ORDER_ECOMMERCE_ID));

        TdfSObjectFactory.insertSObject(new OrderItem(OrderId = order.Id, PricebookEntryId = productPbe.Id, Quantity = 2));
        TdfSObjectFactory.insertSObject(new OrderItem(OrderId = order.Id, PricebookEntryId = depositPbe.Id, Quantity = relationshipRuleQty));
    }

    @IsTest static void testTrigger() {
        List<OrderItem> orderItemsBeforeUpdate = [SELECT Id, Quantity, Product2.Family FROM OrderItem];
        Test.startTest();
        for (OrderItem oi : orderItemsBeforeUpdate) {
            if (oi.Product2.Family != 'Deposit' && oi.Quantity > 0) {
                --oi.Quantity;
            }
        }
        update orderItemsBeforeUpdate;
        Test.stopTest();

        List<OrderItem> orderItemsAfterUpdate = [SELECT Id, Quantity, Product2.Family FROM OrderItem];
        Integer totalQTY = 0;
        Integer nonDepositQTY = 0;
        for (OrderItem oi : orderItemsAfterUpdate) {
            if (oi.Product2.Family != 'Deposit') {
                nonDepositQTY += Integer.valueOf(oi.Quantity);
            }
            totalQTY += Integer.valueOf(oi.Quantity);
        }

        System.assertEquals(nonDepositQTY + (nonDepositQTY * relationshipRuleQty), totalQTY);
    }
}