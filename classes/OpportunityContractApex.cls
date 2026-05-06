public class OpportunityContractApex {
    
    	@AuraEnabled public ID contractId { get; set; }
    	@AuraEnabled public ID oppId { get; set; }
    	@AuraEnabled public ID parentOppId { get; set; }
        @AuraEnabled public Integer changeOrder  { get; set; }
    	@AuraEnabled public date changeOrderEffectiveDate { get; set; }
    	@AuraEnabled public date sowEffectiveDate { get; set; }
    	@AuraEnabled public string insertionOrder { get; set; }
    	@AuraEnabled public string projectTitle { get; set; }
    	@AuraEnabled public string keyDetails { get; set; }
    	@AuraEnabled public decimal totalContractValue { get; set; }
    	@AuraEnabled public decimal parentContractValue { get; set; }
        @AuraEnabled public decimal modifiedContractValue { get; set; }
    	@AuraEnabled public ID firstSOW { get; set; }
   		@AuraEnabled public ID previousCO { get; set; }
    	@AuraEnabled public date sowPADate { get; set; }
    	@AuraEnabled public boolean is0amendment { get; set; }
    
    
    public OpportunityContractApex(ID contractId,
                                  ID oppId,ID parentOppId,
                                  Integer changeOrder,
                                  date changeOrderEffectiveDate,date sowEffectiveDate,
                                  string insertionOrder,string keyDetails, string projectTitle,
                                  decimal totalContractValue,decimal parentContractValue,decimal modifiedContractValue,
                                  ID firstSOW,ID previousCO, date sowPADate, boolean is0amendment){
                                      
		this.contractId = contractId;
        this.oppId = oppId;
        this.parentOppId = parentOppId;                              
		this.changeOrder = changeOrder;
        this.changeOrderEffectiveDate = changeOrderEffectiveDate; 
        this.sowEffectiveDate = sowEffectiveDate; 
        this.insertionOrder = insertionOrder; 
		this.projectTitle = projectTitle; 
        this.keyDetails = keyDetails;
        this.totalContractValue = totalContractValue; 
        this.parentContractValue = parentContractValue;
        this.modifiedContractValue = modifiedContractValue;
        this.firstSOW = firstSOW;
        this.previousCO = previousCO;  
		this.sowPADate = sowPADate;
        this.is0amendment = is0amendment;
    }
                                       

}