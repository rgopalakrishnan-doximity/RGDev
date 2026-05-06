public class SetChangeOrderValues {
    
    
    public class ChangeOrderInput {
        @InvocableVariable(label='Contract ID' description='Contract')
        public String ContractID;
        
        @InvocableVariable(label='CO Rationale' description='Contract')
        public String CORationale;
        
    }
    
    @InvocableMethod(label='Map CO Values')
    public static void MapInitialCOValues(List<ChangeOrderInput> ChangeOrderInputs)
    {
        ChangeOrderInput COInput = ChangeOrderInputs[0];
        decimal rollingamt = 0;
        
        Amendment__c amend = [SELECT id, Opportunity__r.ID, Opportunity__r.Amount, Parent_Opportunity__r.id, 
                              Parent_Opportunity__r.Products__c,Advertiser_Name__r.Name,Name,
                              Opportunity__r.Products__c, Parent_Opportunity__r.Lead_Number__c, Parent_Opportunity__r.Type, Opportunity__r.Type
                              FROM Amendment__c WHERE Id =:COInput.ContractID Limit 1];
      	
        List<AggregateResult> results = new List<AggregateResult>();
        
        if (amend.Parent_Opportunity__c != null){
        	 results = [select SUM(Amount) total from Opportunity 
                                         where 
                       					(id = :amend.Parent_Opportunity__c or  id  = :amend.Opportunity__c) 
                        				 or
                                         (Parent_Opportunity__c = :amend.Parent_Opportunity__c 
                                          and StageName = '100% - Closed Won' )];
        }else{
             results = [select SUM(Amount) total from Opportunity 
                                         where 
                       					(Parent_Opportunity__c = :amend.Opportunity__c 
                                         and 
                                         StageName = '100% - Closed Won')
                                         or id  = :amend.Opportunity__c];
    	}

		if(!results.isEmpty()){
          rollingamt = (decimal)results[0].get('total');
          amend.Rolling_Amount__c = rollingamt;
        }
        
        list<Amendment__c> firstSOW = new List<Amendment__c>();
        list<Amendment__c> previousCO = new List<Amendment__c>();
        list<Amendment__c> previousCONumber = new list<Amendment__c>();
        
        if (amend.Parent_Opportunity__r.id != null){
            firstSOW = [SELECT id, Project_Title__c, Non_Standard_Language_Included__c from Amendment__c where 
                        RecordTypeId  = '0121K000000vkG5QAI'
                        and Type__c = 'SOW'
                        and Amendment_Status__c  = 'Fully Executed' and 
                        Opportunity__r.ID = :amend.Parent_Opportunity__r.id order by createddate desc];
        }else{
            firstSOW = [SELECT id, Project_Title__c, Non_Standard_Language_Included__c from Amendment__c where 
                        RecordTypeId  = '0121K000000vkG5QAI'
                        and Type__c = 'SOW'
                        and Amendment_Status__c  = 'Fully Executed' and 
                        Opportunity__r.ID = :amend.Opportunity__r.id order by createddate desc];
        }
        if (amend.Parent_Opportunity__r.id != null){
             previousCO = [SELECT id, Change_Order_Number__c, Project_Title__c,Non_Standard_Language_Included__c from Amendment__c where 
                        RecordTypeId  = '0121K000000vkG4QAI'
                        and Amendment_Status__c  = 'Fully Executed' and 
                       ( Opportunity__r.ID = :amend.Parent_Opportunity__r.id or 
                        Parent_Opportunity__c = :amend.Parent_Opportunity__r.id)
                           order by createddate, Change_Order_Number__c desc];
            
            previousCONumber = [SELECT id, Change_Order_Number__c, Project_Title__c,Non_Standard_Language_Included__c from Amendment__c where 
                        RecordTypeId  = '0121K000000vkG4QAI'
                        and Amendment_Status__c  = 'Fully Executed' and 
                        SFDC_Documentation_Only__c != true and 
                       ( Opportunity__r.ID = :amend.Parent_Opportunity__r.id or 
                        Parent_Opportunity__c = :amend.Parent_Opportunity__r.id)
                           order by createddate, Change_Order_Number__c desc ];
     
        }else{
             previousCO = [SELECT id, Change_Order_Number__c, Project_Title__c, Non_Standard_Language_Included__c from Amendment__c where 
                        RecordTypeId  = '0121K000000vkG4QAI'
                        and Amendment_Status__c  = 'Fully Executed' and 
                        (Opportunity__r.ID = :amend.Opportunity__r.id or
                        Parent_Opportunity__c = :amend.Opportunity__r.id )
                        order by createddate desc, Change_Order_Number__c desc];
            
            previousCONumber = [SELECT id, Change_Order_Number__c, Project_Title__c, Non_Standard_Language_Included__c from Amendment__c where 
                        RecordTypeId  = '0121K000000vkG4QAI'
                        and Amendment_Status__c  = 'Fully Executed' and 
                        SFDC_Documentation_Only__c != true and 
                        (Opportunity__r.ID = :amend.Opportunity__r.id or
                        Parent_Opportunity__c = :amend.Opportunity__r.id )
                        order by createddate desc, Change_Order_Number__c desc];
     
        }
       
        system.debug('Change ORder count-- + '+ previousCO.size() );
        system.debug('Change ORders-- + '+ previousCO );
        string nonstandard = '';
        integer CONumber = 0;
        if (firstSOW.size() > 0) amend.First_SOW__c = firstSOW[0].id;
        
        if (previousCO.size() > 0){
            amend.Previous_Amendment__c = previousCO[0].id;
            nonstandard = previousCO[0].Non_Standard_Language_Included__c;
        }else{
        	nonstandard = firstSOW[0].Non_Standard_Language_Included__c;
        }
        if (previousCONumber.size() > 0){
         	CONumber = (previousCONumber[0].Change_Order_Number__c != null) ? Integer.valueof(previousCONumber[0].Change_Order_Number__c) + 1 : previousCONumber.size() + 1 ;
        }else{
          	CONumber = 1;  
        }    
          
        amend.Change_Order_Number__c = CONumber;
        amend.Name = amend.Name + ' CO #' + string.valueof(CONumber); //handle this after amendment updates
        amend.Non_Standard_Language_Included__c = nonstandard;   
        
        List<Amended_Products__c> APs = new List<Amended_Products__c>();
        string NewScope = '';
        boolean renametitle = false;
        string projecttitle = '';
        string KeyDetails = '';
       	string InvoiceDetails = (amend.Parent_Opportunity__r.id != null) ? '<span style="color:red">Yes</span>' : '<span style="color:green">No</span>';
        
        string InvoiceAmount = '';
        if (amend.Parent_Opportunity__r.id != null && amend.Opportunity__r.Type  == 'Upsell'){
           InvoiceAmount =  InvoiceAmount + '<span style="color:Blue">' +  amend.Opportunity__r.Amount  + ' </span>';
        }else if (amend.Parent_Opportunity__r.id != null && amend.Opportunity__r.Type  == 'Debooking'){
           InvoiceAmount =  InvoiceAmount + '<span style="color:red">' +  amend.Opportunity__r.Amount + ' </span>';         
        }else{
           InvoiceAmount = InvoiceAmount + '<span style="color:grey"> No Change </span>';  
        }
        
        APs = [SELECT id,Version__c,status__c,Original_Quantity__c,
                                        Opportunity_Product_ID__c,Opportunity_Product__c,
                                        Opportunity__c,Contract_Amendment__c,Amendment_Type__c,
                                        Original_Agency__c,Amended_Agency__c,Amended_Agency_3rd_Party_Transfer_Date__c,
               							Amended_Agency__r.Name,Amendment_Detail__c,
                                        Amended_Contractual_Start_Date__c, Amended_Contractual_End_Date__c,
                                        Amended_Max_Targets_Per_Month__c,Automated_Fulfilment__c,
               							Parent_Product__r.Productline__c , Parent_Product__r.Custom_List_Targets__c,
               							Opportunity_Product__r.Productline__c,Opportunity_Product__r.Custom_List_Targets__c,
               							Opportunity_Product__r.Contractual_Start_Date__c, Original_Contractual_Start_Date__c,Original_Contractual_End_Date__c,
               							Opportunity_Product__r.Contractual_End_Date__c,Opportunity_Product__r.Quantity,
               							New_Target_List_URL__c,Target_Upsell_Only__c,Contractual_Start_Date_Formula__c,
               							Original_Segmentation__c,Amended_Segmentation__c,
               							Invoice_Change_Type__c,Amended_Invoice_Date__c,Original_Invoice_Date__c,
               							Amended_Invoice_Amount__c,Original_Invoice_Amount__c
                                        FROM Amended_Products__c
                                        where Contract_Amendment__c = :COInput.ContractID
               							and status__c = 'Requested'  order by Amendment_Type__c, Version__c desc];
        
        string oldSDate = '';
        string newSDate = '';
        string oldEDate = '';
        string newEDate = '';
        boolean addInvChangeScope = false;
        boolean createEngagementTask = false;
        for(Amended_Products__c AP : APs){
            if (AP.Amendment_Type__c == 'Target Change'){
                createEngagementTask = true;
                NewScope = NewScope + '\n' + '<u><b>Target Change:</u></b> <b>' + AP.Parent_Product__r.Productline__c  + '</b><br/>';
                    
                //target upsell then
                if (AP.Target_Upsell_Only__c){
                    NewScope = NewScope +  'Original Target: <b>' + AP.Parent_Product__r.Custom_List_Targets__c + '</b></b> ';
            	    NewScope = NewScope + ',  New Target: <b>' + AP.Opportunity_Product__r.Custom_List_Targets__c + '</b> ';
               		NewScope = NewScope + ',  Modified Target:  <span style="color:green">' + string.valueof(AP.Opportunity_Product__r.Custom_List_Targets__c + AP.Parent_Product__r.Custom_List_Targets__c) + '</span><br/><br/>';
                }else{
                    NewScope = NewScope + 'Original Target: <b>' + AP.Opportunity_Product__r.Custom_List_Targets__c + '</b> ';
                    NewScope = NewScope + ', New Target List: '  + AP.New_Target_List_URL__c  +  '<br/>' ;
           
                    if (AP.Amended_Max_Targets_Per_Month__c != null){
                			NewScope = NewScope + ',  New Target: <b>' + AP.Amended_Max_Targets_Per_Month__c + '</b> ';
               				NewScope = NewScope + ',  Modified Target:  <span style="color:green">' + string.valueof(AP.Opportunity_Product__r.Custom_List_Targets__c + AP.Amended_Max_Targets_Per_Month__c ) + '</span><br/><br/>';
                    }
               	}
            }
			if (AP.Amendment_Type__c == 'Extension'){
                NewScope = NewScope +  'Extension:' ;
                NewScope = NewScope +  '( adding <span style="color:green">' + AP.Opportunity_Product__r.Productline__c  + '</span> )' + '<br/><br/>';
                renametitle = true;
                addInvChangeScope = true;
            }
            if (AP.Amendment_Type__c == 'Start Date Change'){
                
                NewScope = NewScope +  '<b><u>Start Date Change:</u></b> <b>'  + AP.Opportunity_Product__r.Productline__c  + '</b><br/>';
                NewScope = NewScope +  'Start Date: <b>'  + AP.Original_Contractual_Start_Date__c.format()  + '</b> to <b>' + AP.Amended_Contractual_Start_Date__c.format() + '</b><br/>' ;
                NewScope = NewScope +  'End Date: <b>'  + (AP.Original_Contractual_Start_Date__c.addMonths(Integer.valueof(AP.Opportunity_Product__r.Quantity)) - 1).format()   + '</b> to <b>' + (AP.Amended_Contractual_Start_Date__c.addMonths(Integer.valueof(AP.Opportunity_Product__r.Quantity)) - 1).format() + '</b><br/><br/>' ;
            }
            if (AP.Amendment_Type__c == 'End Date Change ONLY'){
                NewScope = NewScope +  '<b><u>End Date Change ONLY:</u></b> <b>'  + AP.Opportunity_Product__r.Productline__c  + '</b><br/>';
                NewScope = NewScope +  'End Date: <b>'  + AP.Original_Contractual_End_Date__c.format()  + '</b> to <b>' + AP.Amended_Contractual_End_Date__c.format() + '</b><br/>' ;
                NewScope = NewScope +  'Start Date: <b>'  + AP.Contractual_Start_Date_Formula__c.format()   + '</b><br/><br/>' ;
            }
            if (AP.Amendment_Type__c == 'Change to Invoice Schedule'){
                addInvChangeScope = true;
                /*if (AP.Amended_Invoice_Date__c != null){
                    if (AP.Invoice_Change_Type__c == 'Update'){
                        NewScope = NewScope +   AP.Invoice_Change_Type__c + ':<b> From ' + AP.Original_Invoice_Date__c.format() + '</b> To <b>' +  AP.Amended_Invoice_Date__c.format() + '</b><br/>';
                        if (AP.Original_Invoice_Amount__c != null){
                          NewScope = NewScope +   AP.Invoice_Change_Type__c + ':<b> From ' + AP.Original_Invoice_Amount__c + '</b> To <b>' + AP.Amended_Invoice_Amount__c + '</b><br/>';
                        }
                    }
                }else if (AP.Original_Invoice_Amount__c != null){
                    if (AP.Invoice_Change_Type__c == 'Update'){
                        NewScope = NewScope +   AP.Invoice_Change_Type__c + ':<b> From ' + AP.Original_Invoice_Amount__c + '</b> To <b>' + AP.Amended_Invoice_Amount__c + '</b><br/>';
                        if (AP.Amended_Invoice_Date__c != null){
                           NewScope = NewScope +   AP.Invoice_Change_Type__c + ':<b> From ' + AP.Original_Invoice_Date__c.format() + '</b> To <b>' + AP.Amended_Invoice_Date__c.format() + '</b><br/>';
                        }
                    }
                }*/
            }
            
            if (AP.Amendment_Type__c == 'Segmentation Change'){
                NewScope = NewScope +  '<b><u>Segmentation Change:</u></b> <b>'  + AP.Opportunity_Product__r.Productline__c  + '</b><br/>';
                NewScope = NewScope +  'From: <b>'  + string.valueof(Integer.valueof(AP.Original_Segmentation__c))  + '</b> To: <b>' + string.valueof(Integer.valueof(AP.Amended_Segmentation__c))  + '</b><br/><br/>' ;
                
            }
            if (AP.Amendment_Type__c == 'Agency Switch'){
                NewScope = NewScope +  '<b><u>Agency Switch:</u></b> <a href="/' + AP.Amended_Agency__c + '">'  + AP.Amended_Agency__r.Name + '</a><br/><br/>';
            }
            if (AP.Amendment_Type__c == 'Add/Modify Non-Finance Related Language'){
               
                NewScope = NewScope +  '<b><u>Add/Modify Non-Finance Related Language:</u></b> '  + AP.Amendment_Detail__c.replace('\n', '<br>') + '<br/><br/>';
            }
        }
        if (addInvChangeScope){
         NewScope = NewScope +  '<b><u>Changes to Invoice Schedule: </b></u> Details listed in the Invoice changes table under the Original Invoices section. <br/><br/>';
        }      
      	system.debug(NewScope);
  		amend.New_Scope__c = NewScope;
        amend.Change_Order_Rational__c = COInput.CORationale;
        List<OpportunityLineItem> OLIs = [SELECT id,Product_Name__c, Name, Contractual_Start_Date__c, Social_Proof_Enhancement__c  
                                          FROM OpportunityLineItem 
                                          where OpportunityId  = :amend.Opportunity__r.ID order by Contractual_Start_Date__c asc NULLS LAST];
        date prgDate = (OLIs[0].Contractual_Start_Date__c != null) ? OLIs[0].Contractual_Start_Date__c : date.today();
        
        if (!renametitle){
            if (previousCO.size() > 0){
                projecttitle = previousCO[0].Project_Title__c;
            }
            //if this is empty then create pull from SOW
            
            projecttitle = (projecttitle == '' || projecttitle == null || projecttitle.contains('(adding product')) ? firstSOW[0].Project_Title__c : projecttitle;
            system.debug(firstSOW[0].Project_Title__c);
            //if firstSOW is also not mapped create
            if (projecttitle == '' || projecttitle == null){
               //get the product names like in SOW - TODO
               projecttitle = prgDate.year() + ' Doximity ' 
                  			+  amend.Opportunity__r.Products__c.replace(',', ' + ') 
                  			+  ' Product Subscription for ' 
                  			+ amend.Advertiser_Name__r.Name; 
             
            }
        }else{
            //get the product names like in SOW - TODO
          	projecttitle = '(adding product ' + amend.Opportunity__r.Products__c.replace(',', ' + ')  
              + ' ) '+ prgDate.year() + ' Doximity ' 
              +  amend.Parent_Opportunity__r.Products__c.replace(',', ' + ') 
              +  ' Product Subscription for ' + amend.Advertiser_Name__r.Name ;
          
        }
        amend.Project_Title__c = projecttitle;
      	// add this to summary
        KeyDetails = KeyDetails + '<b><u>Change Type: </u></b><br/>' + NewScope + '<br/>';
        KeyDetails = KeyDetails + '<b><u>Invoice: </u></b>' + InvoiceDetails + '<br/>';
        KeyDetails = KeyDetails + '<b><u>Total $$ increase/decrease: </u></b>' + InvoiceAmount + '<br/>';
        KeyDetails = KeyDetails + '<b><u>Nonstandard language: </u></b>' + nonstandard + '<br/>';
        KeyDetails = KeyDetails + '<b><u>Other:</u></b>' +  '<br/>';
        
        amend.Summary_of_Changes__c = KeyDetails;
        update amend;
        
        if (createEngagementTask){
            Task newTask = new Task();
            // 1. Find the Queue
            Group q = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Target_Engagement_Change_Queue' LIMIT 1];
            
            // 2. Create the Task
            Task t = new Task();
            t.Subject = 'Provide Target Engagement Detail Changes';
            t.Description = 'Please review the Target change orders and provide the necessary information';
            t.OwnerId = q.Id; // Assign the task to the queue
            t.ActivityDate = Date.today().addDays(1);
            t.Status = 'Open';
            t.WhatId = amend.id;
            t.RecordTypeId =  '012O4000008zophIAA';
            t.Contract_Amendment__c = amend.id;
            t.Opportunity__c = amend.Opportunity__r.ID;
            insert t;
        }
    }

}