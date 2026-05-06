public class OriginalScopeApex {
    
    	@AuraEnabled public ID apId { get; set; }
        @AuraEnabled public String productName { get; set; }
        @AuraEnabled public Integer  quantity { get; set; }
        @AuraEnabled public Date contractualStartDate { get; set; }
        @AuraEnabled public Date contractualEndDate { get; set; }
        @AuraEnabled public Integer targets { get; set; }
        @AuraEnabled public string segments { get; set; }
    	@AuraEnabled public string segmentclass { get; set; }
        @AuraEnabled public Integer engagements { get; set; }
		@AuraEnabled public String audienceurl { get; set; }
        @AuraEnabled public String mergedguarantee { get; set; }
    	@AuraEnabled public date actuallaunchdate { get; set; }
    	@AuraEnabled public string edmismatch { get; set; }
    	@AuraEnabled public date cspdALD { get; set; }
    	@AuraEnabled public string edmismatchclass { get; set; }
    	@AuraEnabled public String scope { get; set; }
    	@AuraEnabled public String scopeclass { get; set; }
    	@AuraEnabled public String leadNumber { get; set; }
    	
        
    	public OriginalScopeApex(Id apId, string productName, integer quantity,
                                   date sdate, date edate, integer target,
                                   string segment, integer eng, 
                                   string audience, string mergedguarantee, date actuallaunchdate, string edmismatch, date cspdALD, 
                                   string edmismatchclass, string scope, string scopeclass, String leadNumber) {
                this.apId = apId;
                this.productName = productName;
                this.quantity = quantity;
                this.contractualStartDate = sdate;
                this.contractualEndDate = edate;
                this.targets = target;
                this.segments = segment;
                //this.segmentclass = segmentclass;                       
                this.engagements = eng;
                this.audienceurl = audience;
                this.mergedguarantee = mergedguarantee;
                this.actuallaunchdate = actuallaunchdate;
                this.edmismatch = edmismatch;
                this.cspdALD = cspdALD;
                this.edmismatchclass = edmismatchclass;
                this.scope = scope; 
                this.scopeclass = scopeclass; 
                this.leadNumber = leadNumber;                  
                
    	}

}