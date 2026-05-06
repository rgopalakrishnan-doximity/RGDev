public class ChangeOrderOppApex {
    @AuraEnabled public ID apId { get; set; }
    @AuraEnabled public String agencyName { get; set; }
    @AuraEnabled public String amendmenttype { get; set; }
    @AuraEnabled public String amendmentdetail { get; set; }
    @AuraEnabled public String agencyclass { get; set; }
    
    public ChangeOrderOppApex(Id apId, string agencyName, string amendmenttype,
                              string amendmentdetail, string agencyclass ){
                                  this.apId = apId;
                                  this.agencyName = agencyName;
                                  this.amendmenttype = amendmenttype;
                                  this.amendmentdetail = amendmentdetail;
                                  this.agencyclass = agencyclass;
                              }
        

}