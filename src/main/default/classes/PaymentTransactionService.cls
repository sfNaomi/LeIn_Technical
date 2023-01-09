public with sharing class PaymentTransactionService {

    private static final String PAID_INVOICE_STATUS = 'Paid';
    private static final String APPLIED_TRANSACTION_STATUS = 'Applied';
    private static final String REJECTED_TRANSACTION_STATUS = 'Rejected';
    private static final String PENDING_TRANSACTION_STATUS = 'Pending';
    private static final String CUSTOMER_PAYMENT_TRANSACTION_TYPE = 'Customer Payment';
    private static final String UNSUCCESSFUL_INVOICE_STATUS = 'Payment Attempt Unsuccessful';

    private static final Set<String> PAYMENT_METHOD_RT_IDS = new Set<String>{
        RecordTypes.PAYMENT_METHOD_DIRECT_CARD_ID, RecordTypes.PAYMENT_METHOD_BANK_ACCOUNT_ID
    };

    public static void createPaymentTransactionFromOrders(Set<Id> orderIdsToCreatePaymentTransactionFrom) {
        Map<Id, Order> parentOrders = new Map<Id, Order>([
            SELECT Id, AccountId, PaymentMethod__c, Status, TotalAmount FROM Order 
            WHERE Id IN :orderIdsToCreatePaymentTransactionFrom
        ]);

        List<aforza__Payment_Transaction__c> newPaymentTransactions = new List<aforza__Payment_Transaction__c>();
        
        Set<Id> parentAccountIds = new Set<Id>();
        for(Order ord: parentOrders.values() ){
            parentAccountIds.add(ord.AccountId);
        }
        Map<String, aforza__Payment_Method__c> primaryMethodToPaymentRecord = new Map<String, aforza__Payment_Method__c>();
        for(aforza__Payment_Method__c pMethod: [SELECT Id, aforza__Account__c, RecordTypeId FROM aforza__Payment_Method__c
                                                WHERE aforza__Account__c IN: parentAccountIds AND 
                                                      aforza__Active__c = TRUE AND
                                                      RecordTypeId IN :PAYMENT_METHOD_RT_IDS])
        {
            if (pMethod.RecordTypeId == RecordTypes.PAYMENT_METHOD_DIRECT_CARD_ID) {
                primaryMethodToPaymentRecord.put((pMethod.aforza__Account__c+'Direct Debit'), pMethod);
            }
            if (pMethod.RecordTypeId == RecordTypes.PAYMENT_METHOD_BANK_ACCOUNT_ID) {
                primaryMethodToPaymentRecord.put((pMethod.aforza__Account__c+'Bacs'), pMethod);
            }
            if (pMethod.RecordTypeId == RecordTypes.PAYMENT_METHOD_JDE_DD_ID) {
                primaryMethodToPaymentRecord.put((pMethod.aforza__Account__c+'JDE DD'), pMethod);
            }
        }

        for( Order ord: parentOrders.values() ) {
            String uniqueKey = ord.AccountId + ord.PaymentMethod__c;
            aforza__Payment_Transaction__c pt = prepareDDAndBacsTransactionFromOrder(ord);
            pt.aforza__Payment_Method__c = primaryMethodToPaymentRecord.containsKey(uniqueKey) ? primaryMethodToPaymentRecord.get(uniqueKey).Id : null;
            newPaymentTransactions.add(pt);
        }
        insert newPaymentTransactions;
    }

    private static aforza__Payment_Transaction__c prepareDDAndBacsTransactionFromOrder(Order ord) {
        aforza__Payment_Transaction__c pt = new aforza__Payment_Transaction__c();
        pt.aforza__Amount__c = ord.TotalAmount;
        pt.aforza__Status__c = PENDING_TRANSACTION_STATUS;
        pt.OrderNumber__c = ord.Id;
        pt.aforza__Account__c = ord.AccountId;
        pt.aforza__Type__c = CUSTOMER_PAYMENT_TRANSACTION_TYPE; 
        pt.aforza__Method__c = ord.PaymentMethod__c;
        return pt;
    }

    public static void updatePaymentTransactionStatusForInvoices(Set<Id> invoiceIds) {
        List<aforza__Payment_Transaction__c> pTransactionsToUpdate = new List<aforza__Payment_Transaction__c>();
        for(aforza__Payment_Transaction__c pTransaction : [SELECT aforza__Invoice__r.aforza__Status__c  FROM aforza__Payment_Transaction__c 
                                                           WHERE aforza__Invoice__c IN :invoiceIds]) 
        {
            pTransactionsToUpdate.add(new aforza__Payment_Transaction__c(
                Id = pTransaction.Id,
                aforza__Status__c = getPaymentTransactionStatusByInvoiceStatus(pTransaction.aforza__Invoice__r.aforza__Status__c)
            ));
        }
        update pTransactionsToUpdate;
    }

    private static String getPaymentTransactionStatusByInvoiceStatus(String invoiceStatus) {
        switch on invoiceStatus {
            when 'Payment Attempt Unsuccessful' {
                return REJECTED_TRANSACTION_STATUS;
            }
            when 'Paid' {
                return APPLIED_TRANSACTION_STATUS;
            }
        }
        return null;
    }
}
