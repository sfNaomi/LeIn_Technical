public class ResetFeatureValuesBatch implements Database.Batchable<sObject> {

    public enum FEATURES { BENCHMARK }

    public String query;
    public FEATURES feature;

    public ResetFeatureValuesBatch(String query, FEATURES feature) {
        this.query = query;
        this.feature = feature;
    }
 
    public Database.QueryLocator start(Database.BatchableContext bc){
       return Database.getQueryLocator(query);
    }
 
    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        switch on feature {
            when BENCHMARK {
                BenchmarkService.resetOutletBenchmark(scope);
            }
        }
    }
 
    public void finish(Database.BatchableContext bc) {
        System.debug('Finish');
    }
 }

