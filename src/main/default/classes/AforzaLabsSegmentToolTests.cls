@IsTest
private class AforzaLabsSegmentToolTests {
	
    @TestSetup
    private static void setup() {
        aforza__Attribute_Category__c category = (aforza__Attribute_Category__c) TdfSObjectFactory.insertSObject(
            new aforza__Attribute_Category__c(
                Name = 'Attribute Trigger Category',
                aforza__Code__c = 'ATC',
                aforza__Type__c = 'Account'
            )
        );

       // Channel Partner / Reseller=Channel Partner / Reseller, Customer - Channel=Customer - Channel, Customer - Direct=Customer - Direct
       //     , Installation Partner=Installation Partner, Other=Other, Small=Small, Medium=Medium}
        aforza__Attribute__c newAttribute = (aforza__Attribute__c) TdfSObjectFactory.insertSObject(
            new aforza__Attribute__c(
                Name = 'Account Type',
                aforza__Type__c = 'Choice',
                aforza__Attribute_Category__c = category.Id,
                aforza__Code__c = 'AT05',
                aforza__Values__c = 'Small,Medium',
                aforza__Active__c = true
            )
        );
    }

    private static void setAccountMappingTypeField() {
        setAccountMappingTypeField('Type', 'Customer,Outlet');
    }

    private static void setAccountMappingTypeField(String fieldName, String recordTypes) {
        List<Object> mockMapping = new List<Object>{ new Map<String, Object> {
            'attributes' => new Map<String, Object>{'type' => 'AforzaLabsSegmentToolConfig__mdt'},
            'Object__r' => new Map<String, Object>{'attributes' => new Map<String, Object>{'type' => 'EntityDefinition'}, 'QualifiedApiName' => 'Account'},
            'Field__r' => new Map<String, Object>{'attributes' => new Map<String, Object>{'type' => 'FieldDefinition'},'QualifiedApiName' => fieldName},
            'Attribute_Code__c' => 'AT05',
            'Active__c' => true,
            'Record_Types__c' => recordTypes
        }};

        List<AforzaLabsSegmentToolConfig__mdt> mapping = (List<AforzaLabsSegmentToolConfig__mdt>) JSON.deserialize(
            JSON.serialize(mockMapping), List<AforzaLabsSegmentToolConfig__mdt>.class
        );
        AforzaLabsSegmentToolHelper.configs = mapping;
    }
    
    @IsTest
    private static void testAccountInsert() {
        setAccountMappingTypeField();

        Test.startTest();
        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                Type = 'Small'
            )
        );
        Test.stopTest();

        List<aforza__Attribute_Assignment__c> aas = [
            SELECT Id, aforza__Value__c,aforza__Attribute__r.aforza__Code__c
            FROM aforza__Attribute_Assignment__c 
            WHERE aforza__Account__c = :acc.Id
        ];

        System.assertEquals(1, aas.size());
        System.assertEquals('Small', aas[0].aforza__Value__c);
        System.assertEquals('AT05', aas[0].aforza__Attribute__r.aforza__Code__c);
    }

    @IsTest
    private static void testAccountUpdate() {
        setAccountMappingTypeField();

        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                Type = 'Medium'
            )
        );

        List<aforza__Attribute_Assignment__c> aas = [
            SELECT Id, aforza__Value__c,aforza__Attribute__r.aforza__Code__c 
            FROM aforza__Attribute_Assignment__c 
            WHERE aforza__Account__c = :acc.Id
        ];

        System.assertEquals(1, aas.size());
        System.assertEquals('Medium', aas[0].aforza__Value__c);
        System.assertEquals('AT05', aas[0].aforza__Attribute__r.aforza__Code__c);

        Test.startTest();
        acc.Type = 'Small';
        update acc;
        Test.stopTest();

        aas = [
            SELECT Id, aforza__Value__c,aforza__Attribute__r.aforza__Code__c 
            FROM aforza__Attribute_Assignment__c 
            WHERE aforza__Account__c = :acc.Id
        ];

        System.assertEquals(1, aas.size());
        System.assertEquals('Small', aas[0].aforza__Value__c);
        System.assertEquals('AT05', aas[0].aforza__Attribute__r.aforza__Code__c);
    }
    
    @IsTest
    private static void testAccountNull() {
        setAccountMappingTypeField();

        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                Type = 'Medium'
            )
        );
        List<aforza__Attribute_Assignment__c> aas = [
            SELECT Id, aforza__Value__c,aforza__Attribute__r.aforza__Code__c 
            FROM aforza__Attribute_Assignment__c 
            WHERE aforza__Account__c = :acc.Id
        ];

        System.assertEquals(1, aas.size());
        System.assertEquals('Medium', aas[0].aforza__Value__c);
        System.assertEquals('AT05', aas[0].aforza__Attribute__r.aforza__Code__c);

        Test.startTest();
        acc.Type = null;
        update acc;
        Test.stopTest();

        aas = [
            SELECT Id, aforza__Value__c,aforza__Attribute__r.aforza__Code__c 
            FROM aforza__Attribute_Assignment__c 
            WHERE aforza__Account__c = :acc.Id
        ];

        System.assertEquals(0, aas.size());
    }
    
    @IsTest
    private static void testAccountDelete() {
        setAccountMappingTypeField();

        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                Type = 'Medium'
            )
        );
        List<aforza__Attribute_Assignment__c> aas = [
            SELECT Id, aforza__Value__c,aforza__Attribute__r.aforza__Code__c 
            FROM aforza__Attribute_Assignment__c 
            WHERE aforza__Account__c = :acc.Id
        ];

        System.assertEquals(1, aas.size());

        Test.startTest();
        delete acc;
        Test.stopTest();

        aas = [
            SELECT Id, aforza__Value__c,aforza__Attribute__r.aforza__Code__c 
            FROM aforza__Attribute_Assignment__c
        ];

        System.assertEquals(0, aas.size());
    }

    @IsTest
    private static void testAttributeInsert() {
        setAccountMappingTypeField();

        aforza__Attribute__c attr = [SELECT Id FROM aforza__Attribute__c WHERE aforza__Code__c = 'AT05'];
        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID
            )
        );

        Account insertedAccount = [SELECT Type FROM Account];
        System.assertEquals(null , insertedAccount.Type);

        Test.startTest();
        aforza__Attribute_Assignment__c assignment = (aforza__Attribute_Assignment__c) TdfSObjectFactory.insertSObject(
            new aforza__Attribute_Assignment__c(
                aforza__Account__c = acc.Id,
                aforza__Attribute__c = attr.Id,
                aforza__Value__c ='Small'
            )
        );
        Test.stopTest();

        Account updatedAccount = [SELECT Type FROM Account];
        System.assertEquals('Small', updatedAccount.Type);
    }
    
    @IsTest
    private static void testAttributeUpdate() {
        setAccountMappingTypeField();

        aforza__Attribute__c attr = [SELECT Id FROM aforza__Attribute__c WHERE aforza__Code__c = 'AT05'];
        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID
            )
        );
        aforza__Attribute_Assignment__c ass = (aforza__Attribute_Assignment__c) TdfSObjectFactory.insertSObject(
                new aforza__Attribute_Assignment__c(
                        aforza__Account__c = acc.Id,
                        aforza__Attribute__c = attr.Id,
                        aforza__Value__c ='Small'
                )
        );

        Account insertedAccount = [SELECT Type FROM Account];
        System.assertEquals('Small', insertedAccount.Type);

        Test.startTest();
        ass.aforza__Value__c = 'Medium';
        update ass;
        Test.stopTest();

        Account updatedAccount = [SELECT Type FROM Account];
        System.assertEquals('Medium', updatedAccount.Type);
    }

    @IsTest
    private static void testAttributeDelete() {
        setAccountMappingTypeField();

        aforza__Attribute__c attr = [SELECT Id FROM aforza__Attribute__c WHERE aforza__Code__c = 'AT05'];
        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID
            )
        );
        aforza__Attribute_Assignment__c ass = (aforza__Attribute_Assignment__c) TdfSObjectFactory.insertSObject(
            new aforza__Attribute_Assignment__c(
                aforza__Account__c = acc.Id,
                aforza__Attribute__c = attr.Id,
                aforza__Value__c ='Small'
            )
        );

        Account insertedAccount = [SELECT Type FROM Account];
        System.assertEquals('Small', insertedAccount.Type);

        Test.startTest();
        delete ass;
        Test.stopTest();

        Account updatedAccount = [SELECT Type FROM Account];
        System.assertEquals(null, updatedAccount.Type);
    }

    @IsTest
    private static void testBatch() {
        setAccountMappingTypeField();

        AforzaLabsSegmentToolHelper.updatedByTrigger = true;

        Account acc = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                Type = 'Small'
            )
        );

        AforzaLabsSegmentToolHelper.updatedByTrigger = false;

        List<aforza__Attribute_Assignment__c> aas = [
            SELECT Id, aforza__Value__c,aforza__Attribute__r.aforza__Code__c 
            FROM aforza__Attribute_Assignment__c 
            WHERE aforza__Account__c = :acc.Id
        ];

        System.assertEquals(0, aas.size());

        Test.startTest();
        AforzaLabsSegmentToolAccountBatchLaunch.runBatch();
        Test.stopTest();

        aas = [
            SELECT Id, aforza__Value__c,aforza__Attribute__r.aforza__Code__c 
            FROM aforza__Attribute_Assignment__c 
            WHERE aforza__Account__c = :acc.Id
        ];

        System.assertEquals(1, aas.size());
        System.assertEquals('Small', aas[0].aforza__Value__c);
        System.assertEquals('AT05', aas[0].aforza__Attribute__r.aforza__Code__c);
    }
}