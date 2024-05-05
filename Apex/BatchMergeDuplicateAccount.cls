/** 
*
* @author: Moshe Uzan
* @since: 28/02/2024
* Last Modified: Moshe Uzan 29/02/2024
*
* @description: This class is responsible for flaging duplicate accounts in the system.
*
*/

global class BatchMergeDuplicateAccount implements Schedulable, Database.Batchable<sObject>, Database.Stateful {
 
    global List<String> emails = new List<String>();
    global List<String> brands = new List<String>();

    public BatchMergeDuplicateAccount() {
        // default constructor
    }

    global BatchMergeDuplicateAccount(List<String> emails, List<String> brands) {
        this.emails = emails;
        this.brands = brands;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator('SELECT Id, PersonEmail, SHI_Brand__c, Owner.Name, MasterAccount__c, shi_RegistrationSite__c, shi_isGuest__c, CreatedDate '
                                      + 'FROM Account '
                                      + 'WHERE PersonEmail IN :emails AND SHI_Brand__c IN :brands ORDER BY PersonEmail, SHI_Brand__c desc');
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {

        Map<String, List<Account>> mapEmailBrand = new Map<String, List<Account>>();

        // A map to store the master account for each duplicate account
        Map<id, List<Account>> mapMasterAccount = new Map<id, List<Account>>();

        for (Account acc : scope) {

            if(!mapEmailBrand.containsKey(acc.PersonEmail + acc.SHI_Brand__c)) {
                mapEmailBrand.put(acc.PersonEmail + acc.SHI_Brand__c, new List<Account>());
            }

            mapEmailBrand.get(acc.PersonEmail + acc.SHI_Brand__c).add(acc);
        }

        for (List<Account> accList : mapEmailBrand.values()) {

            Account MasterAcc = null;

            for(Account acc : accList){

                if(MasterAcc == null){
                    MasterAcc = acc;
                }
                
                // first rule - if the account isn't a guest, it can be master
                else if(acc.shi_RegistrationSite__c != null  && acc.shi_RegistrationSite__c != ''){

                    // if the master account is a guest, or the new account is newer than the master account
                    if(MasterAcc.shi_RegistrationSite__c == null || MasterAcc.shi_RegistrationSite__c == '' || MasterAcc.CreatedDate < acc.CreatedDate){
                        MasterAcc = acc;
                    }
                }

                // second rule - if the CreatedDate is newer than the master account, it can be master
                else if(acc.CreatedDate > MasterAcc.CreatedDate && (MasterAcc.shi_RegistrationSite__c == null  || MasterAcc.shi_RegistrationSite__c == '')){
                    MasterAcc = acc;
                }

                // third rule - if the owner isn't a system admin, and the master account is a system admin, it can be master
                else if(acc.Owner.Name != 'System Admin' && MasterAcc.Owner.Name == 'System Admin' && (MasterAcc.shi_RegistrationSite__c == null  || MasterAcc.shi_RegistrationSite__c == '') && acc.CreatedDate > MasterAcc.CreatedDate){
                    MasterAcc = acc;
                }
            }

            // if the master account isn't in the map, add it
            if(!mapMasterAccount.containsKey(MasterAcc.Id))
                mapMasterAccount.put(MasterAcc.Id, accList);
        }

        List<Account> ListAccToUpdate = new List<Account>();

        for(id masterId : mapMasterAccount.keySet()){

            List<Account> accList = mapMasterAccount.get(masterId);

            for(Account acc : accList){
                // update the master account with the new account
                if(acc.Id != masterId){
                    acc.MasterAccount__c = masterId;
                    ListAccToUpdate.add(acc);
                }
                else {
                    acc.MasterAccount__c = null;
                    ListAccToUpdate.add(acc);
                }
                
            }
        }
        
        if(ListAccToUpdate.size() > 0){
            try{
                Database.SaveResult[] SR = Database.update(ListAccToUpdate, false);
                System.debug('In - ');
                for(Database.SaveResult s : SR){
                    if(!s.isSuccess()){
                        for(Database.Error e : s.getErrors()){
                            System.debug('The error is ' + e.getMessage());
                        }
                    }
                }
            }
            catch(Exception e) {
                System.debug('The error is ' + e.getMessage());
            }
        }
    }

    public void execute(SchedulableContext ctx){
        // execute Schedule Class
        Database.executeBatch(new BatchMergeDuplicateAccount(),100);
    }

    public void finish(Database.BatchableContext bc) {
        
    }
 
}