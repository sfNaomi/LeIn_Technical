public class AforzaLabsSegmentToolAccountBatchLaunch {

    public AforzaLabsSegmentToolAccountBatchLaunch(ApexPages.StandardController controller) {

    }
    
	@AuraEnabled
    public static void runBatch() {
        Database.executeBatch(new AforzaLabsSegmentToolAccountBatch());
    }
}