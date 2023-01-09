public class OrderRelationshipRuleValidation {
    final Map<Id, Order> currentOrders;
    Map<Id, Map<Id, Integer>> orderIdProductIdQuantity = new Map<Id, Map<Id, Integer>>();
    final Map<Id, Map<Id, Integer>> expectedRuleQuantities = new Map<Id, Map<Id, Integer>>();
    Map<Id, Product2> productWithRelationship = new Map<Id, Product2>();

    public OrderRelationshipRuleValidation(Map<Id, Order> orderMap) {
        currentOrders = new Map<Id, Order>();

        for (Order o : [SELECT Id, RecordTypeId, (SELECT Product2Id, Quantity FROM OrderItems) FROM Order WHERE Id IN :orderMap.keySet()]) {
            currentOrders.put(o.Id, o);
        }

        generateExpectedItems();
        List<OrderItem> orderItemsToUpdate = fixQuantities(new Map<Id, Order>(currentOrders));
        update orderItemsToUpdate;
    }

    private void generateExpectedItems() {
        orderIdProductIdQuantity = generateMapOrderIdProductIdQuantity(currentOrders);

        productWithRelationship = getProductsWithAutoAdd(currentOrders);

        //loop each order
        for (Id orderId : orderIdProductIdQuantity.keySet()) {

            //map of unique products in order with quantities in basket
            Map<Id, Integer> productIdQuantity = orderIdProductIdQuantity.get(orderId);

            //map of empty products expected in basket with expected quantities
            expectedRuleQuantities.put(orderId, generateExpectedQuantity(productIdQuantity, productWithRelationship));
        }
    }

    public List<OrderItem> fixQuantities(Map<Id, Order> orderMap) {
        List<OrderItem> orderItemsToUpdate = new List<OrderItem>();

        for (Order o : orderMap.values()) {
            Id orderId = o.Id;
            List<OrderItem> orderItems = new List<OrderItem>();
            orderItems = o.OrderItems;

            //map of unique products in order with quantities in basket
            Map<Id, Integer> productIdQuantity = orderIdProductIdQuantity.get(orderId);

            Map<Id, Integer> emptyExpectedQuantity = expectedRuleQuantities.get(orderId);

            //loop products again and check any unexpected containers
            for (Integer i = orderItems.size() - 1; i >= 0; i--) {
                Id productId = orderItems[i].Product2Id;
                if (!emptyExpectedQuantity.containsKey(productId)) {
                    orderItems.remove(i);
                }
            }

            //loop expected empties
            for (Id productId : emptyExpectedQuantity.keySet()) {
                Integer qtyRequired = emptyExpectedQuantity.get(productId);
                Integer qtyIncluded = productIdQuantity.get(productId);
                if (qtyRequired > qtyIncluded) {
                    orderItemsToUpdate.addAll(fixQuantity(qtyRequired, productId, orderItems));
                } else if (qtyRequired != qtyIncluded) {
                    orderItemsToUpdate.addAll(fixQuantity(qtyRequired, productId, orderItems));
                }
            }

        }
        return orderItemsToUpdate;
    }

    private static List<OrderItem> fixQuantity(Integer qty, Id productId, List<OrderItem> orderItems) {
        for (OrderItem orderItem : orderItems) {
            if (productId == orderItem.Product2Id) {
                orderItem.Quantity = qty;
            }
        }
        return orderItems;
    }

    public static Map<Id, Integer> generateExpectedQuantity(Map<Id, Integer> productIdQuantity, Map<Id, Product2> productWithRelationship) {
        Map<Id, Integer> expectedQuantity = new Map<Id, Integer>();
        //loop each distinct product in basket to sum up expected quantities
        for (Id productId : productIdQuantity.keySet()) {
            Integer sourceQuantity = productIdQuantity.get(productId);
            Product2 prd = productWithRelationship.get(productId);
            for (aforza__Relationship_Rule__c rule : prd.aforza__Source_Product_Recommendation_Rules__r) {
                Integer quantity = (Integer) expectedQuantity.get(rule.aforza__Target_Product__c);
                expectedQuantity.put(rule.aforza__Target_Product__c, (Integer) ((sourceQuantity * rule.aforza__Quantity__c) + (quantity != null ? quantity : 0)));
            }
        }
        return expectedQuantity;
    }

    public static Map<Id, Map<Id, Integer>> generateMapOrderIdProductIdQuantity(Map<Id, Order> orderIdOrder) {

        Map<Id, Map<Id, Integer>> orderIdproductIdQuantity = new Map<Id, Map<Id, Integer>>();

        for (Id orderId : orderIdOrder.keySet()) {
            Map<Id, Integer> productIdQuantity = new Map<Id, Integer>();
            orderIdproductIdQuantity.put(orderId, productIdQuantity);
            for (OrderItem oi : orderIdOrder.get(orderId).OrderItems) {
                Integer quantity = productIdQuantity.get(oi.Product2Id);
                productIdQuantity.put(oi.Product2Id, (Integer) oi.Quantity + (quantity != null ? quantity : 0));
            }
        }
        return orderIdproductIdQuantity;
    }

    public static Map<Id, Product2> getProductsWithAutoAdd(Map<Id, Order> orderIdOrder) {

        Set<Id> productIds = new Set<Id>();

        for (Order o : orderIdOrder.values()) {
            for (OrderItem oi : o.OrderItems) {
                productIds.add(oi.Product2Id);
            }
        }

        return new Map<Id, Product2>([
            SELECT Id, Name, Family, ProductCode, (
                SELECT Id, aforza__Quantity__c, aforza__Target_Product__c, aforza__Target_Product__r.Name, aforza__Target_Product__r.Family
                FROM aforza__Source_Product_Recommendation_Rules__r
                WHERE aforza__Active__c = TRUE AND aforza__Type__c = 'Addition'
            )
            FROM Product2
            WHERE Id IN :productIds
        ]);
    }

    private static Map<Id, String> getProductNames(Map<Id, Product2> productWithRelationship) {
        Map<Id, String> addonProducts = new Map<Id, String>();
        for (Product2 prd : productWithRelationship.values()) {
            addonProducts.put(prd.Id, prd.Name);
            for (aforza__Relationship_Rule__c rule : prd.aforza__Source_Product_Recommendation_Rules__r) {
                addonProducts.put(rule.aforza__Target_Product__c, rule.aforza__Target_Product__r.Name);
            }
        }
        return addonProducts;
    }

    private static Map<Id, Map<Id, aforza__Assortment_Product__c>> getAssortmentProducts(Set<Id> assortmentIds) {
        Map<Id, Map<Id, aforza__Assortment_Product__c>> assortmentToProductToAssortmentProduct = new Map<Id, Map<Id, aforza__Assortment_Product__c>>();

        List<aforza__Assortment__c> assortmentsWithProducts = [
            SELECT Id, (SELECT Id, aforza__Product__c FROM aforza__Assortment_Products__r)
            FROM aforza__Assortment__c
            WHERE Id IN :assortmentIds
        ];

        for (aforza__Assortment__c a : assortmentsWithProducts) {
            Map<Id, aforza__Assortment_Product__c> tempMap = new Map<Id, aforza__Assortment_Product__c>();
            for (aforza__Assortment_Product__c ap : a.aforza__Assortment_Products__r) {
                tempMap.put(ap.aforza__Product__c, ap);
            }
            assortmentToProductToAssortmentProduct.put(a.Id, tempMap);
        }

        return assortmentToProductToAssortmentProduct;
    }
}