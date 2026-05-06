public class DDRequestController {
    
    @auraenabled
    Public Static String ContractRequest(ID OppID){
        string Retval = '';
        string strerror = 'N';
        string ErrorMsg = '';
        string flow = '';
        
        Opportunity Opp = [SELECT Id,Client_Success_Manager__r.IsActive,StageName,
                           Owner.IsActive,Parent_Opportunity__c,
                           Requires_Approval__c,Discount_Approval_Status__c,
                           Type,Unresolved_Product_Items__c 
                           FROM Opportunity 
                           WHERE ID = :OppID];
        
        
        if (Opp.Client_Success_Manager__r.IsActive == null || !Opp.Client_Success_Manager__r.IsActive){
            strerror = 'Y';
            ErrorMsg = 'Client Success is not set or inactive.'  + '\n';
        }
        if (!Opp.Owner.IsActive){
            strerror = 'Y';
            ErrorMsg = ErrorMsg + 'Opportunity Owner is inactive.'  + '\n';
        }
        if (Approval.isLocked(OppID)){
            strerror = 'Y';
            ErrorMsg = ErrorMsg + 'Opportunity is locked for approval.'  + '\n';
        }
        if (Opp.Type == null || Opp.Type == ''){
            strerror = 'Y';
            ErrorMsg = ErrorMsg + 'Please fill in type on Opportunity before requesting a contract.'  + '\n';
        }
        if (Opp.Unresolved_Product_Items__c != 0 ){
            strerror = 'Y';
            ErrorMsg = ErrorMsg + 'One or more products is missing information. These must be fixed before you can request a contract.'  + '\n';
        }
        
        if (Opp.StageName == '0%' || Opp.StageName == '0% - Closed Lost'){
            strerror = 'Y';
            ErrorMsg = ErrorMsg + 'Opportunity must be between 10% and 90% to request contracting.'  + '\n';
        }
        if (Opp.Requires_Approval__c != 'No - We\'re good here' && Opp.Discount_Approval_Status__c != 'Approved'){
            strerror = 'Y';
            ErrorMsg = ErrorMsg + 'This opportunity requires approval before contracting can be requested.'  + '\n';
        }
       // Requires_Approval__c
        Map<id, Opportunity> allOpps = new Map<id, Opportunity>();
        
        if (Opp.Parent_Opportunity__c != null){
            allOpps = new Map<id, Opportunity>([SELECT id, name FROM Opportunity 
                   WHERE (id = :OppID or 
                          parent_opportunity__c = :Oppid or
                          id = :Opp.Parent_Opportunity__c or
                          parent_opportunity__c = :Opp.Parent_Opportunity__c)]);
        }else{
            allOpps = new Map<id, Opportunity>([SELECT id, name FROM Opportunity 
                   WHERE (id = :OppID or 
                          parent_opportunity__c = :Oppid )]);
        }
        
        system.debug(allOpps.keyset());
        system.debug(allOpps.size());

        List<Amendment__c> amend = [SELECT id, Opportunity__r.ID,Parent_Opportunity__r.id,
                             Opportunity__r.StageName
                             FROM Amendment__c WHERE Opportunity__c IN :allOpps.keyset() and 
                             Amendment_Status__c NOT IN ('Cancelled', 'Fully Executed') ];
        
        system.debug(amend.size());
        if (amend.size() > 0){
            strerror = 'Y';
            ErrorMsg = ErrorMsg + 'There is a contract request already open for this Program.'  + '\n';
        }
        //request only from parent after the child is closed
        if ((Opp.Type == 'Upsell' || Opp.Type == 'Debooking') && (Opp.StageName == '100% - Closed Won' || Opp.StageName == '0% - Closed Lost')) {
            strerror = 'Y';
            ErrorMsg = ErrorMsg + 'Please request the contract from the Parent.'  + '\n';
        }
        if (strerror == 'N'){
            if (Opp.StageName != '100% - Closed Won'){
               if (Opp.Type == 'Upsell' || Opp.Type == 'Debooking'){
                  flow = 'CO';  
               }else if (Opp.Type == 'New Business' || Opp.Type == 'New Program'){
                  flow = 'SOW';
               }
            }else if (Opp.StageName == '100% - Closed Won'){
                flow = 'CO';  
            }
        }else{
            flow = 'ERROR';
        }
        Retval = strerror + '~' + flow + '~' + ErrorMsg;
        system.debug(Retval);
        return RetVal;
    }

}