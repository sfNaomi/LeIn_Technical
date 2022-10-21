/**
 * Created by svatopluk.sejkora on 04.10.2022.
 */

public with sharing class CreateOutletAssetsProductsBatch implements Database.Batchable<SObject> {

    private final List<Product2> focusedProducts;

    public CreateOutletAssetsProductsBatch(List<Product2> focusedProducts){
        this.focusedProducts = focusedProducts;
    }

    public Iterable<SObject> start(Database.BatchableContext batchableContext) {
        String query = 'SELECT Id ' +
                'FROM Account ' +
                'WHERE RecordTypeId = \'' + RecordTypes.ACCOUNT_OUTLET_ID + '\'';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext batchableContext, List<Account> accounts) {
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        FocusProductsService.addNewFocusProducts(accountIds, focusedProducts);
    }

    public void finish(Database.BatchableContext param1) {
    }
}