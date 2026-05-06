public class ChangeOrderApex {
        @AuraEnabled public ID apId { get; set; }
        @AuraEnabled public String productName { get; set; }
        @AuraEnabled public Integer  quantity { get; set; }
        @AuraEnabled public Date contractualStartDate { get; set; }
        @AuraEnabled public Date contractualEndDate { get; set; }
        @AuraEnabled public Integer targets { get; set; }
        @AuraEnabled public string segments { get; set; }
        @AuraEnabled public Integer engagements { get; set; }
        @AuraEnabled public string audienceurl { get; set; }
        @AuraEnabled public String mergedguarantee { get; set; }
        @AuraEnabled public string edmismatch { get; set; }
        @AuraEnabled public String amendmenttype { get; set; }
        @AuraEnabled public String dateclass { get; set; }
        @AuraEnabled public String targetclass { get; set; }
        @AuraEnabled public string edmismatchclass { get; set; }
    	@AuraEnabled public Date actuallaunchdate { get; set; }
    	@AuraEnabled public Date expectedenddate { get; set; }
        @AuraEnabled public string actuallaunchclass { get; set; }
    	@AuraEnabled public string segmentationclass { get; set; }
    
    
        public ChangeOrderApex(Id apId, string productName, integer quantity,
                                   date sdate, date edate, integer target,
                                   string segment, integer eng, 
                                   string audience, string mergedguarantee, string edmismatch, 
                                   string edmismatchclass, string amendmenttype, 
                               	   string dateclass, string targetclass, 
                                   date actuallaunchdate, date expectedenddate, string actuallaunchclass, string segmentationclass ) {
                this.apId = apId;
                this.productName = productName;
                this.quantity = quantity;
                this.contractualStartDate = sdate;
                this.contractualEndDate = edate;
                this.targets = target;
                this.segments = segment;
                this.engagements = eng;
                this.audienceurl = audience;
                this.amendmenttype = amendmenttype;  
                this.dateclass = dateclass;
                this.targetclass = targetclass;
                this.mergedguarantee = mergedguarantee;
                this.edmismatch = edmismatch;                                       
                this.edmismatchclass = edmismatchclass;
				this.actuallaunchdate = actuallaunchdate;
                this.expectedenddate = expectedenddate;
                this.actuallaunchclass = actuallaunchclass;
                this.segmentationclass = segmentationclass;                       
                
                                       
        }


}