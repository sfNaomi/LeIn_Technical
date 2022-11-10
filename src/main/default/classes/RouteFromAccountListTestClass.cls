@IsTest
private class RouteFromAccountListTestClass {
    @IsTest
    private static void testCreateRoute() {
        List<Account> newAccounts = (List<Account>) TdfSObjectFactory.insertSObjects(
            new Account(RecordTypeId = RecordTypes.ACCOUNT_OUTLET_ID), 5
        );

        List<Account> insertedAccounts = [SELECT Id, Name FROM Account];

        Test.startTest();
        PageReference pageRef = Page.RouteFromAccountList;

        ApexPages.StandardSetController standardCtrl = new ApexPages.StandardSetController(insertedAccounts);
        standardCtrl.setSelected(insertedAccounts);
                      
        createRouteFromAccountList ctrl = new createRouteFromAccountList(standardCtrl);
        ctrl.createRoute();
        Test.stopTest();

        List<aforza__Route__c> routes = [
            SELECT Id, aforza__Status__c,
            (
                    SELECT Id, Name, aforza__Account__c, aforza__Sequence__c
                    FROM aforza__Route_Locations__r
            )
            FROM aforza__Route__c
        ];

        System.assertEquals(1, routes.size());
        System.assertEquals('Draft', routes[0].aforza__Status__c);

        System.assertEquals(insertedAccounts.size(), routes[0].aforza__Route_Locations__r.size());
        for(Integer index = 0; index < insertedAccounts.size(); index++) {
            aforza__Route_Location__c location = routes[0].aforza__Route_Locations__r[index];
            System.assertEquals(insertedAccounts[index].Name, location.Name);
            System.assertEquals(insertedAccounts[index].Id, location.aforza__Account__c);
            System.assertEquals(index + 1, location.aforza__Sequence__c);
        }
    }
}