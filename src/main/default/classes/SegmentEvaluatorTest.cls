@IsTest
private class SegmentEvaluatorTest {
	
    @IsTest
    private static void testGetSegmentRules(){
        Test.startTest();
        aforza__Segment__c segment = (aforza__Segment__c) TdfSObjectFactory.insertSObject(
            new aforza__Segment__c(
                Name = 'VIP',
                aforza__Segmentation_Rules__c = '[{\"name\":\"VIP\",\"key\":\"AA-0039\",\"operator\":\"eq\",\"value\":\"true\",\"type\":\"Toggle\"}]'
            )
        );
        Test.stopTest();

       	List<SegmentationRule> expectedResult = new List<SegmentationRule>();
        SegmentationRule parsed = new SegmentationRule();
       	parsed.name = 'VIP';
        parsed.key = 'AA-0039';
        parsed.operator = 'eq';
        parsed.value = 'true';
        parsed.type = 'Toggle';
        expectedResult.add(parsed);

        System.assertEquals(expectedResult.toString(), SegmentEvaluator.getSegmentRules(segment.Id).toString());
    }
    
    @IsTest
    private static void testMain(){
        Test.startTest();
        Account account1 = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                Name = 'Matts Shop',
                ShippingStreet = 'Aforza HQ Cardiff',
                OwnerId = UserInfo.getUserId()
            )
        );

        Account account2 = (Account) TdfSObjectFactory.insertSObject(
            new Account(
                RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID,
                Name = 'James Shop',
                ShippingStreet = 'Aforza HQ Frimley',
                OwnerId = UserInfo.getUserId()
            )
        );

        aforza__Segment__c segment = (aforza__Segment__c) TdfSObjectFactory.insertSObject(
            new aforza__Segment__c(
                Name = 'VIP',
                aforza__Segmentation_Rules__c = '[{\"name\":\"VIP\",\"key\":\"AA-0039\",\"operator\":\"eq\",\"value\":\"true\",\"type\":\"Toggle\"}]'
                        + '[{\"key\":\"AA-0014\",\"name\":\"Point Of Sale Displays\",\"operator\":\"eq\",\"type\":\"Detail\",\"value\":\"4\"}]'
            )
        );

        aforza__Assortment__c assortment = (aforza__Assortment__c) TdfSObjectFactory.insertSObject(
            new aforza__Assortment__c(
                RecordTypeId = RecordTypes.ASSORTMENT_ACCOUNT_ASSORTMENT_ID,
                Name = 'Matts Test Assortment',
                aforza__Target_Segment__c = segment.Id,
                aforza__Segmentation_Rules__c = '[{\"name\":\"Affluent\",\"key\":\"AA-0035\",\"operator\":\"eq\",\"value\":\"true\",\"type\":\"Toggle\"}]'
            )
        );

        aforza__Attribute_Category__c category = (aforza__Attribute_Category__c) TdfSObjectFactory.insertSObject(
            new aforza__Attribute_Category__c(
                Name = 'Test Category',
                aforza__Code__c = '123456',
                aforza__Type__c = 'Account'
            )
        );

        aforza__Attribute__c attribute = (aforza__Attribute__c) TdfSObjectFactory.insertSObject(
            new aforza__Attribute__c(
                Name = 'VIP',
                aforza__Attribute_Category__c = category.Id,
                aforza__Code__c = '12345',
                aforza__Type__c = 'Toggle',
                aforza__Values__c = 'false, true'
            )
        );

        aforza__Attribute__c attribute2 = (aforza__Attribute__c) TdfSObjectFactory.insertSObject(
            new aforza__Attribute__c(
                Name = 'Affluent',
                aforza__Attribute_Category__c = category.Id,
                aforza__Code__c = '123',
                aforza__Type__c = 'Toggle',
                aforza__Values__c = 'false, true'
            )
        );

        aforza__Attribute__c attribute3 = (aforza__Attribute__c) TdfSObjectFactory.insertSObject(
            new aforza__Attribute__c(
                Name = 'Point Of Sale Displays',
                aforza__Attribute_Category__c = category.Id,
                aforza__Code__c = '12345678',
                aforza__Type__c = 'Detail',
                aforza__Values__c = '1, 2, 3, 4'
            )
        );
        
        //Assign VIP to account 1
        TdfSObjectFactory.insertSObject(
            new aforza__Attribute_Assignment__c(
                aforza__Attribute__c  = attribute.Id,
                aforza__Account__c  = account1.Id,
                aforza__Value__c = 'true'
            )
        );

        //Assign VIP to account 2
        TdfSObjectFactory.insertSObject(
            new aforza__Attribute_Assignment__c(
                aforza__Attribute__c  = attribute.Id,
                aforza__Account__c  = account2.Id,
                aforza__Value__c = 'true'
            )
        );

        //Assign Affluent to account 1
        TdfSObjectFactory.insertSObject(
            new aforza__Attribute_Assignment__c(
                aforza__Attribute__c  = attribute2.Id,
                aforza__Account__c  = account1.Id
            )
        );

        //Assign Point of Sales to account 1
        TdfSObjectFactory.insertSObject(
            new aforza__Attribute_Assignment__c(
                aforza__Attribute__c  = attribute3.Id,
                aforza__Account__c  = account1.Id,
                aforza__Value__c = '4'
            )
        );

        //Assign Affluent to account 2
        TdfSObjectFactory.insertSObject(
            new aforza__Attribute_Assignment__c(
                aforza__Attribute__c  = attribute2.Id,
                aforza__Account__c  = account2.Id
            )
        );

        //Assign Point of Sales to account 2
        TdfSObjectFactory.insertSObject(
            new aforza__Attribute_Assignment__c(
                aforza__Attribute__c  = attribute3.Id,
                aforza__Account__c  = account2.Id,
                aforza__Value__c = '4'
            )
        );
        Test.stopTest();

        List<Account> expectedResult = new List<Account>{account1};
        List<Account> actualResult = SegmentEvaluator.displayAccounts(assortment.Id, 'Matt');

        System.assertEquals(expectedResult.size(), actualResult.size());
        System.assertEquals(expectedResult[0].Id, actualResult[0].Id);
    }
}