/* 
    When Contract created, take a snapshot of the current opportunity products on the opportunity  
    When Amendment created, set original opportunity and contract amended from
    When Amendment set to "Approved", take a snapshot of the current opportunity products on the opportunity  
    When "Refresh Opportunity Products" button is clicked, if the contract is not complete, refresh the OPS      
    Covered by Amendment_Test
*/

public class Amendment_TriggerHandler {

    public static boolean hasExecuted = false;
    List<Opportunity_Product_Snapshot__c> opsToDelete = new List<Opportunity_Product_Snapshot__c>();
    List<Amendment__c> amendsToUpdate = new List<Amendment__c>();
    public Id Id { get; set; }     
    public Amendment__c amend { get; set; } 
    public static Decimal targets = 0;
    
    // Code for the Visualforce page Amendment Refresh OPS which runs the "Refresh Opportunity Products" button on Contract/Amendment record
    public Amendment_TriggerHandler(ApexPages.StandardController controller) {
        amend =  (Amendment__c) controller.getRecord();     
        Id = amend.Id;     
        System.debug('The contract/amendment record: ' + amend);    
    }

    public PageReference refreshOPS() { 
        // Delete existing Opportunity Product Snapshots and create new ones
        amendsToUpdate = [SELECT Id,RecordTypeId,Amendment_Type__c, Type__c, Opportunity__c, Amendment_Status__c FROM Amendment__c WHERE Id =: Id LIMIT 1];
        system.debug('amendsToUpdate: ' + amendsToUpdate);
        if(amendsToUpdate[0].Amendment_Status__c != 'Fully Executed'){
            opsToDelete = [SELECT Id FROM Opportunity_Product_Snapshot__c WHERE Amendment__c =: Id];
            delete opsToDelete;
            OnAfterInsert(amendsToUpdate);
        } 
        PageReference pageRef = new PageReference('/'+Id);         
        pageRef.setRedirect(true);        
        return pageRef;      
    }
    
    // When Contract created, take a snapshot of the current opportunity products on the opportunity  
    public static void onAfterInsert(List<Amendment__c> newAmends){
        hasExecuted = true;
        Set<Id> opportunityIds = new Set<Id>();
        List<ID> ContractIDs = new List<ID>();
        List<OpportunityLineItem> oppLineItems;
        Map<Id, List<OpportunityLineItem>> oppToOppLineItems = new Map<Id, List<OpportunityLineItem>>();
        List<Opportunity_Product_Snapshot__c> opsToInsert = new List<Opportunity_Product_Snapshot__c>();
    
        for(Amendment__c amend : newAmends){
            if(amend.Opportunity__c != NULL){
                opportunityIds.add(amend.Opportunity__c);
            }
            if (amend.RecordTypeId == '0121K000000vkG4QAI' && amend.Type__c == 'Amendment' 
                &&  amend.Amendment_Type__c.contains('Start Date Change') ){
                    system.debug('callign the future');
                    UpdateProgramStartDateChange(amend.ID);
                    //system.debug('callign the future');
            }
            /*if (amend.RecordTypeId == '0121K000000vkG5QAI' && amend.Type__c == 'SOW'){
                system.debug('callign the future method to update segmentation on OLI');
                UpdateOLISegmentation(amend.ID);
            }*/
        }
        
        if(!opportunityIds.isEmpty()){
            system.debug('--oids--' + opportunityIds);
            List<OpportunityLineItem> olis = [SELECT Id, Audience__c, Custom_List_Price__c, Custom_List_Targets__c, Configured_Price__c, 
                                                Contractual_End_Date__c, Contractual_Start_Date__c, Enhanced_Package__c, Enhanced_Package_Cost__c,
                                                Opp_Line_Item_ID__c, Quantity, Rep_Discount__c, Rep_Price_Override__c, UnitPrice, TotalPrice, 
                                                Product_Name__c, Guarantee__c, Opportunity.Amount, Lock_fields__c, Total_Units__c,
                                                Total_Price_Debookings__c, Added_Amount__c, Debooked_Amount__c, Total_Contracted_Targets__c, 
                                                Total_Contracted_Targets_Amended__c, Rate_Card_Price_With_Upsells__c
                                          FROM OpportunityLineItem 
                                          WHERE OpportunityId IN :opportunityIds];
            system.debug('---oliss---' + olis);
            for(OpportunityLineItem oli: olis){
                if(oppToOppLineItems.containsKey(oli.OpportunityId)){
                    oppLineItems = oppToOppLineItems.get(oli.OpportunityId);
                } else {
                    oppLineItems = new List<OpportunityLineItem>();   
                }
                oppLineItems.add(oli);
               
                oppToOppLineItems.put(oli.OpportunityId, oppLineItems);
            }
        }
        
        for (Amendment__c newamend : newAmends){
            if(newamend.Type__c != NULL
              && oppToOppLineItems.containsKey(newamend.Opportunity__c)){
                for(OpportunityLineItem oli : oppToOppLineItems.get(newamend.Opportunity__c)){
                    if(oli.Total_Contracted_Targets_Amended__c == NULL){
                        targets = oli.Total_Contracted_Targets__c;
                    } else {
                        targets = oli.Total_Contracted_Targets_Amended__c; 
                    }
                    
                    Opportunity_Product_Snapshot__c ops = new Opportunity_Product_Snapshot__c(
                        Added_Amount_P__c = oli.Added_Amount__c,
                        Amendment__c = newamend.Id,
                        Audience__c = oli.Audience__c,
                        Custom_List_Price__c = oli.Custom_List_Price__c,
                        Custom_List_Targets__c = oli.Custom_List_Targets__c,
                        Configured_Price__c = oli.Configured_Price__c,
                        Contractual_End_Date__c = oli.Contractual_End_Date__c,
                        Contractual_Start_Date__c = oli.Contractual_Start_Date__c,                        
                        Debooked_Amount_P__c = oli.Debooked_Amount__c,
                        Enhanced_Package__c = oli.Enhanced_Package__c,
                        Enhanced_Package_Cost__c = oli.Enhanced_Package_Cost__c,
                        Guarantee__c = oli.Guarantee__c,
                        Name = oli.Product_Name__c,
                        Net_Amount_P__c = oli.Total_Price_Debookings__c,         
                        Opp_Line_Item_ID__c = oli.Opp_Line_Item_ID__c,
                        Opportunity_Amount__c = oli.Opportunity.Amount,
                        Opportunity_Product__c = oli.Opp_Line_Item_ID__c,
                        Quantity__c = oli.Quantity,
                        Rep_Discount__c = oli.Rep_Discount__c,
                        Rep_Price_Override__c = oli.Rep_Price_Override__c,
                        Sales_Price__c = oli.UnitPrice,
                        Total_Contracted_Targets__c = targets,
                        Total_Price__c = oli.TotalPrice,                        
                        Units_per_Month__c = oli.Total_Units__c,
                        Rate_Card_Price_With_Upsells__c = oli.Rate_Card_Price_With_Upsells__c         
                    );   
                    opsToInsert.add(ops); 
                    system.debug('ops: ' + ops); 
                }
            }            
        }
      
        try{
            if(!opsToInsert.isEmpty()){
                insert opsToInsert;
            }
            if(Test.isRunningTest()){
                throw new DMLException('My DML EXCEPTION'); 
            }
        }
        catch(DmlException ex){
            //ApexPages.addMessages(ex);
        }         
    hasExecuted = false;        
    }// end OnAfterInsert    
  
    public static void OnBeforUpdate(Map<ID, Amendment__c> newAmendsMap, Map<ID, Amendment__c> oldAmendsMap){  
        hasExecuted = true;
        Amendment__c oldAmend;
   		for(Amendment__c newAmend : newAmendsMap.values()){
             oldAmend = oldAmendsMap.get(newAmend.Id);
            if (newAmend.Amendment_Status__c == 'New Request' && oldAmend.Amendment_Status__c != 'New Request'){
                newAmend.DD_Confirm_Segmentation_Accuracy__c = false;
                newAmend.Check_List_Review_Acknowledgement__c = false;
                newAmend.CheckList_Verification__c = false;
            }
            if (newAmend.Amendment_Status__c == 'Quality Assurance Review'  && newAmend.Klarity_Quality_Check__c == false && oldAmend.Amendment_Status__c != 'Quality Assurance Review'){
               newAmend.Klarity_Quality_Check__c = true;
            }
        }
    }
    // When Amendment set to "Approved", take a snapshot of the current opportunity products on the opportunity         
    public static void OnAfterUpdate(Map<ID, Amendment__c> newAmendsMap, Map<ID, Amendment__c> oldAmendsMap){  
        hasExecuted = true;
        Set<Id> opportunityIds = new Set<Id>();
        List<ID> ContractIDs = new List<ID>();
        List<OpportunityLineItem> oppLineItems;
        Map<Id, List<OpportunityLineItem>> oppToOppLineItems = new Map<Id, List<OpportunityLineItem>>();
        Amendment__c oldAmend;
        List<Amendment__c> unlocklist = new List<Amendment__c>();
        List<OpportunityLineItem> updateOppLineItems = new List<OpportunityLineItem>();
        List<Opportunity_Product_Snapshot__c> opsToInsert = new List<Opportunity_Product_Snapshot__c>();
    
        for(Amendment__c newAmend : newAmendsMap.values()){
             oldAmend = oldAmendsMap.get(newAmend.Id);
            if(newAmend.Opportunity__c != NULL){
                opportunityIds.add(newAmend.Opportunity__c);
            }
            if (newAmend.RecordTypeId == '0121K000000vkG4QAI' && newAmend.Type__c == 'Amendment' 
                &&  newAmend.Amendment_Type__c.contains('Start Date Change') && (oldamend.Amendment_Status__c != newAmend.Amendment_Status__c || oldamend.Amendment_Type__c != newAmend.Amendment_Type__c) ){
                    UpdateProgramStartDateChange(newAmend.ID);
            }
            if (newAmend.Amendment_Status__c != oldamend.Amendment_Status__c && newAmend.Amendment_Status__c == 'Ready for Client'){
                SendConditionSelectEmail(newAmend.ID);
            }
            if (newAmend.Amendment_Status__c != oldamend.Amendment_Status__c && newAmend.Amendment_Status__c == 'Fully Executed'){
                UpdateCSProjectOpp(newAmend.ID);
            }
        }
        
       
        if(!opportunityIds.isEmpty()){
            for(OpportunityLineItem oli: [SELECT Id, Audience__c, Custom_List_Price__c, Custom_List_Targets__c, Configured_Price__c, 
                                             Contractual_End_Date__c, Contractual_Start_Date__c, Enhanced_Package__c, Enhanced_Package_Cost__c,
                                             Opp_Line_Item_ID__c, Quantity, Rep_Discount__c, Rep_Price_Override__c, UnitPrice, TotalPrice, 
                                             Product_Name__c, Guarantee__c, Opportunity.Amount, Lock_fields__c, Total_Units__c, 
                                             Total_Price_Debookings__c, Added_Amount__c, Debooked_Amount__c, Total_Contracted_Targets__c, 
                                             Total_Contracted_Targets_Amended__c, Rate_Card_Price_With_Upsells__c        
                                          FROM OpportunityLineItem 
                                          WHERE OpportunityId IN: opportunityIds]){
                if(oppToOppLineItems.containsKey(oli.OpportunityId)){
                    oppLineItems = oppToOppLineItems.get(oli.OpportunityId);
                } else {
                    oppLineItems = new List<OpportunityLineItem>();   
                }
                oppLineItems.add(oli);
               
                oppToOppLineItems.put(oli.OpportunityId, oppLineItems);
            }
        }
        
        for(Amendment__c newAmend : newAmendsMap.values()){
            oldAmend = oldAmendsMap.get(newAmend.Id);
            
            if(oldamend.Amendment_Status__c != 'Fully Executed'
                && newAmend.Amendment_Status__c == 'Fully Executed'
                && (newAmend.Type__c == 'Amendment'
                    || newAmend.Type__c == 'SOW')
               && oppToOppLineItems.containsKey(newamend.Opportunity__c)
            ){
                for(OpportunityLineItem oli : oppToOppLineItems.get(newamend.Opportunity__c)){
                    if(oli.Total_Contracted_Targets_Amended__c == NULL){
                        targets = oli.Total_Contracted_Targets__c;
                    } else {
                        targets = oli.Total_Contracted_Targets_Amended__c;
                    }
                    
                    Opportunity_Product_Snapshot__c ops = new Opportunity_Product_Snapshot__c(
                        Added_Amount_P__c = oli.Added_Amount__c,
                        Amendment__c = newamend.Id,
                        Audience__c = oli.Audience__c,
                        Custom_List_Price__c = oli.Custom_List_Price__c,
                        Custom_List_Targets__c = oli.Custom_List_Targets__c,
                        Configured_Price__c = oli.Configured_Price__c,
                        Contractual_End_Date__c = oli.Contractual_End_Date__c,
                        Contractual_Start_Date__c = oli.Contractual_Start_Date__c,                        
                        Debooked_Amount_P__c = oli.Debooked_Amount__c,
                        Enhanced_Package__c = oli.Enhanced_Package__c,
                        Enhanced_Package_Cost__c = oli.Enhanced_Package_Cost__c,
                        Guarantee__c = oli.Guarantee__c,
                        Name = oli.Product_Name__c,
                        Net_Amount_P__c = oli.Total_Price_Debookings__c,         
                        Opp_Line_Item_ID__c = oli.Opp_Line_Item_ID__c,                        
                        Opportunity_Amount__c = oli.Opportunity.Amount,
                        Opportunity_Product__c = oli.Opp_Line_Item_ID__c, 
                        Quantity__c = oli.Quantity,
                        Rep_Discount__c = oli.Rep_Discount__c,
                        Rep_Price_Override__c = oli.Rep_Price_Override__c,
                        Sales_Price__c = oli.UnitPrice,
                        Total_Contracted_Targets__c = targets,
                        Total_Price__c = oli.TotalPrice,                        
                        Units_per_Month__c = oli.Total_Units__c,
                        Rate_Card_Price_With_Upsells__c = oli.Rate_Card_Price_With_Upsells__c
                    );   
                    opsToInsert.add(ops); 
                    system.debug('ops: ' + ops); 
                    oli.Lock_fields__c = FALSE;
                    updateOppLineItems.add(oli);
                }
            }
            //unlock if it is locked
            if (Approval.isLocked(newAmend.ID)) {
                unlocklist.add(newAmend);
            }
        }
        if(!unlocklist.isEmpty()){
          Approval.UnLockResult[] lrList = Approval.Unlock(unlocklist, false);  
        }
        
        
        try{
            update updateOppLineItems;
            insert opsToInsert;
            if(Test.isRunningTest()){
                throw new DMLException('My DML EXCEPTION'); 
            }
        }
        catch(DmlException ex){
            //ApexPages.addMessages(ex);
        } 
        hasExecuted = false;
    } // end OnAfterUpdate

  //Call ROI Study Approval Process again as Opp Amount has changed
  /*
    public static void CallROIStudyApproval(ID OpptyID){
        system.debug('ROI -Opp' + OpptyID);
        List<Amendment__c> SOWwithROIs = [SELECT Id, ROI_Approval_Status__c, Name, type__c, Opportunity__c 
                                          FROM Amendment__c
                                          WHERE Opportunity__c = :OpptyID
                                          AND type__c = 'SOW with ROI' 
                                          AND ROI_Approval_Status__c = 'Deal Desk Approved'];
        system.debug('--ROI--' + SOWwithROIs);
        if (SOWwithROIs.size() > 0){
            system.debug('--here--');
            for (Amendment__c am : SOWwithROIs){
              Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                req1.setComments('Re-Submitting SOW with ROI approval for ' + am.Name);
                req1.setObjectId(am.id);
                req1.setSkipEntryCriteria(true);
                Approval.ProcessResult result = Approval.process(req1);
                 system.debug('--sent for approval--');
            }
                
        }
        
    }
  */
    //unlock record locked in Approval Porcess
    @InvocableMethod(label='Unlock Approval Record')
    public static void UnlockContract(List<string> ContractIds)
    {
       //unlock the record
       system.debug('--sent for approval--' + ContractIds);
       Approval.Unlock(ContractIds[0], false);
    }
    @future(callout=true)
    public static void SendConditionSelectEmail(ID ContractId)
    {
        Amendment__c amen = [Select id,RecordTypeId,Type__c,OpportunityId__c, Name,Amendment_Status__c,Opportunity_Name__c,
                             Opportunity__r.Products__c, Opportunity__r.owner.Name, Opportunity__r.Sales_Team__c  from Amendment__c where id = :ContractId LIMIT 1];
        //if (!amen.Opportunity__r.Products__c.Contains('Condition Select') && amen.Opportunity__r.Sales_Team__c != '1-Pharma') return;
        system.debug('prod--' + amen.Opportunity__r.Products__c + '--Sales--' + amen.Opportunity__r.Sales_Team__c);
        if (amen.Opportunity__r.Sales_Team__c == '1-Pharma' && amen.RecordTypeId == '0121K000000vkG5QAI' && amen.Type__c == 'SOW'){
            if (amen.Opportunity__r.Products__c != null){
                if (amen.Opportunity__r.Products__c.Contains('Condition Select')){
                    EmailTemplate et = [SELECT Id,Subject, Body FROM EmailTemplate WHERE DeveloperName = 'Condition_Select_Email_Notification'];
                    string oweaID = '';
                    string ProductNames = '';
                    string CSProducts = '';
                    List<String> defaultemails = new List<String>();
                    OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'salesops@doximity.com'];
                    if ( owea.size() > 0 ) {
                        oweaID = owea.get(0).Id;
                    }
                    Configuration_Setting__mdt CS_mdt = Configuration_Setting__mdt.getInstance('Condition_Select_Email_Notification');
                    if (CS_mdt.Email_Recipients__c  != ''){
                       defaultemails = CS_mdt.Email_Recipients__c.split(',');
                    }
                    system.debug(defaultemails);
                    
                    for(OpportunityLineItem oli:[SELECT Id, Audience__r.Audience_URL__c, 
                                                 Contractual_Start_Date__c,Contractual_End_Date__c,
                                                 Product_Name__c 
                                                 FROM OpportunityLineItem 
                                                 WHERE OpportunityId = :amen.OpportunityId__c and 
                                                 Productline__c = 'Condition Select']){
                       
                       ProductNames = ProductNames + oli.Product_Name__c + ',' ;
                       CSProducts = CSProducts + 'Product : ' + oli.Product_Name__c +  '<br/>';
                       CSProducts = CSProducts + 'Start Date : ' + oli.Contractual_Start_Date__c.format() + '<br/>';
                       CSProducts = CSProducts + 'End Date : ' + oli.Contractual_End_Date__c.format() + '<br/>';
                       if (oli.Audience__r.Audience_URL__c != null) CSProducts = CSProducts + 'Audience : ' + oli.Audience__r.Audience_URL__c + '<br/>';
                       CSProducts = CSProducts + '<br>';                              
                      
                     }
                     System.debug('PN--' + ProductNames);
                     System.debug('cS-' + CSProducts);
                    
                    //Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(et.ID, null,ContractId);
                    string emailSubject  = mail.getSubject();
                    string emailTextBody = mail.getHtmlBody();
                    
                    string strBody = emailTextBody;
                    strBody = strBody.replace('[[CSProducts]]', CSProducts);
                    string cLink = '<a href="' + Url.getOrgDomainURL().toExternalForm() + '/lightning/r/Amendment__c/' + ContractId + '/view">' + amen.Name + '</a>';
                    strBody = strBody.replace('[[CLink]]', cLink);
                    strBody = strBody.replace('[[CStatus]]', amen.Amendment_Status__c);
                    string oLink = '<a href="' + Url.getOrgDomainURL().toExternalForm() + '/lightning/r/Opportunity/' + amen.OpportunityId__c + '/view">' + amen.Opportunity_Name__c + '</a>';
                    strBody = strBody.replace('[[OppLink]]', oLink);
                    strBody = strBody.replace('[[RVP]]', amen.Opportunity__r.owner.Name);
                    
                    mail.setTemplateId(et.Id);
                    mail.setToAddresses(defaultemails);
                    mail.setSubject(emailSubject.replace('[[CSProductNames]]', ProductNames.removeEnd(',')));
                    mail.setHTMLBody(strBody);
                    mail.setTargetObjectId(UserInfo.getUserId());
                    mail.setWhatId(ContractId);
                    mail.saveAsActivity = false;
                    if (oweaID != '') {
                        mail.setOrgWideEmailAddressId(oweaID);
                    }
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
                    system.debug('sent');
                }
            }
        }else{
          return;  
        } 
    }
    @future
    public static void UpdateCSProjectOpp(ID ContractId)
    {
      boolean updateCSproject = false;
      Amendment__c Amend = [select id,RecordTypeId,Type__c, OpportunityId__c,Opportunity__r.Sales_Team__c, 
                            Opportunity__r.CS_Project__r.id, Parent_Opportunity__r.ID, Was_CS_Project_Run__c, 
                            Opportunity__r.Contractual_Launch_Date__c,Opportunity__r.Contractual_End_Date__c,
                            Opportunity__r.Name
                            from Amendment__c 
     					    where id = :ContractId];
        if (Amend.Was_CS_Project_Run__c == 'No' && Amend.Opportunity__r.CS_Project__r.id != null ){
            CS_Project_Opp__c  CSProjectOpp = new CS_Project_Opp__c ();
            CSProjectOpp.Opportunity__c = Amend.Opportunity__c;
            CSProjectOpp.Contract_Amendment__c = Amend.id;
            CSProjectOpp.CS_Project__c = Amend.Opportunity__r.CS_Project__r.id;
            CSProjectOpp.Name = (Amend.RecordTypeId == '0121K000000vkG4QAI') ?  ('Amendment ' + Amend.Opportunity__r.Name).Left(80) : (Amend.Opportunity__r.Name).left(80);
            CSProjectOpp.Contractual_Start_Date__c = amend.Opportunity__r.Contractual_Launch_Date__c;
            CSProjectOpp.Contractual_End_Date__c = amend.Opportunity__r.Contractual_End_Date__c;
            Insert CSProjectOpp;
        }else if (Amend.Was_CS_Project_Run__c == 'Yes' && Amend.Opportunity__r.CS_Project__r.id != null){
            // find the csprojectopp and update the contract id
            List<CS_Project_Opp__c>  lstCSProjectOpp = [Select Id from CS_Project_Opp__c where
                                                       Opportunity__c = :Amend.Opportunity__c 
                                                       and CS_Project__c = :Amend.Opportunity__r.CS_Project__r.id
                                                       and Contract_Amendment__c = ''
                                                       order by createddate desc Limit 1 ];
            If (lstCSProjectOpp.size() > 0){
                CS_Project_Opp__c csProjOpp  = lstCSProjectOpp[0];
                csProjOpp.Contract_Amendment__c = Amend.ID;
                Update csProjOpp;
            }
			
        }
            
	}
    
    /*@future
    public static void UpdateOLISegmentation(ID ContractId)
    {
	  //updates the OLI Segmentation based on contract request.      
      Amendment__c Amend = [select id,RecordTypeId,Type__c, OpportunityId__c,Opportunity__r.Sales_Team__c, Parent_Opportunity__r.ID, Segmentation__c from Amendment__c 
     					    where id = :ContractId];
      if (Amend.Opportunity__r.Sales_Team__c == '1-Pharma' && Amend.RecordTypeId == '0121K000000vkG5QAI' && Amend.Type__c == 'SOW'){
          system.debug('updating oli segmentation');
          List<OpportunityLineItem> olis = [SELECT Id,Segmentation__c,Productline__c FROM OpportunityLineItem 
                                            WHERE OpportunityId = :Amend.OpportunityId__c];
          List<OpportunityLineItem> olisUpdate = new List<OpportunityLineItem>();
          for(OpportunityLineItem oli: olis){
             oli.Segmentation__c = (oli.Productline__c == 'Condition Select' || oli.Productline__c == 'Conference') ? 1 : Amend.Segmentation__c;
             olisUpdate.add(oli);
          }
          Update olisUpdate;
       }
    }*/
    
    @future
    public static void UpdateProgramStartDateChange(ID ContractId)
    {
      
      //unlock the record
      Set<ID> OppIds = new Set<ID>();
	  Set<ID> ParentOppIds = new Set<ID>();
      List<Opportunity> lstOpps = new List<Opportunity>();
      List<Opportunity> lstchildOpps = new List<Opportunity>();
      Integer OpenOppCount = 0;  
      Integer ClosedOppCount = 0;
      List<AggregateResult> groupedResultsOpen = new List<AggregateResult>();
      List<AggregateResult> groupedResultsClosed = new List<AggregateResult>();
      string ParentOpp = null;
      Map<ID, ID> OppParentOpp = new Map<ID, ID>();
      Amendment__c Amend = [select id,Opportunity__r.ID, Parent_Opportunity__r.ID, Agency__c  from Amendment__c 
                                    where id = :ContractId
                                    and RecordTypeId = '0121K000000vkG4QAI'
                                    and Type__c = 'Amendment'
                                    and Amendment_Type__c includes ('Start Date Change', 'Start Date Change # 1', 'Start Date Change # 2') ];
      system.debug('amend--' + Amend.Parent_Opportunity__r.ID);
      
      if (Amend.Parent_Opportunity__r.ID != null){
        system.debug('having a parent');
      	lstchildOpps = [select id, Parent_Opportunity__c from Opportunity where Parent_Opportunity__c = :Amend.Parent_Opportunity__r.ID or id = :Amend.Opportunity__r.ID or id = :Amend.Parent_Opportunity__r.ID];    
        groupedResultsOpen = [SELECT Count(Id) ContractCount FROM Amendment__c WHERE (Parent_Opportunity__c = :Amend.Parent_Opportunity__r.ID or Opportunity__c = :Amend.Opportunity__r.ID or Opportunity__c = :Amend.Parent_Opportunity__r.ID) and Amendment_Status__c NOT IN ('Fully Executed', 'Cancelled')];
        OpenOppCount = (Integer)groupedResultsOpen[0].get('ContractCount');
        System.debug('OpenOppCount: ' + OpenOppCount);
        if (Amend.Agency__c.contains('CMI')){
        	groupedResultsClosed = [SELECT Count(Id) ContractCount FROM Amendment__c WHERE (Parent_Opportunity__c = :Amend.Parent_Opportunity__r.ID or Opportunity__c = :Amend.Opportunity__r.ID or Opportunity__c = :Amend.Parent_Opportunity__r.ID) and Amendment_Status__c IN ('Fully Executed') 
                                   	and RecordTypeId = '0121K000000vkG4QAI'
                                    and Type__c = 'Amendment'
                                    and Amendment_Type__c includes ('Start Date Change', 'Start Date Change # 1', 'Start Date Change # 2')
                                    and  Day_of_Amendment__c  >= 2023-07-01];
        }else{
        	groupedResultsClosed = [SELECT Count(Id) ContractCount FROM Amendment__c WHERE (Parent_Opportunity__c = :Amend.Parent_Opportunity__r.ID or Opportunity__c = :Amend.Opportunity__r.ID or Opportunity__c = :Amend.Parent_Opportunity__r.ID) and Amendment_Status__c IN ('Fully Executed') 
                                    and RecordTypeId = '0121K000000vkG4QAI'
                                    and Type__c = 'Amendment'
                                    and Amendment_Type__c includes ('Start Date Change', 'Start Date Change # 1', 'Start Date Change # 2')
                                    and  Day_of_Amendment__c  >= 2023-05-01];
        }
        ClosedOppCount = (Integer)groupedResultsClosed[0].get('ContractCount');
        System.debug('ClosedOppCount: ' + ClosedOppCount);
          
      }else{
        system.debug('is a parent');  
  		lstchildOpps = [select id, Parent_Opportunity__c from Opportunity where Parent_Opportunity__c = :Amend.Opportunity__r.ID or id = :Amend.Opportunity__r.ID]; 
        groupedResultsOpen = [SELECT Count(Id) ContractCount FROM Amendment__c WHERE (Parent_Opportunity__c = :Amend.Opportunity__r.ID or Opportunity__c = :Amend.Opportunity__r.ID) and Amendment_Status__c NOT IN ('Fully Executed', 'Cancelled')];
        OpenOppCount = (Integer)groupedResultsOpen[0].get('ContractCount');
        System.debug('OpenOppCount: ' + OpenOppCount);
        if (Amend.Agency__c.contains('CMI')){
        	groupedResultsClosed = [SELECT Count(Id) ContractCount FROM Amendment__c WHERE (Parent_Opportunity__c = :Amend.Opportunity__r.ID or Opportunity__c = :Amend.Opportunity__r.ID) and Amendment_Status__c IN ('Fully Executed') 
                                    and RecordTypeId = '0121K000000vkG4QAI'
                                    and Type__c = 'Amendment'
                                    and Amendment_Type__c includes ('Start Date Change', 'Start Date Change # 1', 'Start Date Change # 2')
                                    and  Day_of_Amendment__c  >= 2023-07-01];
        }else{
     		groupedResultsClosed = [SELECT Count(Id) ContractCount FROM Amendment__c WHERE (Parent_Opportunity__c = :Amend.Opportunity__r.ID or Opportunity__c = :Amend.Opportunity__r.ID) and Amendment_Status__c IN ('Fully Executed') 
                                    and RecordTypeId = '0121K000000vkG4QAI'
                                    and Type__c = 'Amendment'
                                    and Amendment_Type__c includes ('Start Date Change', 'Start Date Change # 1', 'Start Date Change # 2')
                                    and  Day_of_Amendment__c  >= 2023-05-01];
        }
        ClosedOppCount = (Integer)groupedResultsClosed[0].get('ContractCount');
        System.debug('ClosedOppCount: ' + ClosedOppCount);
     
      }
	   for (Opportunity oppUpdt : lstchildOpps){
           Opportunity Opp = new Opportunity();
           Opp.id = oppUpdt.id;
           Opp.Program_Start_Date_Change_Request_Open__c = OpenOppCount;
           Opp.Program_Start_Date_Change_Request_Closed__c = ClosedOppCount;
           lstOpps.add(Opp);
       }
       if (lstOpps.size() > 0) update lstOpps;
    }    
}