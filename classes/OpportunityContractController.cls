public class OpportunityContractController {
    
    @AuraEnabled(cacheable=true)
    public static OpportunityContractApex getOppContractDetails(String recordId) {
    	
        Amendment__c amend = [SELECT id, Opportunity__c,
                              Parent_Opportunity__c,
                              Change_Order_Number__c,
                              Change_Order_Effective_Date__c,
                              First_SOW__r.SOW_Effective_Date__c,
                              Insertion_Order_IO__c,
                              Project_Title__c,
                              Summary_of_Changes__c,
                              Total_Contract_Value__c,
                              Parent_Opportunity__r.Amount,First_SOW__c,Previous_Amendment__c,
                              Rolling_Amount__c,Modified_Amount__c,Opportunity__r.StageName,
                              First_SOW__r.Platform_Agreement_Effective_Date__c 
                              FROM Amendment__c WHERE Id =:recordId Limit 1];
       
		decimal corequestamount = 0;
        boolean is0amendment = true;
        if (amend.Parent_Opportunity__c == null && amend.Opportunity__r.StageName == '100% - Closed Won'){
           corequestamount = 0; 
           is0amendment = true;
        }else{
           corequestamount =  amend.Total_Contract_Value__c;
           is0amendment= false;
        }
        
        OpportunityContractApex lstWrap = new OpportunityContractApex(amend.ID,
                                                                      amend.Opportunity__c,amend.Parent_Opportunity__c,
                                                                      Integer.valueof(amend.Change_Order_Number__c),
                                                                      amend.Change_Order_Effective_Date__c,amend.First_SOW__r.SOW_Effective_Date__c,
                                                                      amend.Insertion_Order_IO__c, amend.Summary_of_Changes__c, amend.Project_Title__c, 
                                                                      corequestamount, amend.Rolling_Amount__c, amend.Modified_Amount__c,
                                                                      amend.First_SOW__c, amend.Previous_Amendment__c, 
                                                                      amend.First_SOW__r.Platform_Agreement_Effective_Date__c, is0amendment);
        
        system.debug('here2--' + lstWrap);
        return lstWrap;
    }
    @AuraEnabled(cacheable=true)
    public static List<ProgramDetailApex> getProgramDetails(String recordId) {
        Amendment__c amend = [SELECT id, Opportunity__c,
                              Parent_Opportunity__c
                              FROM Amendment__c WHERE Id = :recordId Limit 1];
        
        List<ProgramDetailApex> lstretOpps = new List<ProgramDetailApex>();
        List<Opportunity> lstOpps = new List<Opportunity>();
        string debookClass = '';
        //to add 100% - Closed Won StageName 0% - Closed Lost
        if (amend.Parent_Opportunity__c != null){
            lstOpps = [select id, Name,Lead_Number__c, Amount, type 
                       from Opportunity where 
                       ((id = :amend.Parent_Opportunity__c or 
                         Parent_Opportunity__c = :amend.Parent_Opportunity__c)
                        and StageName = '100% - Closed Won')
                        or id  = :amend.Opportunity__c  order by createdDate asc ];
        }else{
            lstOpps = [select id, Name,Lead_Number__c, Amount, type 
                       from Opportunity where 
                       (Parent_Opportunity__c = :amend.Opportunity__c or id  = :amend.Opportunity__c) and
                      StageName = '100% - Closed Won' order by createdDate asc ];
        }
        for (Opportunity opp :lstOpps){
            debookClass = (opp.Type == 'Debooking') ? 'slds-text-color_destructive' : '';
            lstretOpps.add(new ProgramDetailApex(Opp.id, 
                                                 Opp.Name,
                                                 string.valueof(Opp.Lead_Number__c),
                                                 Opp.Amount, debookClass
            									));
        }
        
        return lstretOpps;
    }

}