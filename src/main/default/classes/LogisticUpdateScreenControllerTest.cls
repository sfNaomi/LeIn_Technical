/**
 * Created by svatopluk.sejkora on 07.10.2022.
 */

@IsTest
private class LogisticUpdateScreenControllerTest {

    @IsTest
    private static void testFetchNeededPicklistValues() {
        Test.startTest();
        List<LogisticUpdateScreenController.PicklistDto> picklists = LogisticUpdateScreenController.fetchNeededPicklistValues('Order', new List<String>{'Status', 'Depot__c'});
        Test.stopTest();

        Assert.isTrue(!picklists.isEmpty(), 'There should be values in the returned list of picklists');
    }

    @IsTest
    private static void testUpdateOrderFields_PrintPickSheet() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Status' => 'Picking in Progress', 'PickingSheetPrinted__c' => true
        };
        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));

        Test.startTest();
        LogisticUpdateScreenController.updateRecords(new List<String>{order.Id}, fieldValues);
        Test.stopTest();

        List<Order> updatedOrder = [SELECT Id, Status, PickingSheetPrinted__c FROM Order];

        Assert.areEqual(1, updatedOrder.size());
        Assert.areEqual(fieldValues.get('Status'), updatedOrder[0].Status);
        Assert.areEqual(fieldValues.get('PickingSheetPrinted__c'), updatedOrder[0].PickingSheetPrinted__c);
    }

    @IsTest
    private static void testUpdateOrderFields_Picked() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Status' => 'Ready to Load', 'PickingCompleted__c' => true
        };
        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));

        Test.startTest();
        LogisticUpdateScreenController.updateRecords(new List<String>{order.Id}, fieldValues);
        Test.stopTest();

        List<Order> updatedOrder = [SELECT Id, Status, PickingCompleted__c FROM Order];

        Assert.areEqual(1, updatedOrder.size());
        Assert.areEqual(fieldValues.get('Status'), updatedOrder[0].Status);
        Assert.areEqual(fieldValues.get('PickingCompleted__c'), updatedOrder[0].PickingCompleted__c);
    }

    @IsTest
    private static void testUpdateOrderFields_PrintManifest() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'DeliveryManifestPrinted__c' => true
        };
        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));

        Test.startTest();
        LogisticUpdateScreenController.updateRecords(new List<String>{order.Id}, fieldValues);
        Test.stopTest();

        List<Order> updatedOrder = [SELECT Id, DeliveryManifestPrinted__c FROM Order];

        Assert.areEqual(1, updatedOrder.size());
        Assert.areEqual(fieldValues.get('DeliveryManifestPrinted__c'), updatedOrder[0].DeliveryManifestPrinted__c);
    }

    @IsTest
    private static void testUpdateRecords_PrintInvoice() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'InvoicePrinted__c' => true
        };
        aforza__Invoice__c newInvoice = (aforza__Invoice__c) TdfSObjectFactory.insertSObject(new aforza__Invoice__c());

        Test.startTest();
        LogisticUpdateScreenController.updateRecords(new List<String>{newInvoice.Id}, fieldValues);
        Test.stopTest();

        List<aforza__Invoice__c> updatedInvoice = [SELECT Id, InvoicePrinted__c FROM aforza__Invoice__c];

        Assert.areEqual(1, updatedInvoice.size());
        Assert.areEqual(fieldValues.get('InvoicePrinted__c'), updatedInvoice[0].InvoicePrinted__c);
    }

    @IsTest
    private static void testUpdateRecords_PrintDeliveryNote() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'DeliveryNotePrinted__c' => true
        };
        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));

        Test.startTest();
        LogisticUpdateScreenController.updateRecords(new List<String>{order.Id}, fieldValues);
        Test.stopTest();

        List<Order> updatedOrder = [SELECT Id, DeliveryNotePrinted__c FROM Order];

        Assert.areEqual(1, updatedOrder.size());
        Assert.areEqual(fieldValues.get('DeliveryNotePrinted__c'), updatedOrder[0].DeliveryNotePrinted__c);
    }

    @IsTest
    private static void testUpdateOrderFields_Loaded() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Status' => 'Pending Delivery', 'IsLoaded__c' => true
        };
        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));

        Test.startTest();
        LogisticUpdateScreenController.updateRecords(new List<String>{order.Id}, fieldValues);
        Test.stopTest();

        List<Order> updatedOrder = [SELECT Id, Status, IsLoaded__c FROM Order];

        Assert.areEqual(1, updatedOrder.size());
        Assert.areEqual(fieldValues.get('Status'), updatedOrder[0].Status);
        Assert.areEqual(fieldValues.get('IsLoaded__c'), updatedOrder[0].IsLoaded__c);
    }

    @IsTest
    private static void testUpdateOrderFields_Receipted() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Status' => 'Receipted', 'Receipt__c' => true
        };
        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));

        Test.startTest();
        LogisticUpdateScreenController.updateRecords(new List<String>{order.Id}, fieldValues);
        Test.stopTest();

        List<Order> updatedOrder = [SELECT Id, Status, Receipt__c FROM Order];

        Assert.areEqual(1, updatedOrder.size());
        Assert.areEqual(fieldValues.get('Status'), updatedOrder[0].Status);
        Assert.areEqual(fieldValues.get('Receipt__c'), updatedOrder[0].Receipt__c);
    }

    @IsTest
    private static void testUpdateOrderFields_CancelOrder() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Status' => 'Cancelled', 'DeliveryFailed__c' => true
        };
        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));

        Test.startTest();
        LogisticUpdateScreenController.updateRecords(new List<String>{order.Id}, fieldValues);
        Test.stopTest();

        List<Order> updatedOrder = [SELECT Id, Status, DeliveryFailed__c FROM Order];

        Assert.areEqual(1, updatedOrder.size());
        Assert.areEqual(fieldValues.get('Status'), updatedOrder[0].Status);
        Assert.areEqual(fieldValues.get('DeliveryFailed__c'), updatedOrder[0].DeliveryFailed__c);
    }

    @IsTest
    private static void testUpdateOrderFields_Replan() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Status' => 'Unplanned', 'Replanned__c' => true
        };
        Order order = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));

        Test.startTest();
        LogisticUpdateScreenController.updateRecords(new List<String>{order.Id}, fieldValues);
        Test.stopTest();

        List<Order> updatedOrder = [SELECT Id, Status, Replanned__c FROM Order];

        Assert.areEqual(1, updatedOrder.size());
        Assert.areEqual(fieldValues.get('Status'), updatedOrder[0].Status);
        Assert.areEqual(fieldValues.get('Replanned__c'), updatedOrder[0].Replanned__c);
    }

    @IsTest
    private static void testUpdateOrderFields_NoOrderIds() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Status' => 'Unplanned', 'Replanned__c' => true
        };

        Test.startTest();
        try {
            LogisticUpdateScreenController.updateRecords(new List<String>(), fieldValues);
            Assert.isTrue(false);
        } catch (PopulateAuraHandledException ex) {
            Assert.isTrue(true);
        }
        Test.stopTest();
    }

    @IsTest
    private static void testUpdateOrderFields_NoFieldValues() {
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));

        Test.startTest();
        try {
            LogisticUpdateScreenController.updateRecords(new List<String>{newOrder.Id}, new Map<String, Object>());
            Assert.isTrue(false);
        } catch (PopulateAuraHandledException ex) {
            Assert.isTrue(true);
        }
        Test.stopTest();
    }

    @IsTest
    private static void testUpdateOrderFields_WrongFieldName() {
        Map<String, Object> fieldValues = new Map<String, Object>{
            'Test' => 'Test'
        };
        Order newOrder = (Order) TdfSObjectFactory.insertSObject(new Order(RecordTypeId = RecordTypes.ORDER_TELESALES_ID));

        Test.startTest();
        try {
            LogisticUpdateScreenController.updateRecords(new List<String>{newOrder.Id}, fieldValues);
            Assert.isTrue(false);
        } catch (PopulateAuraHandledException ex) {
            Assert.isTrue(true);
        }
        Test.stopTest();
    }
}