/**
 * This class was generated with "salesforce-source-gen".
 * Project: https://github.com/kratoon3/salesforce-source-gen
 * Issues: https://github.com/kratoon3/salesforce-source-gen/issues
 */
@IsTest private class RecordTypesTest {
    private static void notNull(Object it) {
        System.assertNotEquals(null, it);
    }
    
    @IsTest private static void testAccountRecordTypes() {
        notNull(RecordTypes.ACCOUNT_CUSTOMER_ID);
        notNull(RecordTypes.ACCOUNT_OUTLET_ID);
    }

    @IsTest private static void testOrderRecordTypes() {
        notNull(RecordTypes.ORDER_RT_INFO_BY_DEV_NAME);
        notNull(RecordTypes.ORDER_RT_INFO_BY_ID);
        notNull(RecordTypes.ORDER_FIELD_DIRECT_ID);
        notNull(RecordTypes.ORDER_ECOMMERCE_ID);
        notNull(RecordTypes.ORDER_TELESALES_ID);
        notNull(RecordTypes.ORDER_EDI_ID);
        notNull(RecordTypes.ORDER_RETURN_ID);
        notNull(RecordTypes.ORDER_STRAIGHT_TO_JDE_ID);
        notNull(RecordTypes.ORDER_VAN_SALES_ID);
    }

    @IsTest private static void testAssortmentRecordTypes() {
        notNull(RecordTypes.ASSORTMENT_ACCOUNT_ASSORTMENT);
        notNull(RecordTypes.ASSORTMENT_ACCOUNT_ASSORTMENT_ID);
        notNull(RecordTypes.ASSORTMENT_SEGMENT_ASSORTMENT);
        notNull(RecordTypes.ASSORTMENT_SEGMENT_ASSORTMENT_ID);
    }

    @IsTest private static void testInventoryTypes() {
        notNull(RecordTypes.INVENTORY_BUILDING);
        notNull(RecordTypes.INVENTORY_BUILDING_ID);
    }
}