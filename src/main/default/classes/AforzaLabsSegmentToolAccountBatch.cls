global class AforzaLabsSegmentToolAccountBatch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, RecordTypeId,' + String.join(AforzaLabsSegmentToolHelper.getAccountFieldNames(), ',') + ' FROM Account';
        return Database.getQueryLocator(query);
    }
     
    global void execute(Database.BatchableContext BC, List<Account> accounts) {
        try {
            AforzaLabsSegmentToolHelper.updatedByBatch = true;
            AforzaLabsSegmentToolAccountHandler.afterInsert(new Map<Id, Account>((List<Account>)accounts));
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, e);
        }
         
    }   
     
    global void finish(Database.BatchableContext BC) {
    }
}