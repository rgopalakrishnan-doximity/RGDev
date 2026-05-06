public class COInvoiceScheduleController {
    
     @InvocableMethod(label='Create CO Invoice Schedules')
    public static List<List<Invoice_Schedule__c>> CreateCOInvSch(List<String> recordId) {
        
        Amendment__c amend = [SELECT id, Opportunity__r.ID, Parent_Opportunity__r.ID
                              FROM Amendment__c WHERE Id =:recordId Limit 1];
        List<string> Opps = new List<string>();
        Opps.add(amend.Opportunity__r.ID);
        if (amend.Parent_Opportunity__r.ID != null) opps.add(amend.Parent_Opportunity__r.ID);
        system.debug(Opps);
        List<Invoice_Schedule__c> lstInvoices = [select id, Invoicing_Milestone__c,Sequence__c,Invoice_Schedule_Type__c,
                                                Invoice_Date__c,Invoice_Amount__c,status__c, Invoice_Date_Verbiage__c  
                                                from Invoice_Schedule__c where Opportunity__c IN :Opps
                                                and status__c = 'Approved' order by createdDate, Sequence__c  ASC];
        integer i = 1;
        List<Invoice_Schedule__c> lstCOInvoices = new  List<Invoice_Schedule__c>();
        if (lstInvoices.size() > 0){
            for (Invoice_Schedule__c inv : lstInvoices){
                Invoice_Schedule__c coinv = new Invoice_Schedule__c();
                coinv.Contract_Amendment__c = recordId[0] ;
                coinv.Opportunity__c = amend.Opportunity__r.ID;
                coinv.Invoice_Date__c = inv.Invoice_Date__c;
                coinv.Invoicing_Milestone__c = inv.Invoicing_Milestone__c;
                coinv.Invoice_Amount__c =  inv.Invoice_Amount__c;
                coinv.Invoice_Date_Verbiage__c = inv.Invoice_Date_Verbiage__c;
                coinv.Sequence__c = inv.Sequence__c;
                coinv.Name = 'Version:1 -' + i; 
                coinv.Version__c = 1; 
                coinv.Status__c = 'Created';
                coinv.Invoice_Schedule_Type__c = inv.Invoice_Schedule_Type__c;
                lstCOInvoices.add(coinv);
                i = i+1;
            }
            insert lstCOInvoices;
        }
        
        List<List<Invoice_Schedule__c>> result = new  List<List<Invoice_Schedule__c>> ();
        
    	      
        result.add(lstCOInvoices);
        system.debug(result);
        return result;
        
    }

}