public class FullViewController {

    @AuraEnabled(cacheable=true)
    public static List<FullViewApex> getFullView(String recordId) {
        
        string OppID = '';
        string ParentOppID = null;
        
        if (recordId.startsWith('006')) {
           Opportunity Opp = [SELECT id, Parent_Opportunity__c FROM Opportunity WHERE Id =:recordId Limit 1];
           OppID =  recordId;
           ParentOppID = Opp.Parent_Opportunity__c;
        }else{
           Amendment__c amend = [SELECT id, Opportunity__c,Parent_Opportunity__c
                             FROM Amendment__c WHERE Id =:recordId Limit 1];
           OppID =  amend.Opportunity__c;
           ParentOppID = amend.Parent_Opportunity__c; 
        }
        
 
        
        List<Amendment__c> AllContracts = new List<Amendment__c>();
         //find fully executed Contracts chronologically.
        if (ParentOppID != null && ParentOppID != ''){
            AllContracts = [SELECT id,Name,Project_Title__c, Summary_of_Changes__c,Amendment_Notes__c, 
                             Type__c, Type_of_Request__c ,Amendment_Status__c, 
                             Contract_Effective_Date__c,SOW_Effective_Date__c, Change_Order_Number__c, SFDC_Documentation_Only__c,Date_Amendment_Completed__c
                             FROM Amendment__c WHERE 
                            ( Opportunity__c = :OppID  or 
                             Opportunity__c = :ParentOppID ) and   
                             Amendment_Status__c = 'Fully Executed'
                             order by Date_Amendment_Completed__c asc];
            
        }else{
            
            AllContracts = [SELECT id,Name,Project_Title__c, Summary_of_Changes__c,Amendment_Notes__c,
                             Type__c, Type_of_Request__c ,Amendment_Status__c, 
                             Contract_Effective_Date__c,SOW_Effective_Date__c, Change_Order_Number__c, SFDC_Documentation_Only__c,Date_Amendment_Completed__c 
                             FROM Amendment__c WHERE 
                            ( Opportunity__c = :OppID  or 
                             Parent_Opportunity__c = :OppID) and   
                             Amendment_Status__c = 'Fully Executed'
                             order by Date_Amendment_Completed__c asc];

            
        }
        
        List<FullViewApex> lstWrap = new List<FullViewApex>();
        string conurl = '';
        boolean ischangeorder = false;
        Integer CO = 0;
        
        for ( Amendment__c con : AllContracts){
             
            conurl = '/' + con.id;
            ischangeorder = (con.Type__c == 'SOW') ? false : true;
            
            if (con.Type__c != 'SOW'){
               if (con.Change_Order_Number__c != null){
                    CO = Integer.valueof(con.Change_Order_Number__c);
                }else{
                    CO = CO + 1;
                } 
            }
             
            lstWrap.add(new FullViewApex(con.id, con.Name, con.Project_Title__c, con.Summary_of_Changes__c,
                 				con.Amendment_Notes__c,con.Type__c,
                 				con.Type_of_Request__c,con.Amendment_Status__c,
                 			    con.Contract_Effective_Date__c, con.SOW_Effective_Date__c,
                 				CO, conurl, ischangeorder, 
                                con.SFDC_Documentation_Only__c, con.Date_Amendment_Completed__c
                         ));
        }
       
     
        return lstWrap;
        
        
    }
}