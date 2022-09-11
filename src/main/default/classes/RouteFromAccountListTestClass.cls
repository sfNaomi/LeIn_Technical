@IsTest
public class RouteFromAccountListTestClass {
    @TestSetup
    private static void setData() {
        TdfSObjectFactory.insertSObject(new CallCreationSettings__c());
    }

    @IsTest
    public static void validateRouteFromAccountList() {

        List<Account> accts = new List<Account>();

        for (Integer i = 0; i < 5; i++) {
            Account a = new Account(Name = 'TestAccount' + i);
            accts.add(a);
        }
        insert accts;


        Test.startTest();
        PageReference pageRef = Page.RouteFromAccountList;

        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(accts);
        sc.setSelected(accts);

        createRouteFromAccountList contrl = new createRouteFromAccountList(sc);

        contrl.createRoute();

        Test.stopTest();
    }
}