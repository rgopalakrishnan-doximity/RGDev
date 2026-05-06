public class OriginalScopeController {
    /*TODO
     * actual launch date vs actual launch date reviewed - check and build the logic
     * 
     */
    @AuraEnabled(cacheable=true)
    public static List<OriginalScopeApex> getOriginalScope(String recordId) {
        system.debug('here--' + recordId);
       Amendment__c amend = [SELECT id, Opportunity__r.ID,Parent_Opportunity__r.id,
                             Opportunity__r.StageName
                             FROM Amendment__c WHERE Id =:recordId Limit 1];
       
       List<Opportunity> allclosedOppsParentLevel = [select id from opportunity where 
                                          id = :amend.Opportunity__r.ID
                                          or (parent_opportunity__c =:amend.Opportunity__r.id 
                                          and StageName = '100% - Closed Won')];
        
       List<Opportunity> allclosedOppsChildLevel = [select id from opportunity where 
                                          /*id = :amend.Opportunity__r.ID
                                          or*/ id = :amend.Parent_Opportunity__r.id 
                                          or (parent_opportunity__c = :amend.Parent_Opportunity__r.id 
                                          and StageName = '100% - Closed Won')];
       List<string> closedopps = new list<string>();
       
        
       List<OpportunityLineItem> OLIs = new List<OpportunityLineItem>();
       
        If (amend.Parent_Opportunity__r.id != null){
            
            for(Opportunity opp : allclosedOppsChildLevel){
                 closedopps.add(opp.id);   
            }
            OLIs = [SELECT id,Product_Name__c, Name,Opportunity.Lead_Number__c,
                                         Contractual_Start_Date__c,Contractual_End_Date__c,
                                         Quantity,Custom_List_Targets__c,Segmentation__c,
                                         Guarantee__r.Engagements_Formula__c,Guarantee__r.Audience_URL__c,
                                         Guarantee__r.Merged_Guarantees__c, Actual_Start_Date_Reviewed__c,
                                         Actual_Start_Date__c, ED_Mismatch__c, Term__r.First_Deliverable_Launch_Date_Term__c  
                                         FROM OpportunityLineItem 
                                         where OpportunityId  IN :closedopps];
      
      
      	// previously closed childs needs to be added as well      
        }else{
            
            for(Opportunity opp : allclosedOppsParentLevel){
                 closedopps.add(opp.id);   
            }
            
            OLIs = [SELECT id,Product_Name__c, Name,Opportunity.Lead_Number__c,
                                         Contractual_Start_Date__c,Contractual_End_Date__c,
                                         Quantity,Custom_List_Targets__c,Segmentation__c,
                                         Guarantee__r.Engagements_Formula__c,Guarantee__r.Audience_URL__c,
                                         Guarantee__r.Merged_Guarantees__c, Actual_Start_Date_Reviewed__c,
                                         Actual_Start_Date__c, ED_Mismatch__c, Term__r.First_Deliverable_Launch_Date_Term__c  
                                         FROM OpportunityLineItem 
                                         where OpportunityId IN  :closedopps and Target_Upsell_Only__c = false ];
        
        }
       
      
        
        Date actuallaunchdate = Date.today();
        Date EDate = Date.today();
        String edurl = '';
        integer target = 0;
        string segment = '';
        string segmentclass = 'slds-text-align_right'; 
        string edmismatchclass = 'slds-text-color_destructive';
        List<OriginalScopeApex> lstWrap = new List<OriginalScopeApex>();
        for (OpportunityLineItem OLI : OLIs){
            
            if ((OLI.ED_Mismatch__c).contains('flag_yellow')){
               edurl =  'Not Approved';
               edmismatchclass = 'slds-text-color_destructive';
            }else if ((OLI.ED_Mismatch__c).contains('flag_red')){
               edurl =  'Not Approved';
               edmismatchclass = 'slds-text-color_destructive';
            }else{
               edurl =  'Approved';  
               edmismatchclass = 'slds-text-color_success';
                
            }
            segment = (OLI.Product_Name__c == 'Integrated Campaign - Doc Dynamic') ? 'N/A' : string.valueof(Integer.Valueof(OLI.Segmentation__c));
            actuallaunchdate = (OLI.Actual_Start_Date_Reviewed__c != null) ? OLI.Actual_Start_Date_Reviewed__c : OLI.Actual_Start_Date__c;
            lstWrap.add(new OriginalScopeApex(OLI.id,OLI.Product_Name__c,
                                                Integer.Valueof(OLI.Quantity),
                                                OLI.Contractual_Start_Date__c, 
                                                OLI.Contractual_End_Date__c, 
                                              	Integer.Valueof(OLI.Custom_List_Targets__c),
                                                segment,
                                                Integer.Valueof(OLI.Guarantee__r.Engagements_Formula__c),
                                                OLI.Guarantee__r.Audience_URL__c, OLI.Guarantee__r.Merged_Guarantees__c, 
                                                actuallaunchdate, edurl, OLI.Term__r.First_Deliverable_Launch_Date_Term__c, edmismatchclass, '', '', OLI.Opportunity.Lead_Number__c ));
           
        }
        system.debug('top section--' + lstWrap);
     
        return lstWrap;
    }
    
    //to be used in changeorder - new scope 
    @AuraEnabled(cacheable=true)
    public static List<OriginalScopeApex> getParentOriginalScope(String recordId) {
        system.debug('here--' + recordId);
       Amendment__c amend = [SELECT id, Opportunity__r.ID, Parent_Opportunity__r.id, Opportunity__r.StageName  FROM Amendment__c WHERE Id =:recordId Limit 1];
       List<OpportunityLineItem> OLIs = [SELECT id,Product_Name__c, Name,OpportunityId,Opportunity.Lead_Number__c,
                                         Contractual_Start_Date__c,Contractual_End_Date__c,
                                         Quantity,Custom_List_Targets__c,Segmentation__c,
                                         Guarantee__r.Engagements_Formula__c,Guarantee__r.Audience_URL__c,
                                         Guarantee__r.Merged_Guarantees__c, Actual_Start_Date_Reviewed__c,
                                         Actual_Start_Date__c, ED_Mismatch__c, Term__r.First_Deliverable_Launch_Date_Term__c  
                                         FROM OpportunityLineItem 
                                         where OpportunityId  = :amend.Parent_Opportunity__r.ID or 
                                         OpportunityId  = :amend.Opportunity__r.ID order by createddate asc ];
      
        
        Date actuallaunchdate = Date.today();
        Date EDate = Date.today();
        String edurl = '';
        string Scope = '';
        string Scopeclass = '';
        integer target = 0;
        string segment = '';
        string segmentclass = 'slds-text-align_right'; 
        string edmismatchclass = 'slds-text-color_destructive';
        List<OriginalScopeApex> lstWrap = new List<OriginalScopeApex>();
        for (OpportunityLineItem OLI : OLIs){
            
            system.debug('checkscope--' + OLI.OpportunityId + '--' +  amend.Parent_Opportunity__r.ID);
            if (OLI.OpportunityId == amend.Parent_Opportunity__r.ID){
                Scope = 'Original';
                Scopeclass = 'slds-text-title_bold';
            }else  if (OLI.OpportunityId == amend.Opportunity__r.ID){
                Scope = (amend.Opportunity__r.StageName == '100% - Closed Won' ) ? 'Original' : 'New';
                Scopeclass = (amend.Opportunity__r.StageName == '100% - Closed Won' ) ?  'slds-text-title_bold' : 'slds-text-title_bold slds-text-color_success';
            }else{
                Scope = '';
                Scopeclass = '';
            }
            system.debug(Scopeclass);
            if ((OLI.ED_Mismatch__c).contains('flag_yellow')){
               edurl =  'Not Approved';
               edmismatchclass = 'slds-text-color_destructive';
            }else if ((OLI.ED_Mismatch__c).contains('flag_red')){
               edurl =  'Not Approved';
               edmismatchclass = 'slds-text-color_destructive';
            }else{
                edurl =  'Approved';    
                 edmismatchclass = 'slds-text-color_success';
            }
            segment = (OLI.Product_Name__c == 'Integrated Campaign - Doc Dynamic') ? 'N/A' : string.valueof(Integer.Valueof(OLI.Segmentation__c));
            actuallaunchdate = (OLI.Actual_Start_Date_Reviewed__c != null) ? OLI.Actual_Start_Date_Reviewed__c : OLI.Actual_Start_Date__c;
            lstWrap.add(new OriginalScopeApex(OLI.id,OLI.Product_Name__c,
                                                Integer.Valueof(OLI.Quantity),
                                                OLI.Contractual_Start_Date__c, 
                                                OLI.Contractual_End_Date__c, 
                                              	Integer.Valueof(OLI.Custom_List_Targets__c),
                                                segment,
                                                Integer.Valueof(OLI.Guarantee__r.Engagements_Formula__c),
                                                OLI.Guarantee__r.Audience_URL__c, OLI.Guarantee__r.Merged_Guarantees__c, 
                                                actuallaunchdate, edurl, OLI.Term__r.First_Deliverable_Launch_Date_Term__c, edmismatchclass, Scope, Scopeclass, OLI.Opportunity.Lead_Number__c));
           
        }
        system.debug('SCope--' + lstWrap);
     
        return lstWrap;
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<AtRiskTermsApex> getAtRiskTerms(String recordId) {
       
        List<AtRiskTermsApex> lstWrap = new   List<AtRiskTermsApex>();
       Amendment__c amend = [SELECT id, Opportunity__r.ID, Parent_Opportunity__r.id   FROM Amendment__c WHERE Id =:recordId Limit 1];
        
       List<OpportunityLineItem> OLIs = [SELECT id,Product_Name__c, Name,
                                         term__r.id,
                                         term__r.Name,
                                         term__r.Approval_Type__c,
                                         term__r.Approval_Status__c,
                                         term__r.Approvals_Received__c,
                                         term__r.Latest_Approval__c,
                                         term__r.Latest_Approval_By__c,
                                         term__r.Approval_Comments__c 
                                         FROM OpportunityLineItem 
                                         where OpportunityId  = :amend.Opportunity__r.ID or OpportunityId  = :amend.Parent_Opportunity__r.ID];
        
        for (OpportunityLineItem OLI : OLIs){
             system.debug('here AP---' + OLI.term__r.Approval_Type__c);
            // ||(OLI.term__r.Approvals_Received__c != null && OLI.term__r.Approvals_Received__c.contains('At Risk Launches'))
            if (
                (OLI.term__r.Approval_Type__c != null && OLI.term__r.Approval_Type__c.contains('At Risk Launches'))
               ){
               
                lstWrap.add(new AtRiskTermsApex(OLI.term__r.id, OLI.term__r.Name,
                                                  OLI.Product_Name__c,OLI.term__r.Approval_Type__c,
                                                  OLI.term__r.Approval_Status__c,
                                                     OLI.term__r.Approvals_Received__c,
                                                     OLI.term__r.Latest_Approval__c,
                                                     OLI.term__r.Latest_Approval_By__c,
                                                     OLI.term__r.Approval_Comments__c));
                				
            }
              
        }
        system.debug('here----' + lstWrap);
       return lstWrap;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<DocDynamicApex> getDocDynamicDetails(String recordId) {
       
       List<DocDynamicApex> lstWrap = new   List<DocDynamicApex>();
       Amendment__c amend = [SELECT id, Opportunity__r.ID, Parent_Opportunity__r.id   FROM Amendment__c WHERE Id =:recordId Limit 1];
       List<String> products = new List<String>{'%Doc Dynamic%', '%NBE%'};
           
       Map<ID, OpportunityLineItem> mapDD = new Map<ID, OpportunityLineItem>([SELECT id
                                         FROM OpportunityLineItem 
                                         where (OpportunityId  = :amend.Opportunity__r.ID or OpportunityId  = :amend.Parent_Opportunity__r.ID)
                                         and  Product_Name__c  LIKE :products]);
        
       string DNEngagement = 'N/A';
       string DSEngagement = 'N/A';
       string DPEngagement = 'N/A';
       string ANEngagement = 'N/A';
       string FOEngagement = 'N/A';
       string DNGross = 'N/A';
       string DSGross = 'N/A';
       string DPGross = 'N/A';
       string ANGross = 'N/A';
       string FOGross = 'N/A';
       string DNNet = 'N/A';
       string DSNet = 'N/A';
       string DPNet = 'N/A';
       string ANNet = 'N/A';
       string FONet = 'N/A';
        
        if (mapDD.size() > 0){
     		List<Product_Configuration__c> lstPCs = [SELECT id,Opportunity_Product__r.ID,Opportunity_Product__r.Product_Name__c, Products__c, AAGT__c , Unique_Units__c 
                                                     FROM Product_Configuration__c WHERE 
                                                     Opportunity_Product__r.ID  IN :mapDD.keyset() and Status__c = 'Approved' ];
            List<Product_Breakup__c> lstPBs = new List<Product_Breakup__c>();
            
            
            for (Product_Configuration__c pc : lstPCs){
                lstPBs = [SELECT ID, Product_Configuration__c, Product__c, Engagements__c, Cost__c,Net_Cost__c 
                                                  FROM Product_Breakup__c WHERE 
                                                  Product_Configuration__c = :pc.id];
                for (Product_Breakup__c PB : lstPBs){
                    switch on PB.Product__c {
                        when 'DocNews'{
                            DNEngagement = string.valueof(PB.Engagements__c); 
                            DNGross = '$' + string.valueof(PB.Cost__c);
                            DNNet = '$' + string.valueof(PB.Net_Cost__c);
                        }
                        when 'DocSpot'{
                            DSEngagement = string.valueof(PB.Engagements__c);
                            DSGross = '$' + string.valueof(PB.Cost__c);
                            DSNet = '$' + string.valueof(PB.Net_Cost__c);
                        }
                        when 'DocPoint'{
                            DPEngagement = string.valueof(PB.Engagements__c);
                            DPGross = '$' + string.valueof(PB.Cost__c);
                            DPNet = '$' + string.valueof(PB.Cost__c);
                        } 
						when 'Announce'{
                            ANEngagement = string.valueof(PB.Engagements__c);
                            ANGross = '$' + string.valueof(PB.Cost__c);
                            DPNet = '$' + string.valueof(PB.Cost__c);
                            
                        }  
                        when 'FormularyOne'{
                            FOEngagement = string.valueof(PB.Engagements__c);
                            FOGross = '$' + string.valueof(PB.Cost__c);
                            FONet = '$' + string.valueof(PB.Cost__c);
                        } 
                    }
                }
				DocDynamicPBApex DDPB = new DocDynamicPBApex(DNEngagement,DSEngagement,DPEngagement,ANEngagement,FOEngagement,
                                                            DNGross,DSGross, DPGross, ANGross, FOGross,
                                                            DNNet,DSNet, DPNet, ANNet, FONet
                                                            );
                lstWrap.add (new DocDynamicApex(pc.Opportunity_Product__r.ID, pc.Opportunity_Product__r.Product_Name__c, pc.Products__c,Integer.Valueof(pc.AAGT__c),
                                                Integer.Valueof(pc.Unique_Units__c), DDPB));
            }
            
        }
       return lstWrap;
    }
    
}