/**
 * Class provides functionality for creating default order items in test methods.
 *
 * Do not use this class directly.
 * Class is initialized in TDF_SObjectTemplateFactory and all its functionality is used through TDF_SObjectFactory.
 *
 * @see TdfSObjectFactory
 * @see TdfSObjectTemplate
 * @see TdfSObjectTemplateFactory
 *
 * @author  Magdalena Stanciu
 * @date    2022-09-20
 *
 */
@IsTest
public with sharing class TdfOrderItemTemplate extends TdfSObjectTemplate {
    private Id orderId;
    private Id product2Id;
    private Id pricebookEntryId;

    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Magdalena Stanciu
     * @date    2022-09-20
     *
     */
    public override void init() {
        OrderItem userDefinedOrderItem = (OrderItem) userDefinedSObject;

        if (userDefinedOrderItem.OrderId == null) {
            orderId = TdfSObjectFactory.insertSObject(new Order()).Id;
        }
        if (userDefinedOrderItem.Product2Id == null) {
            product2Id = TdfSObjectFactory.insertSObject(new Product2()).Id;
        }
        if (userDefinedOrderItem.PricebookEntryId == null) {
            Id newProductId = product2Id == null ? userDefinedOrderItem.Product2Id : product2Id;
            pricebookEntryId = TdfSObjectFactory.insertSObject(new PricebookEntry(Product2Id = newProductId)).Id;
        }
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return template with order item record
     *
     * @author  Magdalena Stanciu
     * @date    2022-09-20
     *
     */
    protected override SObject createTemplateSObject() {
        OrderItem template = new OrderItem(
                OrderId = orderId,
                Product2Id = product2Id,
                PricebookEntryId = pricebookEntryId,
                Quantity = 1,
                UnitPrice = 10
        );

        return template;
    }
}