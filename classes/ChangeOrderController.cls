public class ChangeOrderController {
    
    @AuraEnabled(cacheable=true)
    public static List<ChangeOrderApex> getChangeOrders(String recordId) {
        system.debug('here--' + recordId);
        
        List<String> ProductLevelCOs = new List<String>{'Start Date Change', 'End Date Change ONLY', 'Target Change', 'Extension', 'Actual Launch', 'Segmentation Change'};
        
        List<Amended_Products__c> APs = new List<Amended_Products__c>();
 		APs = [SELECT id,Version__c,status__c,Opportunity_Product_ID__c,
               Opportunity__c,Contract_Amendment__c,Amendment_Type__c,
               Opportunity_Product__r.Product_Name__c,
               Opportunity_Product__r.Quantity,
               Opportunity_Product__r.Segmentation__c,
               Opportunity_Product__r.Contractual_Start_Date__c,
               Opportunity_Product__r.Contractual_End_Date__c,
               Opportunity_Product__r.Custom_List_Targets__c,
               Parent_Product__r.Custom_List_Targets__c,
               Opportunity_Product__r.Guarantee__r.Engagements_Formula__c,
               Opportunity_Product__r.Guarantee__r.Audience_URL__c,
               Opportunity_Product__r.Guarantee__r.Merged_Guarantees__c,
               Opportunity_Product__r.ED_Mismatch__c,Amended_Segmentation__c,
               Amended_Agency__c,Amended_Agency_3rd_Party_Transfer_Date__c,
               Amended_Contractual_Start_Date__c, Original_Max_Targets_Per_Month__c,
               Amended_Contractual_End_Date__c,New_Engagements__c,Product_Name__c,
               Amended_Max_Targets_Per_Month__c, New_Target_List_URL__c,New_Merged_Guarantee__c,
               Opportunity_Product__r.term__r.First_Deliverable_Launch_Date_Term__c,
                Opportunity_Product__r.Projected_End_Date__c,Contractual_Start_Date_Formula__c 
                                        FROM Amended_Products__c
                                        where Contract_Amendment__c = :recordId  
               							and  status__c  IN ('Requested', 'Fully Executed' ) 
               							and Amendment_Type__c IN :ProductLevelCOs
               							order by Product_Name__c ];
        Date SDate = Date.today();
        Date EDate = Date.today();
        integer target = 0;
        integer Engagements = 0;
        string Audienceurl = '';
        string MergedGuarantees = '';
        string dateclass = 'slds-text-color_destructive';
        string targetclass = 'slds-text-color_destructive';
        string edmismatchclass = '';
        string edurl = '';
        string actuallaunchclass = '';
        string segmentationclass = '';
        string segment = '';
        List<ChangeOrderApex> lstWrap = new List<ChangeOrderApex>();
        for (Amended_Products__c AP : APs){
            
            if (AP.Amendment_Type__c == 'Start Date Change' || AP.Amendment_Type__c == 'End Date Change ONLY'){
                if (AP.Amendment_Type__c == 'Start Date Change'){
         	       SDate = AP.Amended_Contractual_Start_Date__c;
            	   EDate = SDate.addMonths(Integer.Valueof(AP.Opportunity_Product__r.Quantity)) - 1;
            	   //EDate = (AP.Opportunity_Product__r.Contractual_End_Date__c).addMonths(Integer.Valueof(AP.Opportunity_Product__r.Quantity));
                   system.debug('edate--' + EDate);
                }else if (AP.Amendment_Type__c == 'End Date Change ONLY'){
                   EDate = AP.Amended_Contractual_End_Date__c;
                   SDate = AP.Contractual_Start_Date_Formula__c; //EDate.addMonths(-Integer.Valueof(AP.Opportunity_Product__r.Quantity)) + 1;
                }
                dateclass = 'slds-text-color_destructive';
            }else{
                SDate = AP.Opportunity_Product__r.Contractual_Start_Date__c;
                EDate = AP.Opportunity_Product__r.Contractual_End_Date__c;
                dateclass = '';
            }
			
            if( AP.Amendment_Type__c  == 'Target Change'){
                targetclass = 'slds-text-color_destructive';
                if (AP.Amended_Max_Targets_Per_Month__c != null){
               	 	target = Integer.valueof(AP.Amended_Max_Targets_Per_Month__c) + Integer.valueof(AP.Original_Max_Targets_Per_Month__c);
                }
                
                Engagements = (AP.New_Engagements__c != null) ? Integer.Valueof(AP.New_Engagements__c) : 0 ; 
                Audienceurl = AP.New_Target_List_URL__c; 
                MergedGuarantees = AP.New_Merged_Guarantee__c; 
                edurl =  'Pending Review';
               	edmismatchclass = 'slds-text-color_destructive';   
              
            }else{
                targetclass = '';
                target = Integer.valueof(AP.Opportunity_Product__r.Custom_List_Targets__c);
                Engagements = Integer.Valueof(AP.Opportunity_Product__r.Guarantee__r.Engagements_Formula__c);
                Audienceurl = AP.Opportunity_Product__r.Guarantee__r.Audience_URL__c;
                MergedGuarantees = AP.Opportunity_Product__r.Guarantee__r.Merged_Guarantees__c;
                if ((AP.Opportunity_Product__r.ED_Mismatch__c).contains('flag_yellow')){
                   edurl =  'Not Approved';
                   edmismatchclass = 'slds-text-color_destructive';
                }else if ((AP.Opportunity_Product__r.ED_Mismatch__c).contains('flag_red')){
                   edurl =  'Not Approved';
                   edmismatchclass = 'slds-text-color_destructive';
                }else{
                    edurl =  'Approved';        
                    edmismatchclass = 'slds-text-color_success';
                }
            
            }
           
            if (AP.Opportunity_Product__r.term__r.First_Deliverable_Launch_Date_Term__c > AP.Opportunity_Product__r.Contractual_Start_Date__c  ){
                actuallaunchclass = 'slds-text-color_destructive';
            }
            if (AP.Amendment_Type__c == 'Segmentation Change'){
            	segmentationclass = 'slds-text-color_destructive';
                segment = string.valueof(Integer.Valueof(AP.Amended_Segmentation__c));
            }else{
            	segment = (AP.Product_Name__c == 'Integrated Campaign - Doc Dynamic') ? 'N/A' : string.valueof(Integer.Valueof(AP.Opportunity_Product__r.Segmentation__c));
            }
                                            
            system.debug('edate--' + EDate + '--sdate-- ' + SDate );
            lstWrap.add(new ChangeOrderApex(AP.id,AP.Opportunity_Product__r.Product_Name__c,
                                                Integer.Valueof(AP.Opportunity_Product__r.Quantity),
                                                SDate, EDate, target,
                                                segment,Engagements, Audienceurl, MergedGuarantees,
                                                edurl, edmismatchclass,
                                                AP.Amendment_Type__c,dateclass,targetclass, 
                                            	AP.Opportunity_Product__r.term__r.First_Deliverable_Launch_Date_Term__c,
                                            	AP.Opportunity_Product__r.Projected_End_Date__c,actuallaunchclass, segmentationclass));
            actuallaunchclass = '';
            segmentationclass = '';
        }
        system.debug('here2 COs--' + lstWrap);
     	//autocreate APs type actual launch for products not there 
        return lstWrap;
    }
	@AuraEnabled(cacheable=true)
    public static List<ChangeOrderOppApex> getChangeOppOrders(String recordId) {
        List<ChangeOrderOppApex> lstWrap = new List<ChangeOrderOppApex>();
        List<String> OppLevelCOs = new List<String>{'Agency Switch', 'Add/Modify Non-Finance Related Language'};
        
        List<Amended_Products__c> APs = new List<Amended_Products__c>();
 		APs = [SELECT id,Version__c,status__c,Amendment_Type__c,
               Amendment_Detail__c,Amended_Agency__r.Name
               FROM Amended_Products__c
                                        where Contract_Amendment__c = :recordId  
               							and  status__c  IN ('Requested', 'Fully Executed' ) 
               							and Amendment_Type__c IN :OppLevelCOs
               							order by Amendment_Type__c ];
         for (Amended_Products__c AP : APs){
             if (AP.Amendment_Type__c == 'Agency Switch'){
                 lstWrap.add(new ChangeOrderOppApex(AP.id,AP.Amended_Agency__r.Name, AP.Amendment_Type__c,
                                                'n/a', 'slds-text-color_destructive'));
             }
             if (AP.Amendment_Type__c == 'Add/Modify Non-Finance Related Language'){
                 lstWrap.add(new ChangeOrderOppApex(AP.id,'n/a', AP.Amendment_Type__c,
                                                AP.Amendment_Detail__c, ''));
             }
        	
         }
        system.debug('here2 COs--' + lstWrap);
    	return lstWrap;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<InvoiceCOApex> getInvoiceChangeOrders(String recordId) {
        system.debug('here--' + recordId);
        List<String> InvoiceCOs = new List<String>{'Change to Invoice Schedule'};
        
        List<Amended_Products__c> APs = new List<Amended_Products__c>();
 		APs = [SELECT id,Version__c,status__c,Opportunity_Product_ID__c,Invoice_Schedule__c,
               Invoice_Schedule__r.id,
               Invoice_Schedule__r.Invoicing_Milestone__c,
               Opportunity__c,Contract_Amendment__c,Amendment_Type__c,
               Original_Invoice_Amount__c,Amended_Invoice_Amount__c,
               Original_Invoice_Date__c,Amended_Invoice_Date__c,Invoice_Change_Type__c,
               Invoice_Schedule__r.Invoice_Date__c, Invoice_Schedule__r.Invoice_Amount__c
               FROM Amended_Products__c
               where Contract_Amendment__c = :recordId  
               and  status__c  IN ('Requested', 'Fully Executed' ) 
               and Amendment_Type__c IN :InvoiceCOs
               order by Opportunity_Product__c];
        
        string changeClass = 'slds-text-color_destructive';
       
        List<InvoiceCOApex> lstWrap = new List<InvoiceCOApex>();
        for (Amended_Products__c AP : APs){
            if (AP.Invoice_Change_Type__c == 'Remove'){
                lstWrap.add(new InvoiceCOApex(AP.Invoice_Schedule__r.id, AP.Invoice_Change_Type__c, AP.Invoice_Schedule__r.Invoicing_Milestone__c,
                                   AP.Invoice_Schedule__r.Invoice_Date__c, AP.Invoice_Schedule__r.Invoice_Amount__c,
                             	   AP.Amended_Invoice_Date__c, AP.Amended_Invoice_Amount__c, changeClass ));
            
            }else{
                lstWrap.add(new InvoiceCOApex(AP.Invoice_Schedule__r.id, AP.Invoice_Change_Type__c, AP.Invoice_Schedule__r.Invoicing_Milestone__c,
                                   AP.Original_Invoice_Date__c, AP.Original_Invoice_Amount__c,
                             	   AP.Amended_Invoice_Date__c, AP.Amended_Invoice_Amount__c, changeClass ));
            
            }
           
        }
        system.debug('CO APex--' + lstWrap);
     
        return lstWrap;
    }

    
}