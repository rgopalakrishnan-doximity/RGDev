public class AmendedProducts{

    @InvocableMethod(label='Map SOW Amended Products')
    public static void MapSOWAmendedProducts(List<string> ContractIDs)
    {
       Amendment__c amend = [SELECT id, Opportunity__r.Name,Parent_Opportunity__c,Parent_Opportunity__r.ID,
                             Opportunity__r.Products__c, Opportunity__r.ID, 
                             Opportunity__r.Agency_3rd_Party__r.id  FROM Amendment__c WHERE Id =:ContractIDs[0] Limit 1];
        
       List<OpportunityLineItem> OLIs = [SELECT id,Product_Name__c, Name,
                                         Contractual_Start_Date__c,Contractual_End_Date__c,
                                         Quantity,Total_Targets__c FROM OpportunityLineItem 
                                          where OpportunityId  = :amend.Opportunity__r.ID];
      
       List<Amended_Products__c> APs = new List<Amended_Products__c>();
       APs = [SELECT id,Version__c,status__c,Original_Quantity__c,
                                        Opportunity_Product_ID__c,Opportunity_Product__c,
                                        Opportunity__c,Contract_Amendment__c,Amendment_Type__c,
                                        Original_Agency__c,Amended_Agency__c,Amended_Agency_3rd_Party_Transfer_Date__c,
                                        Amended_Contractual_Start_Date__c, Amended_Contractual_End_Date__c,
                                        Amended_Max_Targets_Per_Month__c,Automated_Fulfilment__c
                                        FROM Amended_Products__c
                                        where (Program__c  = :amend.Parent_Opportunity__r.ID or Program__c  = :amend.Opportunity__r.ID) and (status__c = 'Requested' or status__c = 'Current Version')  order by Version__c desc];
  
       List<Amended_Products__c> newAPs = new List<Amended_Products__c>();
      
       integer CurrentVersion = 1;
       boolean isFirst = false;
       boolean updateOLIs = false;
       
           //based on the request map the new version
           List<Amended_Products__c> UpdatedAPs = new List<Amended_Products__c>();
           Map<ID,OpportunityLineItem> MapOLIs = new Map<ID, OpportunityLineItem>();
           for (OpportunityLineItem line : OLIs) {
                MapOLIs.put(line.Id, line);
           }
           List<OpportunityLineItem> UpdatedOLIs = new List<OpportunityLineItem>();
           Set<Id> oppIds = new Set<Id>();
           Opportunity OppUpdate = new Opportunity();
           boolean isOppUpdate = false;
           
           for (Amended_Products__c AP: APs){
         
               if ( AP.Amendment_Type__c  == 'Agency Switch' && AP.Status__c == 'Requested' ){
                   OppUpdate.id = amend.Opportunity__r.ID;
                   OppUpdate.Agency_3rd_Party__c = AP.Amended_Agency__c;
                   OppUpdate.Agency_3rd_Party_Transferred__c = AP.Original_Agency__c;
                   OppUpdate.Agency_3rd_Party_Transfer_Date__c = AP.Amended_Agency_3rd_Party_Transfer_Date__c;
                   isOppUpdate = true;
                   AP.Status__c = 'Fully Executed';
                   UpdatedAPs.add(AP);
               }
               if ( AP.Amendment_Type__c  == 'Start Date Change' && AP.Status__c == 'Requested' ){
                   updateOLIs = true;
                   MapOLIs.get(AP.Opportunity_Product_ID__c).Contractual_Start_Date__c = AP.Amended_Contractual_Start_Date__c;
                   MapOLIs.get(AP.Opportunity_Product_ID__c).Contractual_End_Date__c = AP.Amended_Contractual_Start_Date__c.addMonths(Integer.valueof(AP.Original_Quantity__c)) - 1;
                   AP.Status__c = 'Fully Executed';
                   UpdatedAPs.add(AP);
               }
               if ( AP.Amendment_Type__c  == 'End Date Change ONLY' && AP.Status__c == 'Requested' ){
                   updateOLIs = true;
                   MapOLIs.get(AP.Opportunity_Product_ID__c).Contractual_End_Date__c = AP.Amended_Contractual_End_Date__c;
                   AP.Status__c = 'Fully Executed';
                   UpdatedAPs.add(AP);
               }
               if ( AP.Amendment_Type__c  == 'Segmentation Change' && AP.Status__c == 'Requested' ){
                   updateOLIs = true;
                   MapOLIs.get(AP.Opportunity_Product_ID__c).Segmentation__c = AP.Amended_Segmentation__c;
                   AP.Status__c = 'Fully Executed';
                   UpdatedAPs.add(AP);
               }
               //Target Change is a manual process
               if (  (AP.Amendment_Type__c  == 'Product Split' 
                     || AP.Amendment_Type__c  == 'Product Swap' || AP.Amendment_Type__c  == 'Unit Change' 
                     || AP.Amendment_Type__c  == 'Target Change' 
                     || AP.Amendment_Type__c  == 'Change to Invoice Schedule' 
                     || AP.Amendment_Type__c  == 'Add/Modify Non-Finance Related Language') 
                   && AP.Status__c == 'Requested' ){
                
                   AP.Status__c = 'Fully Executed';
                   UpdatedAPs.add(AP);
               }
           }
	       if (isOppUpdate) Update OppUpdate;
           system.debug(UpdatedOLIs);
           if (updateOLIs){
               UpdatedOLIs = MapOLIs.values(); 
           }
           if (UpdatedOLIs.size() > 0) update UpdatedOLIs;
           if (UpdatedAPs.size() > 0) update UpdatedAPs;
           MapSOWAmendedProductsCurrentVersion(ContractIDs[0],'Fully Executed');
    }
    
    public static void MapSOWAmendedProductsCurrentVersion(string ContractID, string status){
       
       integer CurrentVersion = 1;
       Amendment__c amend = [SELECT id, Opportunity__r.Name, Parent_Opportunity__c,Parent_Opportunity__r.id,Parent_Opportunity__r.Agency_3rd_Party__r.id,Opportunity__r.Products__c, Opportunity__r.ID, Opportunity__r.Agency_3rd_Party__r.id  FROM Amendment__c WHERE Id =:ContractID Limit 1];
       List<OpportunityLineItem> OLIs = [SELECT id,Product_Name__c, Name,Guarantee__c,
                                         Contractual_Start_Date__c,Contractual_End_Date__c,
                                         Quantity,Total_Targets__c,Segmentation__c FROM OpportunityLineItem 
                                          where OpportunityId  = :amend.Opportunity__r.ID];
        
       List<Amended_Products__c> APs = new List<Amended_Products__c>();
       APs = [SELECT id,Version__c, Status__c FROM Amended_Products__c 
                                         where Opportunity__c  = :amend.Opportunity__r.ID 
                                         order by Version__c desc];
       if (APs.size() > 0){
           CurrentVersion = Integer.valueof(APs[0].Version__c) + 1;
       } 
       List<Amended_Products__c> newAPs = new List<Amended_Products__c>();
       Amended_Products__c AP1 = new Amended_Products__c();
       AP1.Opportunity__c = amend.Opportunity__r.ID;
       AP1.Status__c = 'Current Version';
       AP1.Version__c = CurrentVersion;
       AP1.Original_Agency__c = amend.Opportunity__r.Agency_3rd_Party__r.id;
       AP1.Contract_Amendment__c = amend.id;
       AP1.Active_Version__c = true;
       AP1.Parent_Opportunity__c = amend.Parent_Opportunity__c;
       AP1.Program__c = (amend.Parent_Opportunity__c == null) ? amend.Opportunity__r.ID : amend.Parent_Opportunity__c;
       newAPs.add(AP1);
       if (OLIs.size() > 0){
           for(OpportunityLineItem OLI : OLIs){
               Amended_Products__c AP = new Amended_Products__c();
               AP.Opportunity__c = amend.Opportunity__r.ID;
               AP.Opportunity_Product__c = OLI.ID;
               AP.Status__c = 'Current Version';
               AP.Version__c = CurrentVersion;
               AP.Original_Contractual_Start_Date__c = OLI.Contractual_Start_Date__c;
               AP.Original_Contractual_End_Date__c = OLI.Contractual_End_Date__c;
               AP.Original_Quantity__c = OLI.Quantity;
               AP.Original_Max_Targets_Per_Month__c = OLI.Total_Targets__c;
               AP.Contract_Amendment__c = amend.id;
               AP.Original_Engagement_Detail__c = OLI.Guarantee__c;
               AP.Active_Version__c = true;
               AP.Parent_Opportunity__c = amend.Parent_Opportunity__c;
               AP.Original_Segmentation__c = OLI.Segmentation__c;
               AP.Program__c = (amend.Parent_Opportunity__c == null) ? amend.Opportunity__r.ID : amend.Parent_Opportunity__c;
               newAPs.add(AP);
           }
       }
       //Also create the parent Opp current version
       List<Amended_Products__c> ParentAPs = new List<Amended_Products__c>();
       ParentAPs = [SELECT id,Version__c, Status__c FROM Amended_Products__c 
                                         where Opportunity__c  = :amend.Parent_Opportunity__r.id 
										 order by Version__c desc];
        if (ParentAPs.size() > 0){
            if (ParentAPs[0].Status__c == 'Fully Executed' || ParentAPs[0].Status__c == 'Cancelled'){
                // Map the Parent's current version
                CurrentVersion = Integer.valueof(ParentAPs[0].Version__c) + 1;
                List<OpportunityLineItem> ParentOLIs = [SELECT id,Product_Name__c, Name,Guarantee__c,
                                         Contractual_Start_Date__c,Contractual_End_Date__c,
                                         Quantity,Total_Targets__c,Segmentation__c FROM OpportunityLineItem 
                                          where OpportunityId  = :amend.Parent_Opportunity__r.id];
				Amended_Products__c AP2 = new Amended_Products__c();
                AP2.Opportunity__c = amend.Parent_Opportunity__r.id;
                AP2.Status__c = 'Current Version';
                AP2.Version__c = CurrentVersion;
                AP2.Original_Agency__c = amend.Parent_Opportunity__r.Agency_3rd_Party__r.id;
                AP2.Contract_Amendment__c = amend.id;
                AP2.Active_Version__c = true;
                //AP2.Parent_Opportunity__c = amend.Parent_Opportunity__c;
                AP2.Program__c = (amend.Parent_Opportunity__c == null) ? amend.Opportunity__r.ID : amend.Parent_Opportunity__c;
                newAPs.add(AP2);
       			
				if (ParentOLIs.size() > 0){
                   for(OpportunityLineItem OLI : ParentOLIs){
                       Amended_Products__c AP = new Amended_Products__c();
                       AP.Opportunity__c = amend.Parent_Opportunity__r.id;
                       AP.Opportunity_Product__c = OLI.ID;
                       AP.Status__c = 'Current Version';
                       AP.Version__c = CurrentVersion;
                       AP.Original_Contractual_Start_Date__c = OLI.Contractual_Start_Date__c;
                       AP.Original_Contractual_End_Date__c = OLI.Contractual_End_Date__c;
                       AP.Original_Quantity__c = OLI.Quantity;
                       AP.Original_Max_Targets_Per_Month__c = OLI.Total_Targets__c;
                       AP.Contract_Amendment__c = amend.id;
                       AP.Original_Engagement_Detail__c = OLI.Guarantee__c;
                       AP.Active_Version__c = true;
                       //AP.Parent_Opportunity__c = amend.Parent_Opportunity__c;
                       AP.Original_Segmentation__c = OLI.Segmentation__c;
                       AP.Program__c = (amend.Parent_Opportunity__c == null) ? amend.Opportunity__r.ID : amend.Parent_Opportunity__c;
                       newAPs.add(AP);
                   }
       			}
            }
       }
        
       //void the previous current verison
       List<Amended_Products__c> OldAPs = [SELECT id,status__c,Active_Version__c
                                        FROM Amended_Products__c
                                        where (Opportunity__c  = :amend.Parent_Opportunity__c or Opportunity__c  = :amend.Opportunity__r.id)
                                        and (status__c = 'Current Version' or status__c = 'Requested')];
        if (OldAPs.size() > 0 ){
        	for (Amended_Products__c oldAP : OldAPs){
                oldAP.Status__c = (oldAP.Status__c == 'Requested') ? status : 'Void';
                oldAP.Active_Version__c = false;
               
            }
            update OldAPs;
        }
        if (newAPs.size() > 0) insert newAPs;
	}
    
    
}