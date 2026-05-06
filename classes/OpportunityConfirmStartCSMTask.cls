public class OpportunityConfirmStartCSMTask {
        @InvocableMethod(label = 'Check if CSM Task can be created' description = 'Check if CSM Task Confirm Contractual Start Date can be created')
            public static List<Results> execute (List<Requests> requestList) {
       		     string OppID = requestList[0].OppID;
                 string emptyProduct = '';
                 boolean outputMember = false; //by default true;
                 List<string> OppProducts = new List<string>();
                 //check if the Opp type is debooking then return false
                 //check if the Products are only conference and condition feed then return false
                 Opportunity Opp = [SELECT ID,Type,Products__c, Client_Success_Flag__c  FROM Opportunity WHERE ID = :OppID];
                 OppProducts = ( Opp.Products__c != null) ? Opp.Products__c.split(',') : emptyProduct.split(',') ;
                 if (Opp.Type == 'Debooking'){
                    outputMember = false;
                    system.debug('debook--');
                 }else{
                     for(string s : OppProducts){
                         if ( !s.contains('Conference') && !s.contains('Condition') && !Opp.Client_Success_Flag__c){
                             outputMember = true;
                             break;
                         }
				}
                 }
               	 Results response = new Results();
                 response.outputMember = outputMember;
				 List<Results> responseWrapper = new List<Results> ();
            	 responseWrapper.add(response);
                 return responseWrapper;
    		}

    //
    Public class Requests {
        @InvocableVariable(label = 'Opportunity ID' description = 'Test Description' required = false)
        public string OppID;
    }
    //
    Public class Results {
        @InvocableVariable(label = 'Allow or Disallow' description = '' required = true)
        public Boolean outputMember;
    }
}