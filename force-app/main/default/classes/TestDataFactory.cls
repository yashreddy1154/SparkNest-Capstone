@isTest
public class TestDataFactory {

    public static Contact createContact(String firstName, String lastName, String email) {
        Contact c = new Contact(
            FirstName = firstName,
            LastName = lastName,
            Email = email
        );
        insert c;
        return c;
    }

    public static List<Enquiry__c> createEnquiries(Integer count, String status, Decimal budget) {
        List<Enquiry__c> listEnq = new List<Enquiry__c>();
        for (Integer i = 0; i < count; i++) {
            Enquiry__c enq = new Enquiry__c();
            enq.Subject__c = 'Test Subject ' + i;
            enq.Enquiry_Type__c = 'Product Enquiry';
            enq.Status__c = status;
            enq.Customer_Budget__c = budget;
            enq.Priority__c = 'Medium';
            listEnq.add(enq);
        }
        return listEnq;
    }
}
