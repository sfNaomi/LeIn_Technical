/**
 * This class was generated with "salesforce-source-gen".
 * Project: https://github.com/kratoon3/salesforce-source-gen
 * Issues: https://github.com/kratoon3/salesforce-source-gen/issues
 */
public inherited sharing class RecordTypes {

    public static RecordTypeInfo ACCOUNT_CUSTOMER {
        get {
            return ACCOUNT_CUSTOMER = ACCOUNT_CUSTOMER != null
                    ? ACCOUNT_CUSTOMER : Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer');
        }
        private set;
    }

    public static Id ACCOUNT_CUSTOMER_ID {
        get {
            return ACCOUNT_CUSTOMER.getRecordTypeId();
        }
        private set;
    }

    public static RecordTypeInfo ACCOUNT_OUTLET {
        get {
            return ACCOUNT_OUTLET = ACCOUNT_OUTLET != null
                    ? ACCOUNT_OUTLET : Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Outlet');
        }
        private set;
    }

    public static Id ACCOUNT_OUTLET_ID {
        get {
            return ACCOUNT_OUTLET.getRecordTypeId();
        }
        private set;
    }

    public static RecordTypeInfo VISIT_DIRECT_VISIT {
        get {
            return VISIT_DIRECT_VISIT = VISIT_DIRECT_VISIT != null
                    ? VISIT_DIRECT_VISIT : Schema.SObjectType.aforza__Visit__c.getRecordTypeInfosByDeveloperName().get('Direct_Visit');
        }
        private set;
    }

    public static Id VISIT_DIRECT_VISIT_ID {
        get {
            return VISIT_DIRECT_VISIT.getRecordTypeId();
        }
        private set;
    }

    public static RecordTypeInfo VISIT_REMOTE_VISIT {
        get {
            return VISIT_REMOTE_VISIT = VISIT_REMOTE_VISIT != null
                    ? VISIT_REMOTE_VISIT : Schema.SObjectType.aforza__Visit__c.getRecordTypeInfosByDeveloperName().get('Remote_Visit');
        }
        private set;
    }

    public static Id VISIT_REMOTE_VISIT_ID {
        get {
            return VISIT_REMOTE_VISIT.getRecordTypeId();
        }
        private set;
    }

    public static RecordTypeInfo VISIT_TEMPLATE_VISIT {
        get {
            return VISIT_TEMPLATE_VISIT = VISIT_TEMPLATE_VISIT != null
                    ? VISIT_TEMPLATE_VISIT : Schema.SObjectType.aforza__Visit__c.getRecordTypeInfosByDeveloperName().get('Template_Visit');
        }
        private set;
    }

    public static Id VISIT_TEMPLATE_VISIT_ID {
        get {
            return VISIT_TEMPLATE_VISIT.getRecordTypeId();
        }
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

    public static RecordTypeInfo ASSORTMENT_ACCOUNT_ASSORTMENT {
        get {
            return ASSORTMENT_ACCOUNT_ASSORTMENT = ASSORTMENT_ACCOUNT_ASSORTMENT != null
                    ? ASSORTMENT_ACCOUNT_ASSORTMENT : Schema.SObjectType.aforza__Assortment__c.getRecordTypeInfosByDeveloperName().get('Account_Assortment');
        }
        private set;
    }

    public static Id ASSORTMENT_ACCOUNT_ASSORTMENT_ID {
        get { return ASSORTMENT_ACCOUNT_ASSORTMENT.getRecordTypeId(); }
        private set;
    }

    public static RecordTypeInfo ASSORTMENT_SEGMENT_ASSORTMENT {
        get {
            return ASSORTMENT_SEGMENT_ASSORTMENT = ASSORTMENT_SEGMENT_ASSORTMENT != null
                    ? ASSORTMENT_SEGMENT_ASSORTMENT : Schema.SObjectType.aforza__Assortment__c.getRecordTypeInfosByDeveloperName().get('Segment_Assortment');
        }
        private set;
    }

    public static Id ASSORTMENT_SEGMENT_ASSORTMENT_ID {
        get { return ASSORTMENT_SEGMENT_ASSORTMENT.getRecordTypeId(); }
        private set;
    }
    public static RecordTypeInfo INVENTORY_VEHICLE {
        get {
            return INVENTORY_VEHICLE = INVENTORY_VEHICLE != null
                    ? INVENTORY_VEHICLE : Schema.SObjectType.aforza__Inventory__c.getRecordTypeInfosByDeveloperName().get('Vehicle');
        }
        private set;
    }
    public static Id INVENTORY_VEHICLE_ID {
        get { return INVENTORY_VEHICLE.getRecordTypeId(); }
        private set;
    }
    
    public static RecordTypeInfo INVENTORY_BUILDING {
        get {
            return INVENTORY_BUILDING = INVENTORY_BUILDING != null
                    ? INVENTORY_BUILDING : Schema.SObjectType.aforza__Inventory__c.getRecordTypeInfosByDeveloperName().get('Building');
        }
        private set;
    }

    public static Id INVENTORY_BUILDING_ID {
        get { 
            return INVENTORY_BUILDING.getRecordTypeId(); 
        }
        private set;
    }

    public static RecordTypeInfo PAYMENT_METHOD_CREDIT_CARD {
        get {
            return PAYMENT_METHOD_CREDIT_CARD = PAYMENT_METHOD_CREDIT_CARD != null
                    ? PAYMENT_METHOD_CREDIT_CARD : Schema.SObjectType.aforza__Payment_Method__c.getRecordTypeInfosByDeveloperName().get('Credit_Card');
        }
        private set;
    }

    public static Id PAYMENT_METHOD_CREDIT_CARD_ID {
        get { 
            return PAYMENT_METHOD_CREDIT_CARD.getRecordTypeId(); 
        }
        private set;
    }

    public static RecordTypeInfo BT_PAYMENT_METHOD_CARD {
        get {
            return BT_PAYMENT_METHOD_CARD = BT_PAYMENT_METHOD_CARD != null
                    ? BT_PAYMENT_METHOD_CARD : Schema.SObjectType.bt_stripe__Payment_Method__c.getRecordTypeInfosByDeveloperName().get('Charge_Card');
        }
        private set;
    }

    public static Id BT_PAYMENT_METHOD_CARD_ID {
        get { 
            return BT_PAYMENT_METHOD_CARD.getRecordTypeId(); 
        }
        private set;
    }  
}