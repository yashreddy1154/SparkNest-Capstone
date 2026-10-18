public class EnquiryService {

    public static void handleBeforeInsert(List<Enquiry__c> newEnquiries) {
        for (Enquiry__c enq : newEnquiries) {
            // Set default status if blank
            if (String.isBlank(enq.Status__c)) {
                enq.Status__c = 'New';
            }
            // Check minimum customer budget
            if (enq.Customer_Budget__c != null && enq.Customer_Budget__c < 1000) {
                enq.Customer_Budget__c.addError('Customer budget must be at least ₹1,000');
            }
        }
    }

    public static void handleBeforeUpdate(List<Enquiry__c> newEnquiries, Map<Id, Enquiry__c> oldMap) {
        for (Enquiry__c enq : newEnquiries) {
            Enquiry__c oldEnq = oldMap.get(enq.Id);

            if (enq.Customer_Budget__c != null && enq.Customer_Budget__c < 1000) {
                enq.Customer_Budget__c.addError('Customer budget must be at least ₹1,000');
            }

            // Stamp Closed Date when status changes to Closed
            if (enq.Status__c != oldEnq.Status__c && enq.Status__c != null && enq.Status__c.startsWith('Closed')) {
                enq.Closed_Date__c = Date.today();
            }
        }
    }

    public static void handleAfterInsert(List<Enquiry__c> newEnquiries) {
        List<Task> tasksToInsert = new List<Task>();

        for (Enquiry__c enq : newEnquiries) {
            Task t = new Task();
            t.Subject = 'Follow up: ' + (enq.Subject__c != null ? enq.Subject__c : enq.Name);
            t.ActivityDate = Date.today().addDays(3);
            t.OwnerId = (enq.OwnerId != null && String.valueOf(enq.OwnerId).startsWith('005')) ? enq.OwnerId : UserInfo.getUserId();
            t.WhatId = enq.Id;
            t.Status = 'Not Started';
            t.Priority = 'Normal';
            tasksToInsert.add(t);
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }
}
