public class COInvoiceScheduleUpdateController {
    
    @InvocableMethod(label=' CO Invoice Schedules')
    public static void CreateCOInvSch(List<String> recordId) {
        
         List<Invoice_Schedule__c> lstInvoices = [select id, Invoicing_Milestone__c,Sequence__c,Invoice_Schedule_Type__c,
                                                Invoice_Date__c,Invoice_Amount__c,status__c, Invoice_Date_Verbiage__c  
                                                from Invoice_Schedule__c where Contract_Amendment__c = :recordId
                                                order by Invoice_Date__c ASC NULLS LAST];
        integer seq = 1;
        List<Invoice_Schedule__c> lstUpdateInvoices = new  List<Invoice_Schedule__c> ();
        for(Invoice_Schedule__c inv : lstInvoices){
            inv.Sequence__c = seq;
            lstUpdateInvoices.add(inv);
            seq = seq + 1;
        }
        update lstUpdateInvoices;
    }

}