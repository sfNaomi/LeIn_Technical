/**
 * This class was generated with "salesforce-source-gen".
 * Project: https://github.com/kratoon3/salesforce-source-gen
 * Issues: https://github.com/kratoon3/salesforce-source-gen/issues
 */
public inherited sharing class RecordTypes {

    public static RecordTypeInfo ACCOUNT_CUSTOMER {
        get { return ACCOUNT_CUSTOMER = ACCOUNT_CUSTOMER != null
                ? ACCOUNT_CUSTOMER : Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer'); }
        private set;
    }
    public static Id ACCOUNT_CUSTOMER_ID {
        get { return ACCOUNT_CUSTOMER.getRecordTypeId(); }
        private set;
    }
    public static RecordTypeInfo ACCOUNT_OUTLET {
        get { return ACCOUNT_OUTLET = ACCOUNT_OUTLET != null
                ? ACCOUNT_OUTLET : Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Outlet'); }
        private set;
    }
    public static Id ACCOUNT_OUTLET_ID {
        get { return ACCOUNT_OUTLET.getRecordTypeId(); }
        private set;
    }
}
