public class ProductBreakupActions {
    
    public class ProductBreakupResults{
        @InvocableVariable
        public List<string> ProductConfigs;
    }
    
    
    public class ProductConfigInputs{
        
        @InvocableVariable
        public string Name;
    
        @InvocableVariable
        public string Brand;
        
		@InvocableVariable
        public string OrchestrationFeeIncluded;
        
        @InvocableVariable
        public string OPID;
        
        @InvocableVariable
        public boolean Announce;
        
        @InvocableVariable
        public boolean Announce2;
        
        @InvocableVariable
        public boolean DocSpot;
        
        @InvocableVariable
        public boolean DocNews;
        
        @InvocableVariable
        public boolean DocPoint;
        
        @InvocableVariable
        public boolean FormularyOne;
        
        @InvocableVariable
        public Integer AnnounceEngagement;
        
        @InvocableVariable
        public decimal AnnounceCPE;

 		@InvocableVariable
        public Integer Announce2Engagement; 
        
        @InvocableVariable
        public decimal Announce2CPE;
        
        @InvocableVariable
        public Integer DocNewsEngagement;
        
        @InvocableVariable
        public decimal DocNewsCPE;
        
        @InvocableVariable
        public Integer DocSpotEngagement;
        
        @InvocableVariable
        public decimal DocSpotCPE;

        @InvocableVariable
        public Integer DocPointEngagement;
        
        @InvocableVariable
        public decimal DocPointCPE;

        @InvocableVariable
        public Integer FormularyOneEngagement;
        
        @InvocableVariable
        public decimal FormularyOneCPE;
        
    }
    
    @InvocableMethod(label='Create Product Configuration' description='Create Product Configuration & Breakups')
    public static List<ProductBreakupResults> CreateProductConfig(List<ProductConfigInputs> inputs){
        
        
        ProductConfigInputs PCParameter = inputs[0];
        OpportunityLineItem OLI = [Select Total_Targets__c,Audience_Pricing__r.id,Guarantee__c from OpportunityLineItem where ID = :PCParameter.OPID];
        Id PCRecordTypeId = Schema.SObjectType.Product_Configuration__c.getRecordTypeInfosByName().get('Pricing Config').getRecordTypeId();

        Product_Configuration__c PC = new Product_Configuration__c();
        PC.Name = PCParameter.Name;
        PC.Brand__c = PCParameter.Brand;
        PC.Opportunity_Product__c = PCParameter.OPID;
        PC.Orchestration_Fee_Needed__c = PCParameter.OrchestrationFeeIncluded;
        PC.Status__c = 'Created';
        PC.Engagement_Detail__c = OLI.Guarantee__c;
        PC.RecordTypeId = PCRecordTypeId;//'012gP000000MNij';
        insert PC;
        
        Audience_Pricing__c AP = [Select id, Pharma_DocSpot_Audience_CPE__c ,
                                 Pharma_DocPoint_UV_Audience_CPE__c ,Pharma_AN_Audience_CPE__c ,Pharma_FO_Audience_CPE__c,
                                 Pharma_AN_Weighted_CPE__c, 
                                 Pharma_DN_2_0_Audience_CPE__c, Pharma_DN_2_0_Weighted_CPE__c,
                                 Pharma_DN_2_0_Rate_Card_Cost__c,Pharma_DN_2_0_Engagement_Rate__c,
                                 Pharma_DocPoint_UV_Weighted_CPE__c, Pharma_DocSpot_Weighted_CPE__c,
                                 Pharma_FO_Weighted_CPE__c,Pharma_DocPoint_UV_Rate_Card_Cost__c,
                                 Pharma_AN_Rate_Card_Cost__c,
                                 Pharma_DocSpot_Rate_Card_Cost__c,Pharma_FO_Rate_Card_Cost__c,
                                 Pharma_AN_Engagement_Rate__c,
                                 Pharma_DocSpot_Engagement_Rate__c,Pharma_DocPoint_UV_Engagement_Rate__c,Pharma_FO_Engagement_Rate__c
                                 from Audience_Pricing__c where id = :OLI.Audience_Pricing__r.id];
        
        List<Product_Breakup__c> lstPBs = new List<Product_Breakup__c>();
        List<Product_Breakup__c> lstupdtPBs = new List<Product_Breakup__c>();
            
        if (PCParameter.DocNews){
            Product_Breakup__c PB = new Product_Breakup__c();
            PB.Product_Configuration__c = PC.id;
        	PB.Product__c = 'DocNews';
            PB.Engagements__c = PCParameter.DocNewsEngagement;
            PB.Override_CPE__c = PCParameter.DocNewsCPE;
            PB.Product_Order__c = 1;
            PB.Weighted_CPE__c = AP.Pharma_DN_2_0_Weighted_CPE__c;
            PB.Cost__c = (PCParameter.DocNewsCPE != null && PCParameter.DocNewsCPE > 0) ?  PCParameter.DocNewsEngagement * PCParameter.DocNewsCPE : PCParameter.DocNewsEngagement * AP.Pharma_DN_2_0_Audience_CPE__c;
            PB.Calculated_CPE__c = (PCParameter.DocNewsCPE != null && PCParameter.DocNewsCPE > 0) ? PCParameter.DocNewsCPE.setScale(2,RoundingMode.CEILING) :  AP.Pharma_DN_2_0_Audience_CPE__c.setScale(2,RoundingMode.CEILING);
            PB.Max_Avails__c = AP.Pharma_DN_2_0_Rate_Card_Cost__c;
            //PB.Max_Avails__c = (OLI.Total_Targets__c * AP.Pharma_DN_2_0_Engagement_Rate__c) * AP.Pharma_DN_2_0_Rate_Card_Cost__c;
            lstPBs.add(PB);
        }
        
        if (PCParameter.DocSpot){
            Product_Breakup__c PB = new Product_Breakup__c();
            PB.Product_Configuration__c = PC.id;
        	PB.Product__c = 'DocSpot';
            PB.Engagements__c = PCParameter.DocSpotEngagement;
            PB.Override_CPE__c = PCParameter.DocSpotCPE;
            PB.Product_Order__c = 2;
            PB.Weighted_CPE__c = AP.Pharma_DocSpot_Weighted_CPE__c;
            PB.Cost__c = (PCParameter.DocSpotCPE != null && PCParameter.DocSpotCPE > 0) ?  PCParameter.DocSpotEngagement * PCParameter.DocSpotCPE : PCParameter.DocSpotEngagement * AP.Pharma_DocSpot_Audience_CPE__c;
            PB.Calculated_CPE__c = (PCParameter.DocSpotCPE != null && PCParameter.DocSpotCPE > 0) ?  PCParameter.DocSpotCPE.setScale(2,RoundingMode.CEILING) : AP.Pharma_DocSpot_Audience_CPE__c.setScale(2,RoundingMode.CEILING);
            //PB.Max_Avails__c = (OLI.Total_Targets__c * AP.Pharma_DocSpot_Engagement_Rate__c ) * AP.Pharma_DocSpot_Rate_Card_Cost__c;
            PB.Max_Avails__c =  AP.Pharma_DocSpot_Rate_Card_Cost__c;
            
            lstPBs.add(PB);
        }
        
        if (PCParameter.DocPoint){
            Product_Breakup__c PB = new Product_Breakup__c();
            PB.Product_Configuration__c = PC.id;
        	PB.Product__c = 'DocPoint';
            PB.Engagements__c = PCParameter.DocPointEngagement;
            PB.Override_CPE__c = PCParameter.DocPointCPE;
            PB.Product_Order__c = 3;
            PB.Weighted_CPE__c = AP.Pharma_DocPoint_UV_Weighted_CPE__c;
            PB.Cost__c = (PCParameter.DocPointCPE != null && PCParameter.DocPointCPE > 0) ?  PCParameter.DocPointEngagement * PCParameter.DocPointCPE : PCParameter.DocPointEngagement * AP.Pharma_DocPoint_UV_Audience_CPE__c;
            PB.Calculated_CPE__c = (PCParameter.DocPointCPE != null && PCParameter.DocPointCPE > 0) ?   PCParameter.DocPointCPE.setScale(2,RoundingMode.CEILING) :  AP.Pharma_DocPoint_UV_Audience_CPE__c.setScale(2,RoundingMode.CEILING);
            //PB.Max_Avails__c = (OLI.Total_Targets__c * AP.Pharma_DocPoint_UV_Engagement_Rate__c ) * AP.Pharma_DocPoint_UV_Rate_Card_Cost__c;
            PB.Max_Avails__c = AP.Pharma_DocPoint_UV_Rate_Card_Cost__c;
            
            lstPBs.add(PB);
        }
        
        if (PCParameter.Announce){
            Product_Breakup__c PB = new Product_Breakup__c();
            PB.Product_Configuration__c = PC.id;
        	PB.Product__c = 'Announce';
            PB.Engagements__c = PCParameter.AnnounceEngagement;
            PB.Override_CPE__c = PCParameter.AnnounceCPE;
            PB.Product_Order__c = 4;
            PB.Weighted_CPE__c = AP.Pharma_AN_Weighted_CPE__c;
            PB.Cost__c = (PCParameter.AnnounceCPE != null && PCParameter.AnnounceCPE > 0) ?  PCParameter.AnnounceEngagement * PCParameter.AnnounceCPE : PCParameter.AnnounceEngagement * AP.Pharma_AN_Audience_CPE__c;
            PB.Calculated_CPE__c = (PCParameter.AnnounceCPE != null && PCParameter.AnnounceCPE > 0) ?   PCParameter.AnnounceCPE.setScale(2,RoundingMode.CEILING) :  AP.Pharma_AN_Audience_CPE__c.setScale(2,RoundingMode.CEILING);
            //PB.Max_Avails__c = (OLI.Total_Targets__c * AP.Pharma_AN_Engagement_Rate__c ) * AP.Pharma_AN_Rate_Card_Cost__c;
            PB.Max_Avails__c =  AP.Pharma_AN_Rate_Card_Cost__c;
            
            lstPBs.add(PB);
        }
        
        if (PCParameter.Announce2){
            Product_Breakup__c PB = new Product_Breakup__c();
            PB.Product_Configuration__c = PC.id;
        	PB.Product__c = 'Announce*';
            PB.Engagements__c = PCParameter.Announce2Engagement;
            PB.Override_CPE__c = PCParameter.Announce2CPE;
            PB.Product_Order__c = 5;
            PB.Weighted_CPE__c = AP.Pharma_FO_Weighted_CPE__c;
            PB.Cost__c = (PCParameter.Announce2CPE != null && PCParameter.Announce2CPE > 0) ?  PCParameter.Announce2Engagement * PCParameter.Announce2CPE : PCParameter.Announce2Engagement * AP.Pharma_FO_Audience_CPE__c;
            PB.Calculated_CPE__c = (PCParameter.Announce2CPE != null && PCParameter.Announce2CPE > 0) ?   PCParameter.Announce2CPE.setScale(2,RoundingMode.CEILING) :  AP.Pharma_FO_Audience_CPE__c.setScale(2,RoundingMode.CEILING);
            //PB.Max_Avails__c = (OLI.Total_Targets__c * AP.Pharma_FO_Engagement_Rate__c ) * AP.Pharma_FO_Rate_Card_Cost__c;
            PB.Max_Avails__c =  AP.Pharma_FO_Rate_Card_Cost__c;
            
            lstPBs.add(PB);
        }
        
        if (PCParameter.FormularyOne){
            Product_Breakup__c PB = new Product_Breakup__c();
            PB.Product_Configuration__c = PC.id;
        	PB.Product__c = 'FormularyOne';
            PB.Engagements__c = PCParameter.FormularyOneEngagement;
            PB.Override_CPE__c = PCParameter.FormularyOneCPE;
            PB.Product_Order__c = 6;
            PB.Weighted_CPE__c = AP.Pharma_FO_Weighted_CPE__c;
            PB.Cost__c = (PCParameter.FormularyOneCPE != null && PCParameter.FormularyOneCPE > 0) ?  PCParameter.FormularyOneEngagement * PCParameter.FormularyOneCPE : PCParameter.FormularyOneEngagement * AP.Pharma_FO_Audience_CPE__c;
            PB.Calculated_CPE__c = (PCParameter.FormularyOneCPE != null && PCParameter.FormularyOneCPE > 0) ?   PCParameter.FormularyOneCPE.setScale(2,RoundingMode.CEILING) :  AP.Pharma_FO_Audience_CPE__c.setScale(2,RoundingMode.CEILING);
            //PB.Max_Avails__c = (OLI.Total_Targets__c * AP.Pharma_FO_Engagement_Rate__c ) * AP.Pharma_FO_Rate_Card_Cost__c;
            PB.Max_Avails__c =  AP.Pharma_FO_Rate_Card_Cost__c;
            
            lstPBs.add(PB);
        }
        
        system.debug(lstPBs);
        insert lstPBs;
        
        
        List<ProductBreakupResults> PBRests = new List<ProductBreakupResults>();
        ProductBreakupResults PBRes = new ProductBreakupResults();
        List<string> PCList = new List<string>();
        PCList.add(PC.ID);
        PBRes.ProductConfigs = PCList;
        PBRests.add(PBRes);
        return PBRests;

    }
}