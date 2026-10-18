@IsTest
private class GetEnquiryStatusActionTest {

    @IsTest
    static void testOpenClosedAndUnknownScenarios() {
        Contact c = new Contact(FirstName = 'Agent', LastName = 'Tester', Email = 'agent.tester@sparknest.com');
        insert c;

        Enquiry__c enq = new Enquiry__c(
            Subject__c = 'Smart Lock Warranty',
            Enquiry_Type__c = 'Care Plan Enquiry',
            Contact__c = c.Id,
            Status__c = 'In Progress',
            Customer_Budget__c = 2500
        );
        insert enq;

        // 1. Open Enquiry Scenario
        GetEnquiryStatusAction.Request reqOpen = new GetEnquiryStatusAction.Request();
        reqOpen.email = 'agent.tester@sparknest.com';
        List<GetEnquiryStatusAction.Response> resOpen = GetEnquiryStatusAction.getStatus(new List<GetEnquiryStatusAction.Request>{ reqOpen });
        System.assertEquals(true, resOpen[0].isFound, 'Should find open enquiry');
        System.assertEquals('In Progress', resOpen[0].status);

        // 2. Closed Enquiry Scenario
        enq.Status__c = 'Closed';
        update enq;

        List<GetEnquiryStatusAction.Response> resClosed = GetEnquiryStatusAction.getStatus(new List<GetEnquiryStatusAction.Request>{ reqOpen });
        System.assertEquals('Closed', resClosed[0].status);
        System.assertNotEquals(null, resClosed[0].closedDate, 'Closed Date should be stamped');

        // 3. Unknown Email Scenario
        GetEnquiryStatusAction.Request reqUnknown = new GetEnquiryStatusAction.Request();
        reqUnknown.email = 'nobody@nowhere.com';
        List<GetEnquiryStatusAction.Response> resUnknown = GetEnquiryStatusAction.getStatus(new List<GetEnquiryStatusAction.Request>{ reqUnknown });
        System.assertEquals(false, resUnknown[0].isFound, 'Should return false for unknown email');
    }
}