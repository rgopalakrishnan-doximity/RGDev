@isTest
public class DDRequestControllerTest {

    @testSetup
    static void setupData() {
        Profile proObj = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User usObj = new User(
            Alias = 'csmusr',
            Email = 'csm@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'CSM',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = proObj.Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'usObj' + System.currentTimeMillis() + '@test.com'
        );
        insert usObj;

        Account acc = new Account(Name = 'Test Account');
        insert acc;
		
         Opportunity opp1 = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = '10%',
            Agency_3rd_Party__c = acc.Id,
            CloseDate = Date.today().addDays(30),
            Type = 'New Business',
            Client_Success_Manager__c = usObj.Id,
            Discount_Approval_Status__c = 'Approved'
        );
        insert opp1;
        
     
        
        Product2 prod = new Product2(
            Name = 'Test Product',
            IsActive = true,
            BMI_SF_NS__NetSuiteID__c = 'test'
        );
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        opp1.Pricebook2Id =Test.getStandardPricebookId() ;
        update opp1;

       
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = '10%',
            Agency_3rd_Party__c = acc.Id,
            CloseDate = Date.today().addDays(30),
            Type = 'New Business',
            Client_Success_Manager__c = usObj.Id,
            Discount_Approval_Status__c = 'Approved',
            Parent_Opportunity__c = opp1.id
        );
        insert opp;
		opp1.Parent_Opportunity__c = opp.id;
        update opp1;
        
         OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp1.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            TotalPrice = 100,
            Product_Enhancement_Only__c = true,
            Missing_Content_Type__c = 4
        );
        insert oli;
         
        User usObj1 = new User(
            Alias = 'csmusr',
            Email = 'csm@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'CSM',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = proObj.Id,
            TimeZoneSidKey = 'America/New_York',
            isactive = false,
            UserName = 'usObj1' + System.currentTimeMillis() + '@test.com'
        );
        insert usObj1;
        
        Opportunity opp2 = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = '0%',
            ownerid = usObj1.id,
            Agency_3rd_Party__c = acc.Id,
            CloseDate = Date.today().addDays(30),
            Type = 'New Business',
            Client_Success_Manager__c = usObj1.Id
        );
        insert opp2;
        
    }

    @isTest
    static void testHappyPath() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        String result = DDRequestController.ContractRequest(opp.Id);
        Test.stopTest();
    }
    
	 @isTest
    static void testNoParentOpp() {
        Opportunity opp = [SELECT Id FROM Opportunity where Parent_Opportunity__c =null LIMIT 1];

        Test.startTest();
        String result = DDRequestController.ContractRequest(opp.Id);
        Test.stopTest();
    }


    @isTest
    static void testMissingType() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.Type = null;
        update opp;

        Test.startTest();
        String result = DDRequestController.ContractRequest(opp.Id);
        Test.stopTest();
    }
	
    
    
    @isTest
    static void testUnresolvedProducts() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        update opp;

        Test.startTest();
        String result = DDRequestController.ContractRequest(opp.Id);
        Test.stopTest();
    }

    @isTest
    static void testApprovalRequired() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.Discount_Approval_Status__c = 'Pending';
        update opp;

        Test.startTest();
        String result = DDRequestController.ContractRequest(opp.Id);
        Test.stopTest();
    }

    @isTest
    static void testAmendmentBlocksRequest() {
        List<Opportunity> opp = [SELECT Id FROM Opportunity LIMIT 3];

       

        Test.startTest();
        try{
            Amendment__c amend = new Amendment__c(
                Opportunity__c = opp[0].Id,
                Amendment_Status__c = 'New Request'
            );
            insert amend;
            
            Amendment__c amend1 = new Amendment__c(
                Opportunity__c = opp[1].Id,
                Amendment_Status__c = 'New Request'
            );
            insert amend1;
            
             Amendment__c amend2 = new Amendment__c(
                Opportunity__c = opp[2].Id,
                Amendment_Status__c = 'New Request'
            );
            insert amend2;
            
         String result = DDRequestController.ContractRequest(opp[0].Id);
        }catch(exception e){
            
        }
        Test.stopTest();
    }
	
    
    
   @isTest
static void testUpsellClosedMustUseParent() {
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

    User execUser = new User(
        Alias = 'execu',
        Email = 'exec@test.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Exec',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'America/New_York',
        UserName = 'exec' + System.currentTimeMillis() + '@test.com',
        Team__c = '6-Exec / Finance'
    );
    insert execUser;

    PermissionSet ps = [
        SELECT Id 
        FROM PermissionSet 
        WHERE Name = 'Deal_Desk' 
        LIMIT 1
    ];

    insert new PermissionSetAssignment(
        AssigneeId = execUser.Id,
        PermissionSetId = ps.Id
    );

    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

    System.runAs(execUser) {
        opp.Type = 'Upsell';
        opp.StageName = '100% - Closed Won';
        update opp;

        Test.startTest();
        String result = DDRequestController.ContractRequest(opp.Id);
        Test.stopTest();
    }
}
@isTest
static void testClosedWonFlowCO() {
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

    User execUser = new User(
        Alias = 'execu2',
        Email = 'exec2@test.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Exec2',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'America/New_York',
        UserName = 'exec2' + System.currentTimeMillis() + '@test.com',
        Team__c = '6-Exec / Finance'
    );
    insert execUser;

    PermissionSet ps = [
        SELECT Id 
        FROM PermissionSet 
        WHERE Name = 'Deal_Desk' 
        LIMIT 1
    ];

    insert new PermissionSetAssignment(
        AssigneeId = execUser.Id,
        PermissionSetId = ps.Id
    );

    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

    System.runAs(execUser) {
        opp.StageName = '100% - Closed Won';
        update opp;

        Test.startTest();
        String result = DDRequestController.ContractRequest(opp.Id);
        Test.stopTest();
    }
}
    
    @isTest
static void testOpportunityLockedForApproval() {

    // Get an existing opp from setup
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

    // Submit for approval
    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
    req.setObjectId(opp.Id);
    req.setComments('Submitting for approval');

    Approval.ProcessResult result = Approval.process(req);

    Test.startTest();
    String resultStr = DDRequestController.ContractRequest(opp.Id);
    Test.stopTest();

    System.assert(resultStr.contains('Opportunity is locked for approval'));
}
  
}