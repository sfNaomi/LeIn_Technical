public class createRouteFromAccountList {
    public List<Account> acctList;
    public String RouteName {get; set;}
    
    public createRouteFromAccountList(ApexPages.StandardSetController stdController) {
        acctList = stdController.getSelected();       
    }
    
    public PageReference createRoute(){
        aforza__Route__c newRoute = new aforza__Route__c();
        newRoute.Name = RouteName;
        newRoute.aforza__Status__c = 'Draft';
        insert newRoute;

        Integer sequence = 1;
        List<aforza__Route_Location__c> newRouteLocations = new List<aforza__Route_Location__c>();
        for (Account acct : acctList) {
            aforza__Route_Location__c newLocation = new aforza__Route_Location__c();

            newLocation.Name = acct.Name;
            newLocation.aforza__Account__c = acct.Id;
            newLocation.aforza__Route__c = newRoute.Id;
            newLocation.aforza__Sequence__c = sequence;

            newRouteLocations.add(newLocation);
            sequence++;
        }
        insert newRouteLocations;
        
        PageReference pr = new PageReference('/lightning/n/aforza__Visit_Planning');
        return pr;
    }
}