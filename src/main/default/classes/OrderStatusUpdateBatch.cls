/**
 * Created by svatopluk.sejkora on 23.01.2023.
 *
 * this should be scheduled only once at any time you need to. Reschedule will happen at finish method.
 * to schedule: System.schedule('Order Status Change', '0 40 * * * ?', new OrderStatusUpdateBatch());
 */

public without sharing class OrderStatusUpdateBatch implements Schedulable, Database.Batchable<SObject> {

    private static final String SCHEDULE_FORMAT = '0 m H d MM ? yyyy';
    private static final Set<String> EXCLUDED_ORDER_TYPES = new Set<String>{RecordTypes.ORDER_STRAIGHT_TO_JDE_ID, RecordTypes.ORDER_VAN_SALES_ID};
    private static final String STRAIGHT_TO_JDE_RECORD_TYPE_ID = RecordTypes.ORDER_STRAIGHT_TO_JDE_ID;
    private static final String JOB_NAME = 'Order Status Change';

    public Iterable<SObject> start(Database.BatchableContext batchableContext) {
        // load all order records that should be moved to completed
        String query = 'SELECT Id, Status, RecordTypeId FROM Order ' +
            'WHERE (Status = \'Delivered\' AND RecordTypeId NOT IN :EXCLUDED_ORDER_TYPES) ' +
            'OR (Status = \'Activated\' AND RecordTypeId = :STRAIGHT_TO_JDE_RECORD_TYPE_ID)';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext batchableContext, List<Order> orders) {
        OrderService.updateOrderStatus(orders, 'Receipted');
        InvoiceService.createInvoicesFromOrdersBatch(orders);
    }

    public void finish(Database.BatchableContext param1) {
        // delete old runs
        clearOldScheduledApexJobs();
        // schedule new run
        Datetime nextTime = System.now().addMinutes(10);
        String jobName = JOB_NAME + ' ' + System.now().getTime();
        String scheduleTime = nextTime.format(SCHEDULE_FORMAT);
        System.schedule(jobName, scheduleTime, new OrderStatusUpdateBatch());
    }

    public void execute(SchedulableContext schedulableContext) {
        Database.executeBatch(this, 500);
    }

    private static void clearOldScheduledApexJobs() {
        String pattern = JOB_NAME + '%';
        for (CronTrigger cron : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE :pattern AND (State = 'DELETED' OR State = 'COMPLETE')]) {
            System.abortJob(cron.Id);
        }
    }
}