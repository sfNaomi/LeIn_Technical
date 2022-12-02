public with sharing class ResetBenchmarkScheduler implements Schedulable {
    private static final String QUERY = 'SELECT Id FROM aforza__Outlet_Asset__c '+
                                        'WHERE aforza__Product__r.PsProductEngland__c = true '+
                                        '   OR aforza__Product__r.PsProductScotland__c = true';
    private static final String CRON_EXP = '0 0 0 31 JAN ? *';

    public static void scheduleBenchmarkReset() {
        System.schedule('Outlet Asset Benchmark Reset' + Datetime.now(), CRON_EXP, new ResetBenchmarkScheduler());
    }

    public void execute(SchedulableContext ctx) {
        Database.executeBatch(
            new ResetFeatureValuesBatch(QUERY, ResetFeatureValuesBatch.FEATURES.BENCHMARK)
        );
    }
}
