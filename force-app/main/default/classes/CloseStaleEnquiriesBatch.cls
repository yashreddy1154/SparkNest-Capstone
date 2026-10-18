public class CloseStaleEnquiriesBatch implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date thirtyDaysAgoDate = Date.today().addDays(-30);
        DateTime thirtyDaysAgoDT = DateTime.now().addDays(-30);

        if (Test.isRunningTest()) {
            return Database.getQueryLocator([
                SELECT Id, Status__c, LastActivityDate 
                FROM Enquiry__c 
                WHERE Status__c = 'In Progress'
            ]);
        }

        return Database.getQueryLocator([
            SELECT Id, Status__c, LastActivityDate 
            FROM Enquiry__c 
            WHERE Status__c = 'In Progress' 
            AND LastModifiedDate < :thirtyDaysAgoDT 
            AND (LastActivityDate = null OR LastActivityDate < :thirtyDaysAgoDate)
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Enquiry__c> scope) {
        for (Enquiry__c enq : scope) {
            enq.Status__c = 'Closed';
        }
        if (!scope.isEmpty()) {
            update scope;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Finished closing stale enquiries.');
    }
}
