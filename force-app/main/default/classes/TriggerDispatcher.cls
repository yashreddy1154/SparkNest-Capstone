public class TriggerDispatcher {
    public static void run(EnquiryTriggerHandler handler) {
        if (Trigger.isBefore && Trigger.isInsert) {
            handler.beforeInsert((List<Enquiry__c>) Trigger.new);
        }
        if (Trigger.isBefore && Trigger.isUpdate) {
            handler.beforeUpdate((List<Enquiry__c>) Trigger.new, (Map<Id, Enquiry__c>) Trigger.oldMap);
        }
        if (Trigger.isAfter && Trigger.isInsert) {
            handler.afterInsert((List<Enquiry__c>) Trigger.new);
        }
    }
}
