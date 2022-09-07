/**
 * This class was generated with "salesforce-source-gen".
 * Project: https://github.com/kratoon3/salesforce-source-gen
 * Issues: https://github.com/kratoon3/salesforce-source-gen/issues
 */
@IsTest private class RecordTypesTest {

    private static void notNull(Object it) {
        System.assertNotEquals(null, it);
    }
    
    @IsTest private static void test() {
        notNull(RecordTypes.ACCOUNT_CUSTOMER_ID);
        notNull(RecordTypes.ACCOUNT_OUTLET_ID);
    }
}