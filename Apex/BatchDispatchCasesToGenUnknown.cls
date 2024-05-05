/*
 Created by : Moshe Uzan, 08/02/2024 
 Last modified by : Moshe Uzan, 13/02/2024 
 Description : This class is a batch that will dispatch unknown cases to generic accounts. 
               The batch will dispatch cases to generic accounts that have the same brand and language as the case. 
               If the generic account is full, the batch will create a new generic account and dispatch the cases to it. 
               The batch will also update the generic account that is full with an email address that will tell us that the account is full.
*/

public class BatchDispatchCasesToGenUnknown implements Schedulable, Database.Batchable<sObject> {

    static Integer limitSizeCaseToDML = 10000;
    static Integer limitSizeCaseByMaster = 9500;

    // Condition pour que le Batch marche : il faut que les Masters accounts couvrent ttes les marques existantes et les langues existantes et egalement que les champs brands et langues dans les accounts et les cases soient identiques.
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT ID, PersonContactId, PersonEmail, shi_Country__c,(SELECT ID, shi_Language_Level_5__c, shi_designersbrands__c, shi_techCountry__c FROM Cases LIMIT 75) ' 
                                        + 'FROM ACCOUNT WHERE NAME LIKE \'%Unknown%\' '
                                        + 'AND (PersonEmail = NULL OR PersonEmail LIKE \'%Unknown%\') '
                                        + 'AND IsGenericAccount__c = False '
                                        + 'AND ID IN (SELECT ACCOUNTID FROM CASE) ' 
                                        + 'AND ID NOT IN (SELECT ACCOUNTID FROM ORDER) LIMIT 10000');
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {

        if(Test.isRunningTest()) {
            limitSizeCaseByMaster = 10;
        }

        List<Case> casesToDispatch = new List<Case>();

        List<Account> accountMasterFullToUpdate = new List<Account>();

        List<Account> accountMaster = [SELECT ID, PersonContactId, shi_zone__c, FirstName, LastName, PersonEmail, shi_language__c, SHI_Brand__c, shi_Country__c
                                        FROM Account 
                                        WHERE FirstName LIKE 'Unknown_%' 
                                        AND LastName LIKE 'Unknown_%' AND PersonEmail = NULL AND IsGenericAccount__c = True];

        Set<String> setLanguageCountryMaster = new Set<String>();
        Set<String> setOutsideCountryMaster = new Set<String>();
        Set<String> setBrandMaster = new Set<String>();

        for(Account a : accountMaster){

            if(a.shi_zone__c == 'EMEA'){
                setLanguageCountryMaster.add(a.shi_language__c + a.shi_Country__c);
            }

            else if(a.shi_zone__c == 'Outside EMEA')
                setOutsideCountryMaster.add(a.shi_Country__c);
            
            setBrandMaster.add(a.SHI_Brand__c);
        }

        if(setOutsideCountryMaster.size() > 1){
            System.debug('Error more than one country outside EMEA');
            System.debug('setOutsideCountryMaster => ' + setOutsideCountryMaster);
            return;
        }

        List<String> listNameOutsideCountry = new List<String>(setOutsideCountryMaster);

        // map cases by brand and by langague
        Map<String, Map<String, List<Case>>> mapBrandLanguageCases = new Map<String, Map<String, List<Case>>>(); 

        for(String brand : setBrandMaster){

            mapBrandLanguageCases.put(brand, new Map<String, List<Case>>());
            
            if(listNameOutsideCountry.size() > 0 && mapBrandLanguageCases.get(brand).get(listNameOutsideCountry[0]) == null)
                mapBrandLanguageCases.get(brand).put(listNameOutsideCountry[0], new List<Case>());
        }

        Set<Case> listCaseUpdate = new Set<Case>();

        for(Account a : scope) {
            casesToDispatch.addAll(a.Cases);
        }

        // dispatch cases by brand and language in the map mapBrandLanguageCases
        for(Case c : casesToDispatch) {

            if(c.shi_Language_Level_5__c == null || c.shi_techCountry__c == null || c.shi_designersbrands__c == null){
                continue;
            }

            if(mapBrandLanguageCases.get(c.shi_designersbrands__c) == null){
                mapBrandLanguageCases.put(c.shi_designersbrands__c, new Map<String, List<Case>>());
            }

            if(setLanguageCountryMaster.contains(c.shi_Language_Level_5__c + c.shi_techCountry__c)){
                if(mapBrandLanguageCases.get(c.shi_designersbrands__c).get(c.shi_Language_Level_5__c + c.shi_techCountry__c) == null){
                    mapBrandLanguageCases.get(c.shi_designersbrands__c).put(c.shi_Language_Level_5__c + c.shi_techCountry__c, new List<Case>());
                }
                mapBrandLanguageCases.get(c.shi_designersbrands__c).get(c.shi_Language_Level_5__c + c.shi_techCountry__c).add(c);
            }
            else{
                if(listNameOutsideCountry.size() > 0 && mapBrandLanguageCases.get(c.shi_designersbrands__c).get(listNameOutsideCountry[0]) != null)
                    mapBrandLanguageCases.get(c.shi_designersbrands__c).get(listNameOutsideCountry[0]).add(c);
            }
        }

        // set ids of the Master Accounts
        Set<Id> setAccountId = new Set<Id>();
        
        for(Account a : accountMaster){
            setAccountId.add(a.Id);
        }

        // get the number of case by account Master
        List<AggregateResult> numCaseByMaster = [SELECT AccountId , COUNT(Id) total FROM Case WHERE AccountId IN :setAccountId GROUP BY AccountId];

        // Map the number of case already bound by account Master
        Map<Id, Integer> mapCountCaseByMaster = new Map<Id, Integer>();

        for(AggregateResult ar : numCaseByMaster){
            mapCountCaseByMaster.put((Id)ar.get('AccountId'), (Integer)ar.get('total'));
        }
        
        for(Account a : accountMaster){

            // if the mapBrandLanguageCases contains the brand and language of the account
            if(mapBrandLanguageCases.get(a.SHI_Brand__c) != null && (mapBrandLanguageCases.get(a.SHI_Brand__c).get(a.shi_Language__c + a.shi_Country__c) != null 
                                                                        || mapBrandLanguageCases.get(a.SHI_Brand__c).get(a.shi_Country__c) != null)){

                String key = a.shi_Language__c + a.shi_Country__c;

                if(mapBrandLanguageCases.get(a.SHI_Brand__c).get(a.shi_Country__c) != null){
                    key = a.shi_Country__c;
                }

                // if there is not cases bound to the current Master account.
                Integer countSizeCurr =  0;

                // if the account already has cases bound to it
                if(mapCountCaseByMaster.get(a.Id) != null){
                    countSizeCurr = mapCountCaseByMaster.get(a.Id);
                }

                Account curr = null;
                // first use case
                Boolean isFirst = true;

                for(Case c : mapBrandLanguageCases.get(a.SHI_Brand__c).get(key)){

                    if(isFirst){
                        curr = a;
                        isFirst= false;
                    }

                    if(countSizeCurr > limitSizeCaseByMaster){
                        Account newAccMaster = new Account();

                        newAccMaster.FirstName = curr.FirstName;
                        newAccMaster.LastName = curr.LastName;
                        newAccMaster.PersonEmail = null;
                        newAccMaster.SHI_Brand__c = curr.SHI_Brand__c;
                        newAccMaster.shi_Language__c = curr.shi_Language__c;
                        newAccMaster.shi_Country__c = curr.shi_Country__c;
                        newAccMaster.IsGenericAccount__c = True;

                        try{
                            Database.SaveResult s = Database.insert(newAccMaster);
                            }
                        catch(Exception e){
                                System.debug('The error is ' + e.getMessage());
                            }
                        // add an email to the account that will tell us that the current Mast Account is full
                        curr.PersonEmail = curr.FirstName + '@isFull.com';
                        // update the full account
                        accountMasterFullToUpdate.add(curr);
                        // switch to the new Account
                        curr = newAccMaster;
                        countSizeCurr = 0;
                    }
                    
                    c.AccountId = curr.Id;
                    C.ContactId = curr.PersonContactId;
                    listCaseUpdate.add(c);
                    countSizeCurr++;
                }
            }
        }
        
        if(listCaseUpdate.size() > 0){
            if(listCaseUpdate.size() > limitSizeCaseToDML){
                System.debug('The size of the listCaseUpdate is to big and is equal to ' + listCaseUpdate.size());
            }else{
                try{
                    List<Case> listCaseUpdateList = new List<Case>();
                    listCaseUpdateList.addAll(listCaseUpdate);
                    Database.SaveResult[] SR = Database.update(listCaseUpdateList, false);

                    for(Database.SaveResult s : SR){
                        if(!s.isSuccess()){
                            for(Database.Error e : s.getErrors()){
                                System.debug('The error is ' + e.getMessage());
                            }
                        }
                    }
                }
                catch(Exception e){
                    System.debug('The error is ' + e.getMessage());
                }
            }
        }

        if(accountMasterFullToUpdate.size() > 0){
            try{
                System.debug('accountMasterFullToUpdate =>  ' + accountMasterFullToUpdate);
                Database.SaveResult[] SR = Database.update(accountMasterFullToUpdate, false);
                for(Database.SaveResult s : SR){
                    if(!s.isSuccess()){
                        for(Database.Error e : s.getErrors()){
                            System.debug('The database.error is ' + e.getMessage());
                        }
                    }
                }
            }
            catch(Exception e){
                System.debug('The error is ' + e.getMessage());
            }
        }
    }

    public void execute(SchedulableContext ctx){
        // execute Schedule Class
        Database.executeBatch(new BatchDispatchCasesToGenUnknown(),200);
    }

    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations - send emails, notify clients,
        
    }
 
}