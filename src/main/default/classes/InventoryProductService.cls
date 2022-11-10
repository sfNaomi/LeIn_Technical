public class InventoryProductService {

	public static void updateInventoryStock(List <aforza__Inventory_Product__c> inventoryProducts) {
	  Decimal totalQuantity;
	  Decimal stockUpdate;
  
	  List <aforza__Inventory_Product__c> inventoryProductsToUpdate = new List <aforza__Inventory_Product__c> ();
	  Map <String, Decimal> mapInventoryIdAndProductQuantitySum = new Map <String, Decimal> ();
	  
	  Set <ID> inventoryProductsId = new Set<Id>();
	  for (aforza__Inventory_Product__c inventoryProduct: inventoryProducts){
	  	inventoryProductsId.add(inventoryProduct.aforza__Product__c);
	}
	  
	   AggregateResult[] quantityInOrders = [SELECT Order.aforza__Inventory__c Inventory, Product2Id product, sum(quantity) summ FROM OrderItem WHERE 
	   Order.RecordType.DeveloperName IN: OrderService.RECORD_TYPES_FOR_STOCK_UPDATE AND Product2Id IN:inventoryProductsId AND ((Order.Status NOT IN: OrderService.UNFULFILLED_ORDER_STATUS) OR
	   (Order.Status = 'Receipted' AND Order.Invoice__r.PushedtoJde__c = FALSE))
           GROUP BY Order.aforza__Inventory__c, Product2Id
	  ];
  
  
	  for (AggregateResult aggResult: quantityInOrders) {
		mapInventoryIdAndProductQuantitySum.put((String) aggResult.get('inventory') + (String) aggResult.get('product'), (Decimal) aggResult.get('summ'));
	  }
  
	  for (aforza__Inventory_Product__c aip: inventoryProducts) {
		String thiskey = String.valueOf(aip.aforza__Inventory__c) + String.valueOf(aip.aforza__Product__c);
  
		  totalQuantity = mapInventoryIdAndProductQuantitySum.get(thisKey);
		if (totalQuantity == null) {
		  totalQuantity = 0;
		}
  
		Decimal JdeStock = aip.JdeStockQuantity__c == null ? 0 : aip.JdeStockQuantity__c;
		Decimal NonSalableStock = aip.NonSalableStock__c == null ? 0 : aip.NonSalableStock__c;
  
		stockUpdate = JdeStock - (NonSalableStock + totalQuantity);
  
		aip.aforza__Stock_Quantity__c = stockUpdate;
		inventoryProductsToUpdate.add(aip);
	  }
  
	  update inventoryProductsToUpdate;
	}
  
  }
