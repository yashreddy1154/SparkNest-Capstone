@isTest
public class SparkNestEnquiryAPITest {

    @isTest
    static void testNewCustomerCreatesContactAndEnquiry() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/sparknest/enquiry';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"firstName":"Kiran","lastName":"Rao","email":"kiran.rao@example.com","subject":"Smart Watch Enquiry","enquiryType":"Product Enquiry","budget":5000}');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        SparkNestEnquiryAPI.submitEnquiry();
        Test.stopTest();

        System.assertEquals(201, res.statusCode, 'Status code should be 201');
        System.assertEquals(1, [SELECT COUNT() FROM Contact WHERE Email = 'kiran.rao@example.com']);
        System.assertEquals(1, [SELECT COUNT() FROM Enquiry__c WHERE Subject__c = 'Smart Watch Enquiry']);
    }

    @isTest
    static void testExistingCustomerReusesContact() {
        Contact existing = new Contact(FirstName = 'Rohan', LastName = 'Verma', Email = 'rohan.verma@example.com');
        insert existing;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/sparknest/enquiry';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"name":"Rohan Verma","email":"rohan.verma@example.com","subject":"Care Plan Renewal","enquiryType":"Care Plan Enquiry","planDuration":"24 months","budget":3000}');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        SparkNestEnquiryAPI.submitEnquiry();
        Test.stopTest();

        System.assertEquals(201, res.statusCode, 'Status code should be 201');
        System.assertEquals(1, [SELECT COUNT() FROM Contact WHERE Email = 'rohan.verma@example.com'], 'Should not create duplicate Contact');
    }

    @isTest
    static void testMissingEmailReturns400() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/sparknest/enquiry';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"firstName":"NoEmail","subject":"Test Missing Email"}');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        SparkNestEnquiryAPI.submitEnquiry();
        Test.stopTest();

        System.assertEquals(400, res.statusCode, 'Missing email should return HTTP 400');
    }
}
