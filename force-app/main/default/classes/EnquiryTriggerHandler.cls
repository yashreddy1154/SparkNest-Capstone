public class EnquiryTriggerHandler {
    public void beforeInsert(List<Enquiry__c> newList) {
        EnquiryService.handleBeforeInsert(newList);
    }

    public void beforeUpdate(List<Enquiry__c> newList, Map<Id, Enquiry__c> oldMap) {
        EnquiryService.handleBeforeUpdate(newList, oldMap);
    }

    public void afterInsert(List<Enquiry__c> newList) {
        EnquiryService.handleAfterInsert(newList);
    }
}
