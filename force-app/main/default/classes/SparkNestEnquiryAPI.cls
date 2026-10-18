@RestResource(urlMapping='/sparknest/enquiry/*')
global with sharing class SparkNestEnquiryAPI {

    @HttpPost
    global static void submitEnquiry() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            String body = req.requestBody != null ? req.requestBody.toString() : '{}';
            Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(body);

            String email = (String) params.get('email');
            String firstName = (String) params.get('firstName');
            String lastName = (String) params.get('lastName');
            String name = (String) params.get('name');
            String phone = (String) params.get('phone');
            String subject = (String) params.get('subject');
            String enquiryType = (String) params.get('enquiryType');
            String source = (String) params.get('source');
            String planDuration = (String) params.get('planDuration');

            // Gracefully normalize plan duration if needed
            if (planDuration == '1 Year' || planDuration == '1 year') {
                planDuration = '12 months';
            } else if (planDuration == '2 Years' || planDuration == '2 years') {
                planDuration = '24 months';
            }

            Decimal budget = null;
            if (params.get('budget') != null) {
                budget = Decimal.valueOf(String.valueOf(params.get('budget')));
            }

            // Scenario 3: Missing email -> HTTP 400
            if (String.isBlank(email)) {
                res.statusCode = 400;
                Map<String, Object> err = new Map<String, Object>{
                    'success' => false,
                    'message' => 'Missing required field: email is required to submit an enquiry.'
                };
                res.responseBody = Blob.valueOf(JSON.serialize(err));
                return;
            }

            // Check if Contact already exists by Email
            List<Contact> existingContacts = [SELECT Id, FirstName, LastName, Email FROM Contact WHERE Email = :email LIMIT 1];
            Contact targetContact;
            Boolean isNewContact = false;

            if (!existingContacts.isEmpty()) {
                // Scenario 2: Existing customer found
                targetContact = existingContacts[0];
            } else {
                // Scenario 1: New customer -> create Contact
                isNewContact = true;
                if (String.isBlank(lastName)) {
                    if (String.isNotBlank(name) && name.contains(' ')) {
                        List<String> parts = name.split(' ', 2);
                        firstName = parts[0];
                        lastName = parts[1];
                    } else if (String.isNotBlank(name)) {
                        lastName = name;
                    } else {
                        lastName = 'Customer';
                    }
                }

                targetContact = new Contact(
                    FirstName = firstName,
                    LastName = lastName,
                    Email = email,
                    Phone = phone
                );
                insert targetContact;
            }

            // Create linked Enquiry
            Enquiry__c newEnq = new Enquiry__c();
            newEnq.Contact__c = targetContact.Id;
            newEnq.Subject__c = String.isNotBlank(subject) ? subject : 'Website Enquiry';
            newEnq.Enquiry_Type__c = String.isNotBlank(enquiryType) ? enquiryType : 'Product Enquiry';
            newEnq.Source__c = String.isNotBlank(source) ? source : 'Web';
            newEnq.Status__c = 'New';
            newEnq.Plan_Duration__c = planDuration;
            newEnq.Customer_Budget__c = budget;
            insert newEnq;

            res.statusCode = 201;
            Map<String, Object> successResp = new Map<String, Object>{
                'success' => true,
                'message' => isNewContact ? 'New Contact and Enquiry created successfully.' : 'Existing Contact matched and Enquiry created successfully.',
                'isNewContact' => isNewContact,
                'contactId' => targetContact.Id,
                'enquiryId' => newEnq.Id
            };
            res.responseBody = Blob.valueOf(JSON.serialize(successResp));

        } catch (Exception e) {
            res.statusCode = 400;
            Map<String, Object> err = new Map<String, Object>{
                'success' => false,
                'message' => e.getMessage()
            };
            res.responseBody = Blob.valueOf(JSON.serialize(err));
        }
    }
}
