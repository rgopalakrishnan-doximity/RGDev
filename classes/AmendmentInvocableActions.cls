public class AmendmentInvocableActions {
    
    @InvocableMethod(label='Check CLM Approvals')
    public static void CheckCLMApprovals(List<string> ContractIDs)
    {
        //get contract details
        Amendment__c amend = [SELECT  Opportunity__r.Name, Opportunity__r.Lead_Number__c,  Opportunity__r.Products__c, Opportunity__r.ID,CLM_Deal_Desk_Approval__r.Parent_Agency__c,
                              CLM_Deal_Desk_Approval__c, Opportunity__r.CreatedDate,Agency__c,CLM_Deal_Desk_Approval__r.Agency__r.Name,CLM_Deal_Desk_Approval__r.Client__r.Name,
                              CLM_Approval_Restricted_By_Product__c,Account_Payable_Contact__c,Is_Custom_Reporting_Fee_Waived__c,Custom_Reporting_Fee_Waiver_Approval__c,
                              CLM_Product_Restriction_Language__c,CLM_Always_On_Product_Language__c,Is_Custom_Reporting_Included__c,Reporting_Partnership_Approval_Status__c,
                              Platform_Agreement_Reference__c,Platform_Agreement_Effective_Date__c,CLM_Regeneration__c,CLM_Document_ID__c,
                              Opportunity__r.Agency_3rd_Party__c,Opportunity__r.AccountId,Social_Proof_Enhancement_Language__c, Project_Title__c,
                              Advertiser_Name__r.Name,ROI_Approved_Contract_Value__c,ROI_Approval_Status__c,Total_Contract_Value__c FROM Amendment__c WHERE Id =:ContractIDs[0] Limit 1];
        
        string DDAID = '';
        string AgrID = '';
        string APContact = '';
        boolean AgencyChange = false;
        boolean PAChange = false;
        boolean AgencyInvYear = false;
        //if agency has been changed
        if (amend.CLM_Deal_Desk_Approval__c != null && 
            ((amend.Agency__c != amend.CLM_Deal_Desk_Approval__r.Agency__r.Name))
           ){
            // also check if it parent level
            Account ParentAgency = [select id, Parent.Name, name from account where id = :amend.Opportunity__r.Agency_3rd_Party__c Limit 1];
               if (ParentAgency.Parent.Name != amend.CLM_Deal_Desk_Approval__r.Agency__r.Name){
                   AgencyChange = true;
                    system.debug('Agency change ---' + AgencyChange);
                    //delete the previously assigned clauses to this contract
                    List<Clause_Library__c> delCLs = [SELECT ID FROM Clause_Library__c where Contract__c = :ContractIDs[0]];
                    if (delCLs.size() > 0) delete delCLs;
                    //redo invoice schedules
                    List<Invoice_Schedule__c> InvUpdt = [SELECT id, status__c
                                                  FROM Invoice_Schedule__c 
                                                  where Contract_Amendment__c = :ContractIDs[0] and Status__c  = 'Approved'];
                       for (Invoice_Schedule__c inv :InvUpdt){
                           inv.status__c = 'Cancelled';
                       }
                    update InvUpdt;
                    List<Rev_Rec_Schedule__c> RevRecUpdt = [SELECT id, status__c
                                                  FROM Rev_Rec_Schedule__c 
                                                  where Contract_Amendment__c = :ContractIDs[0] and Status__c  = 'Approved'];
                    for (Rev_Rec_Schedule__c rev :RevRecUpdt){
                           rev.status__c = 'Cancelled';
                       }
                    update RevRecUpdt;
               }
        }
        date AlwaysOnDate = date.newInstance(2024,6,30);
        date OppDate = Date.valueOf(amend.Opportunity__r.CreatedDate);
        boolean AlwaysOnOpp = ( OppDate > AlwaysOnDate) ? true : false;
        string ProductRestriction = System.Label.CLM_Product_Restriction;
        string AlwaysOnProductRestriction = System.Label.CLM_Always_On_Restriction;
        //string ProductRestrictionCheck = '';
        boolean ProdRestriction = false;
        boolean AlwaysRestriction = false;
        boolean SocialProofingLanguage = false;
        
        date PADate;
        string RollupParentId = '';
        string RollupAgencyId = '';
        string PARollupParentId = '';
        boolean tobeUpdated = false;
        //check if the account has a parent has a PA
        Account acc = [Select id, ParentID, Override_Parent_Level_Contracts__c  from Account where id = :amend.Opportunity__r.AccountID];
        RollupParentId = (acc.ParentID != null) ? acc.ParentId : acc.Id;
        PARollupParentId = (acc.ParentID != null && acc.Override_Parent_Level_Contracts__c == false) ? acc.ParentId : acc.Id;

        
        //check if Agency has a parent as well
        Account Agencyacc = [Select id, ParentID, Override_Parent_Level_Contracts__c  from Account where id = :amend.Opportunity__r.Agency_3rd_Party__c];
        RollupAgencyId = (Agencyacc.ParentID != null) ? Agencyacc.ParentId : Agencyacc.Id;
        

        List<string> ProductNames = new list<string>();
        List<string> TitleProductNames = new list<string>();
       
        if(amend.Opportunity__r.Products__c != null && amend.Opportunity__r.Products__c != '') {
            ProductNames = amend.Opportunity__r.Products__c.split(',');
        }
        //if NBE product is added
        List<OpportunityLineItem> OLIs = [SELECT id,Product_Name__c, Name,Productline__c,Contractual_Start_Date__c, Social_Proof_Enhancement__c  FROM OpportunityLineItem 
                                          where OpportunityId  = :amend.Opportunity__r.ID order by Contractual_Start_Date__c asc NULLS LAST];
        if (OLIs.size()>0){
            for (OpportunityLineItem OLI : OLIs){
                if (OLI.Product_Name__c.contains('NBE') || OLI.Name.contains('NBE')){
                    ProductNames.add('NBE');
                    break;
                }
            }
            for (OpportunityLineItem OLI : OLIs){
                //SocialProofingLanguage
                if (OLI.Product_Name__c.contains('DocNetwork') && OLI.Social_Proof_Enhancement__c ){
                    SocialProofingLanguage = true;
                    break;
                }
            }
            for (OpportunityLineItem OLI : OLIs){
                if(OLI.Product_Name__c.contains('NBE') || OLI.Product_Name__c.contains('Doc Dynamic')){
                    TitleProductNames.add(OLI.Product_Name__c);
                }else{
                    TitleProductNames.add(OLI.Productline__c);
                }
            }
        }

        string projecttitle = '';
        Set<String> uniqueNames = new Set<String>(TitleProductNames);
        String UniquePNames = String.join(new List<String>(uniqueNames), ',');
        
        Integer projectdate = !OLIs.isempty() && OLIs[0].Contractual_Start_Date__c !=null ? OLIs[0].Contractual_Start_Date__c.year() : date.today().year();
        //ProjectTitle
        if(amend.Project_Title__c == '' || amend.Project_Title__c == null){
           // Year + Doximity + Product + Product Subscription for Advertiser + Brand – Lead Number
           // DocNews, DocSpot
           projecttitle = projectdate  + ' Doximity ' +  UniquePNames.replace(',', ' + ') +  ' Subscription for ' + amend.Advertiser_Name__r.Name;// + ' - ' + amend.Opportunity__r.Lead_Number__c;
           amend.Project_Title__c =  projecttitle;
           tobeUpdated = true;
        }
        
        system.debug('pN---' + ProductNames);
        
        if (amend.CLM_Deal_Desk_Approval__c == null || amend.Account_Payable_Contact__c == null || AgencyChange){
            
            //select if the DDA Record for this agency and client combination
            List<Deal_Desk_Approval__c> DDAAgencyandClient = [SELECT ID,SOW_Version__c,Account_Payable_Contact__c, Assign_Clauses__c, SOW_Request_via_CLM_Approval__c
                                        FROM Deal_Desk_Approval__c WHERE 
                                        Agency__c = :RollupAgencyId
                                        AND (Client__c = :RollupParentId OR Client__c = :amend.Opportunity__r.AccountId)
                                        AND SOW_Request_via_CLM_Approval__c = 'Approved'];
            
            if (DDAAgencyandClient.size() > 0){
                DDAID = DDAAgencyandClient[0].ID;
                amend.CLM_Deal_Desk_Approval__c = DDAAgencyandClient[0].ID;
                amend.Account_Payable_Contact__c = DDAAgencyandClient[0].Account_Payable_Contact__c;
                //ProductRestriction = DDAAgencyandClient[0].Product_Restriction__c;
                tobeUpdated = true;
            } 
            
            List<Deal_Desk_Approval__c> DDAAgencyOnly = [SELECT ID,SOW_Version__c,Account_Payable_Contact__c, Assign_Clauses__c, SOW_Request_via_CLM_Approval__c
                                        FROM Deal_Desk_Approval__c WHERE 
                                        Agency__c = :amend.Opportunity__r.Agency_3rd_Party__c
                                        AND Agency_Only_Formula__c  = true
                                        AND SOW_Request_via_CLM_Approval__c = 'Approved'];
            
            if (DDAAgencyOnly.size() > 0 && DDAID == ''){
                DDAID = DDAAgencyOnly[0].ID;
                amend.CLM_Deal_Desk_Approval__c = DDAAgencyOnly[0].ID;
                amend.Account_Payable_Contact__c = DDAAgencyOnly[0].Account_Payable_Contact__c;
                //ProductRestriction = DDAAgencyOnly[0].Product_Restriction__c;
                tobeUpdated = true;
            } else{
                //if the agency approval is not found - find it at the agency's Parent level
                List<Deal_Desk_Approval__c> DDAAgencyParentOnly = [SELECT ID,SOW_Version__c,Account_Payable_Contact__c, Assign_Clauses__c, SOW_Request_via_CLM_Approval__c
                                        FROM Deal_Desk_Approval__c WHERE 
                                        Agency__c = :RollupAgencyId
                                        AND Agency_Only_Formula__c  = true
                                        AND SOW_Request_via_CLM_Approval__c = 'Approved'];
                
                if (DDAAgencyParentOnly.size() > 0 && DDAID == ''){
                    DDAID = DDAAgencyParentOnly[0].ID;
                    amend.CLM_Deal_Desk_Approval__c = DDAAgencyParentOnly[0].ID;
                    amend.Account_Payable_Contact__c = DDAAgencyParentOnly[0].Account_Payable_Contact__c;
                    //ProductRestriction = DDAAgencyOnly[0].Product_Restriction__c;
                    tobeUpdated = true;
                }
            }
            //
            if(!tobeUpdated && AgencyChange){
                //It did not find the approval for the new agency so undo the previous setting
                amend.CLM_Deal_Desk_Approval__c = null;
                amend.Account_Payable_Contact__c = null;
                tobeUpdated = true;
            }
            
      	}
        
        if (amend.Platform_Agreement_Reference__c == null || AgencyChange){
            system.debug('pa');
                                      
            List<Agreement__c> AGRClientandAgency = [SELECT id,Effective_Date__c from Agreement__c where 
                                            Account__c = :PARollupParentId
                                            and Agency__c = :amend.Opportunity__r.Agency_3rd_Party__c
                                            and (Agreement_Type__c = 'PA' or Agreement_Type__c = 'Portal PA')
                                            and Status__c = 'Completed' order by Effective_date__c desc limit 1];
            
            if (AGRClientandAgency.size() > 0) {
                tobeUpdated = true;
                AgrID = AGRClientandAgency[0].ID;
                amend.Platform_Agreement_Reference__c = AGRClientandAgency[0].ID;
                amend.Platform_Agreement_Effective_Date__c = AGRClientandAgency[0].Effective_Date__c;
                PAChange = true;
            }
            
            List<Agreement__c> AGRAgencyOnly = [SELECT id, Effective_Date__c from Agreement__c where 
                                            Account__c = :amend.Opportunity__r.Agency_3rd_Party__c
                                          	and Account_Type__c = 'Agency'
                                            and Agency__c = ''
                                            and (Agreement_Type__c = 'PA' or Agreement_Type__c = 'Portal PA')
                                            and Status__c = 'Completed' order by Effective_date__c desc limit 1];
            if (AGRAgencyOnly.size() > 0 && AgrID == ''){
                tobeUpdated = true;
                AgrID = AGRAgencyOnly[0].ID;
                amend.Platform_Agreement_Reference__c = AGRAgencyOnly[0].ID;
                amend.Platform_Agreement_Effective_Date__c = AGRAgencyOnly[0].Effective_Date__c;
                PAChange = true;
            } else{
                //parent agency PA
                List<Agreement__c> AGRParentAgencyOnly = [SELECT id, Effective_Date__c from Agreement__c where 
                                            Account__c = :RollupAgencyId
                                          	and Account_Type__c = 'Agency'
                                            and Agency__c = ''
                                            and (Agreement_Type__c = 'PA' or Agreement_Type__c = 'Portal PA')
                                            and Status__c = 'Completed' order by Effective_date__c desc limit 1];

                if (AGRParentAgencyOnly.size() > 0 && AgrID == ''){
                    tobeUpdated = true;
                    AgrID = AGRParentAgencyOnly[0].ID;
                    amend.Platform_Agreement_Reference__c = AGRParentAgencyOnly[0].ID;
                    amend.Platform_Agreement_Effective_Date__c = AGRParentAgencyOnly[0].Effective_Date__c;
                    PAChange = true;
                }
            }
            
            List<Agreement__c> AGRClientOnly = [SELECT id,Effective_Date__c from Agreement__c where 
                                            Account__c = :PARollupParentId
                                          	and Account_Type__c = 'Direct'
                                            and Agency__c = ''
                                            and (Agreement_Type__c = 'PA' or Agreement_Type__c = 'Portal PA')
                                            and Status__c = 'Completed' order by Effective_date__c desc limit 1];
            
            if (AGRClientOnly.size() > 0 && AgrID == ''){
                tobeUpdated = true;
                AgrID = AGRClientOnly[0].ID;
                amend.Platform_Agreement_Reference__c = AGRClientOnly[0].ID;
                amend.Platform_Agreement_Effective_Date__c = AGRClientOnly[0].Effective_Date__c;
                PAChange = true;
            } 
            
           /* List<Agreement__c> AGRPortalPAOnly = [SELECT id,Effective_Date__c from Agreement__c where
                                            Account__c = :PARollupParentId
                                          	and Agreement_Type__c = 'Portal PA'
                                            and Status__c = 'Completed' order by Effective_date__c desc limit 1];

            if (AGRPortalPAOnly.size() > 0 ){
                tobeUpdated =  (amend.Portal_PA_Reference__c != AGRPortalPAOnly[0].ID) ? true : false;
                amend.Portal_PA_Reference__c = AGRPortalPAOnly[0].ID;
                amend.Portal_PA_Effective_Date__c = AGRPortalPAOnly[0].Effective_Date__c;
                PAChange = true;
            }*/


            
            if (!PAChange && AgencyChange){
                amend.Platform_Agreement_Reference__c = null;
                amend.Platform_Agreement_Effective_Date__c = null;
            }
     
        }
        //ROI Approval Change check
        if ((amend.ROI_Approval_Status__c == 'ROI Study Approved' ||
            amend.ROI_Approval_Status__c == 'ROI Guarantee Approved') && amend.ROI_Approved_Contract_Value__c != amend.Total_Contract_Value__c ){
            //fire the task to strategic analytics and reset the status to Pending Approval
            amend.ROI_Approval_Status__c = null;
        }
        //check if Product based restriction for CLM approval is there .. this needs to be done everytime as products can be added anytime
        //ProductRestrictionCheck = (amend.CLM_Deal_Desk_Approval__r.Product_Restriction__c != null) ? amend.CLM_Deal_Desk_Approval__r.Product_Restriction__c : ProductRestriction;
        //system.debug('opp product2 ==' + ProductRestrictionCheck);
        if (ProductRestriction != null){
           for (string s : ProductNames){
               if (!ProdRestriction){
                  ProdRestriction = ProductRestriction.contains(s.trim()) ? true : false;
               }
               if (ProdRestriction) break;
           }
            if (amend.CLM_Product_Restriction_Language__c != ProdRestriction){
                amend.CLM_Product_Restriction_Language__c = ProdRestriction;
                amend.CLM_Approval_Restricted_By_Product__c = false;
                tobeUpdated = true; 
            }
           
        }
        //Social Proofing
        system.debug('SocialProofingLanguage--' +  SocialProofingLanguage + '---' + amend.Social_Proof_Enhancement_Language__c );
        
        if (amend.Social_Proof_Enhancement_Language__c  != SocialProofingLanguage){
            amend.Social_Proof_Enhancement_Language__c = SocialProofingLanguage;
            tobeUpdated = true; 
        }
        
        if (AlwaysOnProductRestriction != null){
            if (AlwaysOnOpp){
                  for (OpportunityLineItem OLI : OLIs){
                       if (!AlwaysRestriction){
                          AlwaysRestriction = AlwaysOnProductRestriction.contains(OLI.Product_Name__c.trim()) ? true : false;
                       }
                       if (AlwaysRestriction) break;
                  }  
                if (amend.CLM_Always_On_Product_Language__c  != AlwaysRestriction){
                    amend.CLM_Always_On_Product_Language__c = AlwaysRestriction;
                    tobeUpdated = true; 
                }
            }else{
                if (amend.CLM_Always_On_Product_Language__c  != AlwaysRestriction){
                    amend.CLM_Always_On_Product_Language__c = AlwaysRestriction;
                    tobeUpdated = true; 
                }
            }
        }
        system.debug('update ==' + ProdRestriction + '--' + tobeUpdated);
        if (tobeUpdated){
          if (amend.CLM_Document_ID__c != '' && AgencyChange )  amend.CLM_Regeneration__c = true;
          if (amend.Is_Custom_Reporting_Included__c && AgencyChange) amend.Reporting_Partnership_Approval_Status__c = null;
          if (amend.Is_Custom_Reporting_Fee_Waived__c && AgencyChange && amend.Custom_Reporting_Fee_Waiver_Approval__c != 'Diamond Approved') {
                system.debug('--CRF set to null--');
           		amend.Custom_Reporting_Fee_Waiver_Approval__c = null;
          }
          //amend.CheckList_Verification__c = false;
          update amend;  
        }
        //Dochecklist again
        //get contract details
        Amendment__c amend2 = [SELECT ID, Opportunity__r.Name, Opportunity__r.Products__c, CLM_Deal_Desk_Approval__c, 
                              Client_Success_Launch_Date_Review__c,Name,
                              CLM_Approval_Restricted_By_Product__c, Opportunity__r.Requires_Approval__c,
                              Opportunity__r.Discount_Approval_Status__c,Opportunity__r.ID,
                              Reporting_Partnership_Approval_Status__c,Is_Custom_Reporting_Included__c,
                              Is_ROI_Included__c,ROI_Approval_Status__c,
                              CLM_Deal_Desk_Approval__r.SOW_Request_via_CLM_Approval__c, 
                              CLM_Deal_Desk_Approval__r.Agency_requires_first_invoices_same_year__c,
                              Agency_Invoice_Schedule_Restriction__c,Override_Agency_Invoice_Sch_Restriction__c, 
                              CLM_Deal_Desk_Approval__r.Template_Creation_Options__c, Non_Standard_Language_Included__c,
                              DD_Confirm_Segmentation_Accuracy__c,Check_List_Review_Acknowledgement__c,
                              Platform_Agreement_Reference__c,Platform_Agreement_Effective_Date__c,
                              Opportunity__r.Agency_3rd_Party__c,Opportunity__r.AccountId, Advertiser_Name__r.Name,
                              ROI_Approved_Contract_Value__c, Client_SOW_Signer_Email__c,Client_SOW_Signer_Name__c,
                              CLM_Deal_Desk_Approval__r.Account_Payable_Contact__c,Initial_Contract_Value__c,Multiple_Documents_required_to_Book__c,
                              Account_Payable_Contact__c,CheckList_Verification__c,CLM_Deal_Desk_Approval__r.Assign_Clauses_Formula__c, 
                              Total_Contract_Value__c FROM Amendment__c WHERE Id =:ContractIDs[0] Limit 1];
        
        List<OpportunityLineItem> OLIs2 = [SELECT id,Product_Name__c, Name,Guarantee__c,ED_Mismatch__c 
                                          FROM OpportunityLineItem 
                                          where OpportunityId  = :amend.Opportunity__r.ID
                                          and Product_Name__c NOT IN ('Data Fee', 'Data Fee Value Add', 'Formulary Data Fee' )
                                          and (Guarantee__c = null
                                          or ED_Mismatch__c like '%flag_yellow%')];
        
        List<Invoice_Schedule__c> Inv = [SELECT id, status__c
                                          FROM Invoice_Schedule__c 
                                          where Contract_Amendment__c = :ContractIDs[0] and Status__c  = 'Approved'];
        
        List<Clause_Library__c> CLs = [SELECT ID FROM Clause_Library__c where Contract__c = :ContractIDs[0]];
        List<Clause_Library__c> insertClause = new List<Clause_Library__c>();
        
        if (CLs.size() == 0 && amend2.CLM_Deal_Desk_Approval__r.Assign_Clauses_Formula__c){ 
            
            //***TO DO Associated Clause content should be assigned with assigned content **//
            List<Clause_Library__c> lstApprovedClauses = [SELECT ID, Type__c,Clause_Library_Name__c, Content__c, Product_Family__c, Agency__c,Client__c, Clause_Kind__c, SOW_Version__c,
      					 	Description__c, Subscription_a__c,Content_Volume_b__c, Targeting_Above_Table_c__c, Targeting_Beneath_Table_c__c,
     						Program_Performance_d__c,Initial_Clause__c, Initial_Clause_with_Targets__c, Content_Hosting__c,
       						Coverage_Reservation_Main_d__c, Coverage_Renewal_e__c, Feed_Exclusive_Nature_Clause_a__c,
       						X15_Day_Hold_d__c, ROFR_Clause__c, status__c,Associated_Default_Clause__c,
                            Version__c,Version_Active_Since__c,Omit_Clause__c
        					FROM Clause_Library__c WHERE 
      						Deal_Desk_Approval__c = :amend.CLM_Deal_Desk_Approval__c and Status__c = 'Approved'];
           
           List<ID> AssociateIDs = new List<ID>();
           if (lstApprovedClauses.size() > 0){
               for(Clause_Library__c CL : lstApprovedClauses){
                   if (CL.Clause_Kind__c == 'Default') AssociateIDs.add(CL.Associated_Default_Clause__c);
               }
           }
           Map<ID, Clause_Library__c> mapAssociateClause = new Map<ID, Clause_Library__c>();
           if (AssociateIDs.size() > 0){
           	 mapAssociateClause = new Map<ID, Clause_Library__c>([SELECT ID, Type__c,Clause_Library_Name__c, Content__c, Product_Family__c, Agency__c,Client__c, Clause_Kind__c, SOW_Version__c,
                                                                                            Description__c, Subscription_a__c,Content_Volume_b__c, Targeting_Above_Table_c__c, Targeting_Beneath_Table_c__c,
                                                                                            Program_Performance_d__c,Initial_Clause__c, Initial_Clause_with_Targets__c, Content_Hosting__c,
                                                                                            Coverage_Reservation_Main_d__c, Coverage_Renewal_e__c, Feed_Exclusive_Nature_Clause_a__c,
                                                                                            X15_Day_Hold_d__c, ROFR_Clause__c, status__c,Associated_Default_Clause__c,
                                                                  							Version__c,Version_Active_Since__c,Omit_Clause__c
                                                                                            FROM Clause_Library__c WHERE 
                                                                                            ID IN :AssociateIDs]);
           }
            
           if(lstApprovedClauses.size() > 0){
               
               for(Clause_Library__c CL :lstApprovedClauses){
                   
                  Clause_Library__c newCL = new Clause_Library__c();
                  newCL.Clause_Kind__c = CL.Clause_Kind__c;
                  newCL.Omit_Clause__c = CL.Omit_Clause__c;
                  newCL.Content__c = (CL.Clause_Kind__c == 'Default') ? mapAssociateClause.get(CL.Associated_Default_Clause__c).Content__c : CL.Content__c;
                  newCL.Content_Volume_b__c = (CL.Clause_Kind__c == 'Default') ? mapAssociateClause.get(CL.Associated_Default_Clause__c).Content_Volume_b__c :CL.Content_Volume_b__c;
                  newCL.Contract__c = amend2.ID;
                  newCL.Coverage_Renewal_e__c = (CL.Clause_Kind__c == 'Default') ? mapAssociateClause.get(CL.Associated_Default_Clause__c).Coverage_Renewal_e__c : CL.Coverage_Renewal_e__c;
                  newCL.Coverage_Reservation_Main_d__c = (CL.Clause_Kind__c == 'Default') ? mapAssociateClause.get(CL.Associated_Default_Clause__c).Coverage_Reservation_Main_d__c : CL.Coverage_Reservation_Main_d__c;
                  newCL.Description__c = (CL.Clause_Kind__c == 'Default') ? mapAssociateClause.get(CL.Associated_Default_Clause__c).Description__c :CL.Description__c;
                  newCL.Feed_Exclusive_Nature_Clause_a__c = (CL.Clause_Kind__c == 'Default') ? mapAssociateClause.get(CL.Associated_Default_Clause__c).Feed_Exclusive_Nature_Clause_a__c : CL.Feed_Exclusive_Nature_Clause_a__c;
                  newCL.Initial_Clause__c = (CL.Clause_Kind__c == 'Default') ? mapAssociateClause.get(CL.Associated_Default_Clause__c).Initial_Clause__c : CL.Initial_Clause__c;
                  newCL.Initial_Clause_with_Targets__c = (CL.Clause_Kind__c == 'Default') ? mapAssociateClause.get(CL.Associated_Default_Clause__c).Initial_Clause_with_Targets__c : CL.Initial_Clause_with_Targets__c;
                  newCL.Opportunity__c = amend.Opportunity__r.ID;
                  newCL.Product_Family__c = (CL.Clause_Kind__c == 'Default') ? mapAssociateClause.get(CL.Associated_Default_Clause__c).Product_Family__c : CL.Product_Family__c;
                  newCL.Program_Performance_d__c = (CL.Clause_Kind__c == 'Default') ? mapAssociateClause.get(CL.Associated_Default_Clause__c).Program_Performance_d__c : CL.Program_Performance_d__c;
                  newCL.ROFR_Clause__c = (CL.Clause_Kind__c == 'Default') ? mapAssociateClause.get(CL.Associated_Default_Clause__c).ROFR_Clause__c : CL.ROFR_Clause__c;
                  newCL.SOW_Version__c = CL.SOW_Version__c;
                  newCL.Subscription_a__c = (CL.Clause_Kind__c == 'Default') ? mapAssociateClause.get(CL.Associated_Default_Clause__c).Subscription_a__c : CL.Subscription_a__c;
                  newCL.Targeting_Above_Table_c__c = (CL.Clause_Kind__c == 'Default') ? mapAssociateClause.get(CL.Associated_Default_Clause__c).Targeting_Above_Table_c__c : CL.Targeting_Above_Table_c__c;
                  newCL.Targeting_Beneath_Table_c__c = (CL.Clause_Kind__c == 'Default') ? mapAssociateClause.get(CL.Associated_Default_Clause__c).Targeting_Beneath_Table_c__c : CL.Targeting_Beneath_Table_c__c;
                  newCL.Type__c = CL.Type__c;
                  newCL.X15_Day_Hold_d__c = (CL.Clause_Kind__c == 'Default') ? mapAssociateClause.get(CL.Associated_Default_Clause__c).X15_Day_Hold_d__c : CL.X15_Day_Hold_d__c;
                  newCL.Status__c = 'Approved';
                  newCL.Version__c = (CL.Clause_Kind__c == 'Default') ? mapAssociateClause.get(CL.Associated_Default_Clause__c).Version__c : CL.Version__c;
                  newCL.Version_Active_Since__c = (CL.Clause_Kind__c == 'Default') ? mapAssociateClause.get(CL.Associated_Default_Clause__c).Version_Active_Since__c : CL.Version_Active_Since__c;
                  newCL.Clause_Library_Name__c = (CL.Type__c == 'Product Library SOW V1') ? amend2.Name + ' > ' + CL.Product_Family__c : amend2.Name + ' > ' + CL.Type__c;
                  insertClause.add(newCL); 
               }
            }
            insert insertClause;
       
        }
        CLs = [SELECT ID FROM Clause_Library__c where Contract__c = :ContractIDs[0]];
        
        boolean SOWChecklist = true;
        //IF all the checklist is passed then SOWChecklist value will be true 
        
        SOWChecklist = amend2.CLM_Deal_Desk_Approval__c == null ? false : true;
        system.debug('DDA --' + amend2.CLM_Deal_Desk_Approval__c);
        
        if (SOWChecklist){
            SOWChecklist = (amend2.CLM_Deal_Desk_Approval__r.SOW_Request_via_CLM_Approval__c != 'Approved' && amend2.CLM_Deal_Desk_Approval__r.Template_Creation_Options__c != 'Not Approved for CLM')  ? false : true;
            system.debug('DDA3 --' + amend2.CLM_Deal_Desk_Approval__r.SOW_Request_via_CLM_Approval__c);
        }
        
        if (SOWChecklist){
            SOWChecklist = amend2.Platform_Agreement_Reference__c == null ? false : true;
            system.debug('DDA4 --' + amend2.Platform_Agreement_Reference__c);
        }
        
       
        if (SOWChecklist){
            SOWChecklist = amend2.Client_Success_Launch_Date_Review__c == false ? false : true;
            system.debug('DDA5 --' + amend2.Client_Success_Launch_Date_Review__c);
        }
        
       
        if (SOWChecklist){
            SOWChecklist = !amend2.Opportunity__r.Requires_Approval__c.contains('No') ? false : true;
            system.debug('DDA6 --' + amend2.Opportunity__r.Requires_Approval__c);
        }
        
       
	    if (SOWChecklist){
            SOWChecklist = amend2.Opportunity__r.Discount_Approval_Status__c != 'Rejected' ? true : false;
            system.debug('DDA7 --' + amend2.Opportunity__r.Discount_Approval_Status__c);
        }
        
        if (SOWChecklist){
            SOWChecklist = (amend2.Is_Custom_Reporting_Included__c && amend2.Reporting_Partnership_Approval_Status__c != 'Approved') ? false : true;
            system.debug('DDA8 --' + amend2.Reporting_Partnership_Approval_Status__c);
        }
        
        
        if (SOWChecklist){
            if (amend2.Is_ROI_Included__c){
              SOWChecklist = (amend2.ROI_Approval_Status__c == 'ROI Study Approved' || amend2.ROI_Approval_Status__c == 'ROI Guarantee Approved') ? true : false;
            }
        }
        
        
        if (SOWChecklist){
            SOWChecklist = (amend2.Client_SOW_Signer_Email__c != '' && amend2.Client_SOW_Signer_Name__c != '') ? true : false;
            system.debug('DDA10 --' + amend2.Client_SOW_Signer_Email__c + ' - ' + amend2.Client_SOW_Signer_Name__c);
        }
        
        
        if (SOWChecklist){
            SOWChecklist = amend2.Account_Payable_Contact__c == null ? false : true;
            system.debug('DDA11 --' + amend2.Account_Payable_Contact__c);
        
        }
        
        if (SOWChecklist){
            SOWChecklist = OLIs2.size() > 0 ? false :true;
            system.debug('DDA12 --' + OLIs2.size());
        }
        
        if (SOWChecklist){
            SOWChecklist = Inv.size() > 0 && amend2.Initial_Contract_Value__c == amend2.Total_Contract_Value__c ? true :false;
            system.debug('DDA12 --' + Inv.size());
        }
        
        if (SOWChecklist){
            SOWChecklist = (CLs.size() == 0 && amend2.CLM_Deal_Desk_Approval__r.Assign_Clauses_Formula__c) ? false : true;
            system.debug('DDA12 --' + CLs.size());
        }
        
        //Non standard Language
        
        if (SOWChecklist){
            SOWChecklist = (amend2.Non_Standard_Language_Included__c == '') ? false : true;
            system.debug('DDA15 --' + amend2.Non_Standard_Language_Included__c);
        }
        
        //Multiple Document Check
        if (SOWChecklist){
            SOWChecklist = (amend2.Multiple_Documents_required_to_Book__c == '' || amend2.Multiple_Documents_required_to_Book__c == null) ? false : true;
            system.debug('DDA16 --' + amend2.Multiple_Documents_required_to_Book__c);
        }
        
        if (SOWChecklist){
            SOWChecklist = amend2.CLM_Approval_Restricted_By_Product__c  ? false : true;
            system.debug('DDA2 --' + amend2.CLM_Approval_Restricted_By_Product__c);
        }
        
        
        //Agency requires first invoice same year check
        //if (SOWChecklist){
            //Agency_Invoice_Schedule_Restriction__c Override_Agency_Invoice_Sch_Restriction__c 
            if (amend2.CLM_Deal_Desk_Approval__r.Agency_requires_first_invoices_same_year__c == 'Yes' && amend2.Override_Agency_Invoice_Sch_Restriction__c){
                SOWChecklist = true;
                system.debug('DDA16 -- Agency inv year step 1');
            }else if (amend2.CLM_Deal_Desk_Approval__r.Agency_requires_first_invoices_same_year__c == 'Yes'&& !amend2.Override_Agency_Invoice_Sch_Restriction__c){
                //check the earliest date of the invoice 
                AggregateResult InvaggregateResults = [SELECT min(Invoice_Date__c) InvoiceStartDate
                                                     from Invoice_Schedule__c 
                                                      where Contract_Amendment__c = :ContractIDs[0] and Status__c  = 'Approved'];
                AggregateResult PrgaggregateResults = [SELECT min(Contractual_Start_Date__c) ProgramStartDate,
                                                      max(Contractual_End_Date__c) ProgramEndDate, sum(Quantity) Terms 
                                                      from OpportunityLineItem where OpportunityId = :amend2.Opportunity__r.ID];
                
                if (InvaggregateResults != null && PrgaggregateResults != null){
                    date invdate = (Date)InvaggregateResults.get('InvoiceStartDate');
                	date stdate = (Date)PrgaggregateResults.get('ProgramStartDate');
                    if (invdate == null){
                       AgencyInvYear = true; 
                       SOWChecklist = false;
                    }else if (invdate.Year() != stdate.Year()){
                       AgencyInvYear = true; 
                       SOWChecklist = false;
                    }else{
                       AgencyInvYear = false; 
                       SOWChecklist = true; 
                    }
                }else{
                    AgencyInvYear = true; 
                    SOWChecklist = false;
                    system.debug('DDA16 -- Invoice not found');
                }
		   		system.debug('Agency inv year step 2');
                
            }else if (amend2.CLM_Deal_Desk_Approval__r.Agency_requires_first_invoices_same_year__c == 'No'){
                SOWChecklist = true;
                system.debug('Agency inv year step 3');
            }
        //}
        
        if (SOWChecklist || AgencyChange){
            SOWChecklist = (!amend2.DD_Confirm_Segmentation_Accuracy__c || AgencyChange == true) ? false : true;
            system.debug('DDA13 --' + amend2.DD_Confirm_Segmentation_Accuracy__c);
        }
        
        if (SOWChecklist || AgencyChange){
            SOWChecklist = (!amend2.Check_List_Review_Acknowledgement__c || AgencyChange == true) ? false : true;
            system.debug('DDA14 --' + amend2.Check_List_Review_Acknowledgement__c);
        }
        
        //
        //bypass if acknowledged
        SOWChecklist =  (amend2.Check_List_Review_Acknowledgement__c && AgencyChange == false) ? true : SOWChecklist;
        
        
        system.debug('previous==' + amend2.CheckList_Verification__c  + 'current--' + SOWChecklist);
        
        if (amend2.CheckList_Verification__c != SOWChecklist || amend2.Agency_Invoice_Schedule_Restriction__c != AgencyInvYear){
            amend2.CheckList_Verification__c = SOWChecklist;
            amend2.Agency_Invoice_Schedule_Restriction__c = AgencyInvYear;
           	update amend2;
            system.debug('here---');
        }
    }

}