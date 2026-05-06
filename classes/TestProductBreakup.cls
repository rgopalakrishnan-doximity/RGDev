@isTest
public class TestProductBreakup {
//covers ProductBreakupActions, ProductBreakupTriggerHandler,ProductBreakupTrigger    
     static testmethod void method1() {  
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Custom System Administrator'].Id,
             LastName = 'Last',
             Email = 'test@doximity.com',
             Username = 'test@doximity.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'Title',
             Alias = 'Alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US',
             Team__c = '5-Exec / Finance'
        );     
        insert u;
        List<string> Opplst = new List<string>();
        //Telehealth Renewal
        List<Opportunity> lstopp = TestDataFactory.createTestOpps(1,1);
        Opportunity Opp = lstopp[0];
        Opp.Sales_Team__c = '1-Pharma'; 
        Opp.Type = 'New Business';
        update Opp;
        List<OpportunityLineItem> lstOLIS = [select id, quantity,Audience__c, Audience_Pricing__c, Contractual_Start_Date__c from OpportunityLineItem where OpportunityId =:Opp.id ];
       
        Audience__c aud = new Audience__c ( Opportunity__c = Opp.Id, Attached_to_Product__c = FALSE, Final_Target_Size__c = 3000); 
        insert aud;
        Audience_Pricing__c ap = new Audience_Pricing__c ( Opportunity__c = Opp.Id, 
                                           Pharma_DN_2_0_Audience_CPE__c = 30.50, 
                                           Pharma_DocSpot_Audience_CPE__c = 45.75,
                                           Pharma_DocPoint_UV_Audience_CPE__c = 50.75,
                                           Pharma_AN_Audience_CPE__c = 35.00,
                                           Pharma_FO_Audience_CPE__c = 28.50,
                                           Audience__c = aud.Id, price_book_id__c  = 'Rx Feb 2022');
        insert ap;
                                           
        OpportunityLineItem OLI1 =  new OpportunityLineItem();
        OLI1.id = lstOLIS[0].id;
        OLI1.Audience__c = aud.id;
        OLI1.Audience_Pricing__c = ap.id;
        update OLI1;
         
        List<ProductBreakupActions.ProductConfigInputs> inputs = new List<ProductBreakupActions.ProductConfigInputs>(); 
        ProductBreakupActions.ProductConfigInputs PBInput = new ProductBreakupActions.ProductConfigInputs();
        PBInput.Name = 'Test config';
        PBInput.Announce = true;
        PBInput.Announce2 = true;
        PBInput.AnnounceEngagement = 1200;
        PBInput.Announce2Engagement = 1200;
        PBInput.Brand = 'New';
		PBInput.OrchestrationFeeIncluded = 'No';
        PBInput.DocNews = true;
        PBInput.DocNewsEngagement = 100; 
        PBInput.DocSpot = true; 
        PBInput.DocSpotEngagement = 100;  
        PBInput.DocPoint = true; 
        PBInput.DocPointEngagement = 100;  
        PBInput.FormularyOne = true; 
        PBInput.FormularyOneEngagement = 300;  
        PBInput.OPID = OLI1.id; 
        inputs.add(PBInput);
        List<ProductBreakupActions.ProductBreakupResults> lstResult = new List<ProductBreakupActions.ProductBreakupResults>();
        lstResult =  ProductBreakupActions.CreateProductConfig(inputs);
        
        List<string> PCIDs = lstResult[0].ProductConfigs;
        List<Product_Breakup__c> lstPBs = [select id, Engagements__c, CPE__c from Product_Breakup__c 
                                           where Product_Configuration__c = :PCIDs[0]];
        List<Product_Breakup__c> uplstPBs = new List<Product_Breakup__c>();
         for (Product_Breakup__c updtPB : lstPBs){
             updtPB.Engagements__c = updtPB.Engagements__c + 5;
             uplstPBs.add(updtPB);
         }
         update uplstPBs;
     }
    

}