/**
 * Created by svatopluk.sejkora on 05.10.2022.
 */

@IsTest
private with sharing class OutletAssetTriggerHandlerTest {

    @IsTest
    private static void testDeleteAttributesForFocusedProducts() {
        // create NonStockis attribute category
        TdfSObjectFactory.insertSObject(new aforza__Attribute_Category__c());
        Account acc = (Account) TdfSObjectFactory.insertSObject(new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID));

        Test.startTest();
        Product2 prod = (Product2) TdfSObjectFactory.insertSObject(new Product2(FocusFiveProduct__c = true, FocusFiveGroup__c = 'GROUP'));
        Test.stopTest();

        List<aforza__Outlet_Asset__c> assets = [SELECT Id, aforza__Product_Code__c FROM aforza__Outlet_Asset__c WHERE aforza__Account__c = :acc.Id];
        System.debug(assets);
        System.assertEquals(1, assets.size());

        List<aforza__Attribute__c> attributes = [SELECT Id, aforza__Code__c FROM aforza__Attribute__c WHERE aforza__Code__c = :prod.StockKeepingUnit];
        System.assertEquals(1, attributes.size());

        // assign attribute manually
        aforza__Attribute_Assignment__c assignment = new aforza__Attribute_Assignment__c(aforza__Account__c = acc.Id, aforza__Attribute__c = attributes[0].Id);
        insert assignment;

        delete assets;

        List<aforza__Attribute_Assignment__c> assignmentsAfterDel = [SELECT Id FROM aforza__Attribute_Assignment__c WHERE aforza__Account__c = :acc.Id];
        System.assertEquals(0, assignmentsAfterDel.size());

    }
}