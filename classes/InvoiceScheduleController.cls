public class InvoiceScheduleController {
    
  
    @AuraEnabled(cacheable=true)
    public static List<InvoiceScheduleApex> getPreviousInvoices(String recordId) {
        
        Amendment__c amend = [SELECT id, Opportunity__r.ID, Parent_Opportunity__r.ID, First_SOW__c
                              FROM Amendment__c WHERE Id =:recordId Limit 1];
        
       
		List<string> Opps = new List<string>();
        opps.add(amend.Opportunity__r.ID);
        if (amend.Parent_Opportunity__r.ID != null) opps.add(amend.Parent_Opportunity__r.ID);
        
        //find the latest of the inv schedules from COs
        List<Amendment__c> prevInvAmend = [SELECT id FROM Amendment__c WHERE Opportunity__c IN :Opps
                              AND Amendment_Type__c includes ('Change to Invoice Schedule') 
                              and Amendment_Status__c = 'Fully Executed' order by createdDate DESC LIMIT 1];
        
        List<Invoice_Schedule__c> lstInvoices = new List<Invoice_Schedule__c>();
     	
        if (prevInvAmend.size() > 0){
           lstInvoices = [select id, Invoicing_Milestone__c,
                                                Invoice_Date__c,Invoice_Amount__c,status__c 
                                                from Invoice_Schedule__c where status__c = 'Approved' and Contract_Amendment__c != :prevInvAmend[0].id order by createdDate, Sequence__c   ASC];
        }else{
            lstInvoices = [select id, Invoicing_Milestone__c,
                                                Invoice_Date__c,Invoice_Amount__c,status__c 
                                                from Invoice_Schedule__c where  status__c = 'Approved' and Contract_Amendment__c = :amend.First_SOW__c order by Sequence__c   ASC];
        
        }
        string invClass = '';
        List<InvoiceScheduleApex> lstWrap = new List<InvoiceScheduleApex>();
        for (Invoice_Schedule__c inv: lstInvoices){
            lstWrap.add(new InvoiceScheduleApex(inv.id, inv.Invoicing_Milestone__c,
                                               inv.Invoice_Date__c, inv.Invoice_Amount__c, inv.Status__c, invClass));
        }
       	system.debug('here--' + lstWrap);
    	return lstWrap;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<InvoiceScheduleApex> getModifiedInvoices(String recordId) {
        
        Amendment__c amend = [SELECT id, Opportunity__r.ID, Parent_Opportunity__r.ID
                              FROM Amendment__c WHERE Id =:recordId Limit 1];
		List<string> invStatus = new List<string>();
        invStatus.add('Approved');
        invStatus.add('Created');              
        
        List<Invoice_Schedule__c> lstInvoices = [select id, Invoicing_Milestone__c,COUpdate__c,
                                                Invoice_Date__c,Invoice_Amount__c,status__c 
                                                from Invoice_Schedule__c where Contract_Amendment__c = :recordId
                                                and status__c IN :invStatus order by  Sequence__c   ASC];
        string invClass = 'slds-text-color_destructive';
        List<InvoiceScheduleApex> lstWrap = new List<InvoiceScheduleApex>();
        for (Invoice_Schedule__c inv: lstInvoices){
            invClass = (inv.COUpdate__c == true) ? 'slds-text-color_destructive' : '';
            lstWrap.add(new InvoiceScheduleApex(inv.id, inv.Invoicing_Milestone__c,
                                               inv.Invoice_Date__c, inv.Invoice_Amount__c, inv.Status__c, invClass));
        }
       	system.debug('here--' + lstWrap);
    	return lstWrap;
    }
    
    
    @InvocableMethod(label='Get Previous Invoice Schedules')
    public static List<List<Invoice_Schedule__c>> getCOInvoices(List<String> recordId) {
        
        //and Replaced__c = false - to be used if we have multiple Inv Schedules
        
        Opportunity Opp = [select id, type, Parent_Opportunity__r.ID from Opportunity where id= :recordId[0] ];
        List<string> Opps = new List<string>();
        Opps.add(Opp.ID);
        if (Opp.Parent_Opportunity__r.ID != null) opps.add(Opp.Parent_Opportunity__r.ID);
        system.debug(Opps);
        //find the latest of the inv schedules from COs
        List<Amendment__c> prevInvAmend = [SELECT id FROM Amendment__c WHERE Opportunity__c IN :Opps
                              AND Amendment_Type__c includes ('Change to Invoice Schedule') 
                              and Amendment_Status__c = 'Fully Executed' order by createdDate DESC LIMIT 1];
       
        List<Invoice_Schedule__c> lstInvoices = new List<Invoice_Schedule__c>();
        
        if (prevInvAmend.size() > 0){
            system.debug('fetching the previous CO Invoice');
            lstInvoices = [select id, Invoicing_Milestone__c,
                                                Invoice_Date__c,Invoice_Amount__c,status__c 
                                                from Invoice_Schedule__c where Contract_Amendment__c = :prevInvAmend[0].id
                                                and status__c = 'Approved' and Invoice_Date__c > TODAY order by  Sequence__c   ASC];
        }else{
            system.debug('fetching the SOW Invoice');
            lstInvoices = [select id, Invoicing_Milestone__c,
                                                Invoice_Date__c,Invoice_Amount__c,status__c 
                                                from Invoice_Schedule__c where Opportunity__c IN :Opps
                                                and status__c = 'Approved' and Invoice_Date__c > TODAY order by  Sequence__c   ASC];
            
        }
        
        
        List<List<Invoice_Schedule__c>> result = new  List<List<Invoice_Schedule__c>> ();
    	      
        result.add(lstInvoices);
        system.debug(result);
        return result;
        
    }
    
    
   
}