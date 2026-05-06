public class FullViewApex {

     @AuraEnabled public ID contractId { get; set; }
     @AuraEnabled public String documentName { get; set; }
     @AuraEnabled public String projectName { get; set; }
     @AuraEnabled public String summary { get; set; }
     @AuraEnabled public String notes { get; set; }
     @AuraEnabled public String doctype { get; set; }
     @AuraEnabled public String reqtype { get; set; }
     @AuraEnabled public String status { get; set; }
     @AuraEnabled public date codate { get; set; }
 	 @AuraEnabled public date sowdate { get; set; }  
     @AuraEnabled public integer changeorder { get; set; } 
    @AuraEnabled public string conurl { get; set; }
    @AuraEnabled public boolean ischangeorder { get; set; }
    @AuraEnabled public boolean isinternal { get; set; }
    @AuraEnabled public date completeddate { get; set; }
    
    
     public  FullViewApex(id contractId, string documentName, string projectName, string summary,
                 				string notes,string doctype,string reqtype, string status,
                 				date codate, date sowdate, integer changeorder, string conurl, boolean ischangeorder, boolean isinternal, date completeddate ){
                                    
                           this.contractId = contractId;
                           this.documentName = documentName;
                           this.projectName = projectName;
                           this.summary = summary;
                           this.notes =notes;
                           this.doctype = doctype;
                           this.reqtype =reqtype;
                           this.status =status;
                           this.codate =codate;
                           this.sowdate = sowdate;
                           this.changeorder = changeorder;
                           this.conurl =conurl;    
                           this.ischangeorder = ischangeorder;
                           this.isinternal = isinternal;
                           this.completeddate = completeddate;
                         }
}