public with sharing class GetEnquiryStatusAction {

    public class Request {
        @InvocableVariable(
            label='Customer Email'
            description='The email address of the customer asking about their enquiry status'
            required=true
        )
        public String email;
    }

    public class Response {
        @InvocableVariable(label='Record Found' description='True if a Contact and Enquiry were found')
        public Boolean isFound;

        @InvocableVariable(label='Customer Name' description='Name of the matched Contact')
        public String customerName;

        @InvocableVariable(label='Enquiry Number' description='Auto-number of the latest Enquiry')
        public String enquiryNumber;

        @InvocableVariable(label='Enquiry Subject' description='Subject of the latest Enquiry')
        public String subject;

        @InvocableVariable(label='Enquiry Status' description='Current status of the latest Enquiry')
        public String status;

        @InvocableVariable(label='Closed Date' description='Date the Enquiry was closed, if status is Closed')
        public Date closedDate;

        @InvocableVariable(label='Summary Message' description='Formatted status and next step for the agent to reply with')
        public String summaryMessage;
    }

    @InvocableMethod(
        label='Get Latest Enquiry Status By Email'
        description='Finds a Contact by email and retrieves their most recent Enquiry status, closed date, and recommended next steps.'
    )
    public static List<Response> getStatus(List<Request> requests) {
        List<Response> results = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();
            res.isFound = false;

            if (String.isBlank(req.email)) {
                res.summaryMessage = 'No email address was provided. Please ask the customer to check their email or submit a new enquiry.';
                results.add(res);
                continue;
            }

            List<Contact> contacts = [
                SELECT Id, Name, Email
                FROM Contact
                WHERE Email = :req.email.trim()
                LIMIT 1
            ];

            if (contacts.isEmpty()) {
                res.summaryMessage = 'No customer record was found for ' + req.email + '. Please ask the customer to check their email address or submit a new enquiry.';
                results.add(res);
                continue;
            }

            Contact c = contacts[0];
            res.customerName = c.Name;

            List<Enquiry__c> enquiries = [
                SELECT Id, Name, Subject__c, Status__c, Closed_Date__c, CreatedDate
                FROM Enquiry__c
                WHERE Contact__c = :c.Id
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            if (enquiries.isEmpty()) {
                res.summaryMessage = 'A Contact record was found for ' + req.email + ', but no Enquiry records exist yet. Ask the customer if they would like to submit a new enquiry.';
                results.add(res);
                continue;
            }

            Enquiry__c latest = enquiries[0];
            res.isFound = true;
            res.enquiryNumber = latest.Name;
            res.subject = latest.Subject__c;
            res.status = latest.Status__c;
            res.closedDate = latest.Closed_Date__c;

            if (latest.Status__c != null && latest.Status__c.startsWithIgnoreCase('Closed')) {
                String closedDateStr = latest.Closed_Date__c != null ? latest.Closed_Date__c.format() : 'recently';
                res.summaryMessage = 'Enquiry ' + latest.Name + ' (' + latest.Subject__c + ') is ' + latest.Status__c + ' as of ' + closedDateStr + '. Offer to raise a new enquiry if the customer needs further assistance.';
            } else {
                res.summaryMessage = 'Enquiry ' + latest.Name + ' (' + latest.Subject__c + ') is currently open with status "' + latest.Status__c + '". Let the customer know our team is reviewing it and will follow up shortly.';
            }

            results.add(res);
        }

        return results;
    }
}