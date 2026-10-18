for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'Nightly Close Stale Enquiries']) {
    System.abortJob(ct.Id);
}
System.schedule('Nightly Close Stale Enquiries', '0 0 0 * * ?', new CloseStaleEnquiriesScheduler());
