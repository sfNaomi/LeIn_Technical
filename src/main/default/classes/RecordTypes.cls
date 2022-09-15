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
    public static Map<Id, Schema.RecordTypeInfo> ORDER_RT_INFO_BY_ID {
        get { return ORDER_RT_INFO_BY_ID = ORDER_RT_INFO_BY_ID != null
                ? ORDER_RT_INFO_BY_ID : Schema.SObjectType.Order.getRecordTypeInfosById(); }
        private set;
    }
    public static Map<String, Schema.RecordTypeInfo> ORDER_RT_INFO_BY_DEV_NAME {
        get { return ORDER_RT_INFO_BY_DEV_NAME = ORDER_RT_INFO_BY_DEV_NAME != null
                ? ORDER_RT_INFO_BY_DEV_NAME : Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName(); }
        private set;
    }
    public static RecordTypeInfo ORDER_FIELD_DIRECT {
        get { return ORDER_RT_INFO_BY_DEV_NAME.get('FieldDirectOrder'); }
        private set;
    }
    public static Id ORDER_FIELD_DIRECT_ID {
        get { return ORDER_FIELD_DIRECT.getRecordTypeId(); }
        private set;
    }
    public static RecordTypeInfo ORDER_ECOMMERCE {
        get { return ORDER_RT_INFO_BY_DEV_NAME.get('ECommerceOrder'); }
        private set;
    }
    public static Id ORDER_ECOMMERCE_ID {
        get { return ORDER_ECOMMERCE.getRecordTypeId(); }
        private set;
    }
    public static RecordTypeInfo ORDER_TELESALES {
        get { return ORDER_RT_INFO_BY_DEV_NAME.get('TelesalesOrder'); }
        private set;
    }
    public static Id ORDER_TELESALES_ID {
        get { return ORDER_TELESALES.getRecordTypeId(); }
        private set;
    }
    public static RecordTypeInfo ORDER_EDI {
        get { return ORDER_RT_INFO_BY_DEV_NAME.get('EDIOrder'); }
        private set;
    }
    public static Id ORDER_EDI_ID {
        get { return ORDER_EDI.getRecordTypeId(); }
        private set;
    }
    public static RecordTypeInfo ORDER_RETURN {
        get { return ORDER_RT_INFO_BY_DEV_NAME.get('ReturnOrder'); }
        private set;
    }
    public static Id ORDER_RETURN_ID {
        get { return ORDER_RETURN.getRecordTypeId(); }
        private set;
    }
    public static RecordTypeInfo ORDER_STRAIGHT_TO_JDE {
        get { return ORDER_RT_INFO_BY_DEV_NAME.get('StraightToJDEOrder'); }
        private set;
    }
    public static Id ORDER_STRAIGHT_TO_JDE_ID {
        get { return ORDER_STRAIGHT_TO_JDE.getRecordTypeId(); }
        private set;
    }
    public static RecordTypeInfo ORDER_VAN_SALES {
        get { return ORDER_RT_INFO_BY_DEV_NAME.get('VanSalesOrder'); }
        private set;
    }
    public static Id ORDER_VAN_SALES_ID {
        get { return ORDER_VAN_SALES.getRecordTypeId(); }
        private set;
    }
}
