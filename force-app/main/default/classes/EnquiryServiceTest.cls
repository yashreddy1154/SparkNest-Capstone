@isTest
public class EnquiryServiceTest {

    @isTest
    static void testBlankStatusDefaultsToNew() {
        Enquiry__c enq = new Enquiry__c(
            Subject__c = 'Smart Lock Question',
            Enquiry_Type__c = 'Product Enquiry',
            Customer_Budget__c = 5000
        );
        enq.Status__c = null;

        Test.startTest();
        insert enq;
        Test.stopTest();

        Enquiry__c saved = [SELECT Id, Status__c FROM Enquiry__c WHERE Id = :enq.Id];
        System.assertEquals('New', saved.Status__c, 'Blank status should default to New');
    }

    @isTest
    static void testLowBudgetError() {
        Enquiry__c enq = new Enquiry__c(
            Subject__c = 'Low Budget Test',
            Status__c = 'New',
            Customer_Budget__c = 500
        );

        Boolean errorThrown = false;
        Test.startTest();
        try {
            insert enq;
        } catch (DmlException e) {
            errorThrown = true;
            System.assert(e.getMessage().contains('1,000'), 'Should fail with budget error');
        }
        Test.stopTest();

        System.assertEquals(true, errorThrown, 'Exception should have been thrown for budget < 1000');
    }

    @isTest
    static void testFollowUpTaskCreated() {
        List<Enquiry__c> enqs = TestDataFactory.createEnquiries(1, 'New', 2500);
        
        Test.startTest();
        insert enqs;
        Test.stopTest();

        List<Task> tasks = [SELECT Id, Subject, ActivityDate, OwnerId, WhatId FROM Task WHERE WhatId = :enqs[0].Id];
        System.assertEquals(1, tasks.size(), 'One follow-up task should be created');
        System.assertEquals('Follow up: Test Subject 0', tasks[0].Subject, 'Subject should match');
        System.assertEquals(Date.today().addDays(3), tasks[0].ActivityDate, 'Due date should be 3 days from today');
    }

    @isTest
    static void testClosedDateStampedOnUpdate() {
        List<Enquiry__c> enqs = TestDataFactory.createEnquiries(1, 'New', 3000);
        insert enqs;

        Test.startTest();
        enqs[0].Status__c = 'Closed';
        update enqs[0];
        Test.stopTest();

        Enquiry__c updatedEnq = [SELECT Id, Status__c, Closed_Date__c FROM Enquiry__c WHERE Id = :enqs[0].Id];
        System.assertEquals(Date.today(), updatedEnq.Closed_Date__c, 'Closed Date should be today');
    }

    @isTest
    static void testBulkInsert200Records() {
        List<Enquiry__c> bulkEnqs = TestDataFactory.createEnquiries(200, 'New', 2000);

        Test.startTest();
        insert bulkEnqs;
        Test.stopTest();

        Integer taskCount = [SELECT COUNT() FROM Task WHERE WhatId IN :bulkEnqs];
        System.assertEquals(200, taskCount, '200 tasks should be created for 200 enquiries');
    }

    @isTest
    static void testBatchExecution() {
        List<Enquiry__c> staleEnqs = TestDataFactory.createEnquiries(5, 'In Progress', 4000);
        insert staleEnqs;

        Test.startTest();
        CloseStaleEnquiriesBatch batch = new CloseStaleEnquiriesBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        List<Enquiry__c> closedEnqs = [SELECT Id, Status__c, Closed_Date__c FROM Enquiry__c WHERE Id IN :staleEnqs];
        System.assertEquals('Closed', closedEnqs[0].Status__c, 'Batch should close In Progress enquiries');
        System.assertEquals(Date.today(), closedEnqs[0].Closed_Date__c, 'Closed date should be stamped');
    }

    @isTest
    static void testSchedulerExecution() {
        Test.startTest();
        String cronExp = '0 0 0 * * ?';
        String jobId = System.schedule('Test Nightly Stale Enquiry Job', cronExp, new CloseStaleEnquiriesScheduler());
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Scheduled job should be created');
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cronExp, ct.CronExpression, 'Cron expression should match');
    }
}
