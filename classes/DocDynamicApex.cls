public class DocDynamicApex {
  
    @AuraEnabled public ID oliId { get; set; }
    @AuraEnabled public string pname { get; set; }
    @AuraEnabled public string products { get; set; }
    @AuraEnabled public integer AAGT { get; set; }
    @AuraEnabled public integer uniqueunits { get; set; }
    @AuraEnabled public DocDynamicPBApex ddPB {get; set; }
    
    public DocDynamicApex(ID oliId, string pname, string products,integer AAGT,integer uniqueunits,
                         DocDynamicPBApex ddPB){
       	this.oliId = oliId;
        this.pname = pname;
       	this.products = products;
        this.AAGT = AAGT;
        this.uniqueunits = uniqueunits;
        this.ddPB = ddPB;
    }

}