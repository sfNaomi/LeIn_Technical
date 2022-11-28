/**
 * Created by magdalena.stanciu on 22.11.2022.
 */

public with sharing class OrderRecalculationWidgetController {
    /**
	 * @description perform the recalculation on order based on selected option
	 *
	 * @param orderId id of order to be updated
	 * @param selectedOption recalculation option selected by user
	 *
	 * @return N/A
	 *
	 * @author Magdalena Stanciu
	 * @date 2022-11-23
	 */
    @AuraEnabled
    public static void performRecalculation(Id orderId, String selectedOption) {
        try {
            Map<Id, OrderItem> orderItems = getOrderLineItemsToUpdate(orderId);

            switch on selectedOption {
                when 'ZERO_OUT_AMOUNT_VAT' {
                    zeroOutAmountVat(orderItems);
                }
                when 'PRODUCT_RETURN_REFUND' {
                    productReturnRefund(orderItems);
                }
                when else {
                    throw new PopulateAuraHandledException(Label.InvalidOptionSelected);
                }
            }

            updateOrderRecalculationDate(orderItems.values());

            update orderItems.values();
        } catch (Exception e) {
            throw new PopulateAuraHandledException(e.getMessage());
        }
    }

    /**
	 * @description query line items for order id provided as param
	 *
	 * @param orderId id of order to get line items for
	 *
	 * @return N/A
	 *
	 * @author Magdalena Stanciu
	 * @date 2022-11-23
	 */
    @TestVisible
    private static Map<Id, OrderItem> getOrderLineItemsToUpdate(Id orderId) {
        Map<Id, OrderItem> orderItems = new Map<Id, OrderItem>([
            SELECT Id, Quantity, UnitPrice, aforza__Tax__c, aforza__Tax_Percent__c, aforza__Type__c
            FROM OrderItem
            WHERE OrderId = :orderId
        ]);
        return orderItems;
    }

    /**
     * @description sets amounts (price & tax) to zero on order items
     *
     * @param orderItems map of order items to set the amounts for
     *
     * @return N/A
     *
     * @author Magdalena Stanciu
     * @date 2022-11-23
     */
    @TestVisible
    private static void zeroOutAmountVat(Map<Id, OrderItem> orderItems) {
        for (OrderItem newOrderItem : orderItems.values()) {
            newOrderItem.UnitPrice = 0;
            newOrderItem.aforza__Tax__c = 0;
        }
    }

    /**
     * @description sets amounts (price & tax) to positive/negative values based on type
     *
     * @param orderItems map of order items to set the amounts for
     *
     * @return N/A
     *
     * @author Magdalena Stanciu
     * @date 2022-11-23
     */
    @TestVisible
    private static void productReturnRefund(Map<Id, OrderItem> orderItems) {
        for (OrderItem newOrderItem : orderItems.values()) {
            switch on newOrderItem.aforza__Type__c {
                when 'Product', 'Tax' {
                    newOrderItem.UnitPrice = toNegativeAmount(newOrderItem.UnitPrice);
                    newOrderItem.aforza__Tax__c = toNegativeAmount(newOrderItem.aforza__Tax__c);
                }
                when 'Promotion', 'Discount' {
                    newOrderItem.UnitPrice = toPositiveAmount(newOrderItem.UnitPrice);
                    newOrderItem.aforza__Tax__c = toPositiveAmount(newOrderItem.aforza__Tax__c);
                }
            }
        }
    }

    /**
     * @description converts an amount to a negative value
     *
     * @param initialValue amount to be converted
     *
     * @return converted amount
     *
     * @author Magdalena Stanciu
     * @date 2022-11-23
     */
    @TestVisible
    private static Decimal toNegativeAmount(Decimal initialValue) {
        if (initialValue == null) {
            return null;
        }
        if (initialValue > 0) {
            return initialValue * (-1);
        }
        return initialValue;
    }

    /**
     * @description converts an amount to a positive value
     *
     * @param initialValue amount to be converted
     *
     * @return converted amount
     *
     * @author Magdalena Stanciu
     * @date 2022-11-23
     */
    @TestVisible
    private static Decimal toPositiveAmount(Decimal initialValue) {
        if (initialValue == null) {
            return null;
        }
        if (initialValue < 0) {
            return initialValue * (-1);
        }
        return initialValue;
    }

    /**
    * @description update order recalculation date on order item (to indicate that update was made from LWc and bypass
    *              validation which prevent update of the unit price on order item level
    *
    * @param orderItems list of order items to update date for
    *
    * @return N/A
    *
    * @author Magdalena Stanciu
    * @date 2022-11-28
    */
    private static void updateOrderRecalculationDate(List<OrderItem> orderItems) {
        for (OrderItem item : orderItems) {
            item.OrderRecalculationDate__c = System.now();
        }
    }
}