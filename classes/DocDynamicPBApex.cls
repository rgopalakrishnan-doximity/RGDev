public class DocDynamicPBApex {
    
    @AuraEnabled public string DNEngagement { get; set; }
    @AuraEnabled public string DSEngagement { get; set; }
    @AuraEnabled public string DPEngagement { get; set; }
    @AuraEnabled public string ANEngagement { get; set; }
    @AuraEnabled public string FOEngagement { get; set; }
    @AuraEnabled public string DNGross { get; set; }
    @AuraEnabled public string DSGross { get; set; }
    @AuraEnabled public string DPGross { get; set; }
    @AuraEnabled public string ANGross { get; set; }
    @AuraEnabled public string FOGross { get; set; }
    @AuraEnabled public string DNNet { get; set; }
    @AuraEnabled public string DSNet { get; set; }
    @AuraEnabled public string DPNet { get; set; }
    @AuraEnabled public string ANNet { get; set; }
    @AuraEnabled public string FONet { get; set; }
    
    
    public DocDynamicPBApex(string DNEngagement, string DSEngagement,string DPEngagement,string ANEngagement,
                           string FOEngagement,string DNGross,string DSGross,string DPGross,string ANGross,
                           string FOGross,string DNNet,string DSNet,string DPNet,string ANNet,
                           string FONet
                           ){
       	
        this.DNEngagement = DNEngagement;
       	this.DSEngagement = DSEngagement;
        this.DPEngagement = DPEngagement;
        this.ANEngagement = ANEngagement;
    	this.FOEngagement = FOEngagement;
        this.DNGross = DNGross;
        this.DSGross = DSGross;
        this.DPGross = DPGross;
        this.ANGross = ANGross;
		this.FOGross = FOGross;
        this.DNNet = DNNet;
        this.DSNet = DSNet;
        this.DPNet = DPNet;
        this.ANNet = ANNet;
		this.FONet = FONet;
	}

}