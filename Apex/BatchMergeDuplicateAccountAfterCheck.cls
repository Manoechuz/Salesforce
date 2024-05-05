/** 
*
* @author: Moshe Uzan
* @since: 29/02/2024
* Last Modified: Moshe Uzan 10/03/2024
*
* @description: This class is a batch class that will merge all the
                duplicate accounts that have the same Master Account and update the Master Account with the information from the duplicates.
*
*/

public class BatchMergeDuplicateAccountAfterCheck implements Schedulable, Database.Batchable<sObject> {

    public String brand;
    public Datetime fromDate;
    public Datetime toDate;
    
    public BatchMergeDuplicateAccountAfterCheck() {
        // Constructor
    }

    public BatchMergeDuplicateAccountAfterCheck(String brand, Datetime fromDate, Datetime toDate) {
        // Constructor
        this.brand = brand;
        this.fromDate = fromDate;
        this.toDate = toDate;
    }
 
    public Database.QueryLocator start(Database.BatchableContext bc) {

        schema.SObjectType targetType = Schema.getGlobalDescribe().get('Account');
        Map<String, Schema.SObjectField> fieldMap = targetType.getDescribe().fields.getMap();
        String fieldNames = '';

        for (Schema.SObjectField field : fieldMap.values()) {

            if(field.getDescribe().getName() == 'MasterAccount__c')
                fieldNames += field.getDescribe().getName() + ', ';

            else if(field.getDescribe().isAccessible() && field.getDescribe().isUpdateable() && field.getDescribe().getName() != 'Name')
                fieldNames += field.getDescribe().getName() + ', ';
        }

        if(brand != null && fromDate != null && toDate != null){
            return Database.getQueryLocator('SELECT ' + fieldNames.substring(0, fieldNames.length() - 2)
            + ' FROM Account WHERE SHI_Brand__c = :brand AND CreatedDate >= :fromDate AND CreatedDate <= :toDate AND MasterAccount__c != NULL ORDER BY MasterAccount__c, CreatedDate DESC' );
        }
            
        return Database.getQueryLocator('SELECT ' + fieldNames.substring(0, fieldNames.length() - 2)
        + ' FROM Account WHERE MasterAccount__c != NULL ORDER BY MasterAccount__c, CreatedDate DESC' );
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        Set<Id> masterAccountIds = new Set<Id>();

        // identify all the master accounts
        for(Account acc : scope){
            masterAccountIds.add(acc.MasterAccount__c);
        }

        schema.SObjectType targetType = Schema.getGlobalDescribe().get('Account');
        Map<String, Schema.SObjectField> fieldMap = targetType.getDescribe().fields.getMap();
        String fieldNames = '';

        for (Schema.SObjectField field : fieldMap.values()) {

            if(field.getDescribe().getName() == 'MasterAccount__c')
                fieldNames += field.getDescribe().getName() + ', ';

            // Check if we can update the field and also filtering Name because we can't update it
            else if(field.getDescribe().isAccessible() && field.getDescribe().isUpdateable() && field.getDescribe().getName() != 'Name')
                fieldNames += field.getDescribe().getName() + ', ';
        }

        // Map AccountMaster By Id
        String queryString = 'SELECT ' + fieldNames.substring(0, fieldNames.length() - 2) + ' FROM Account WHERE Id IN :masterAccountIds';

        // Assuming masterAccountIds is a Set<Id> containing the IDs of the master accounts
        List<Account> queryResults = Database.query(queryString);

        // Initialize the map
        Map<Id, Account> masterAccounts = new Map<Id, Account>();

        // Populate the map
        for(Account acc : queryResults) {
            masterAccounts.put(acc.Id, acc);
        }

        // Map AccountMaster By Id
        Map<Id, List<Account>> mapMasterDuplicateIDs = new Map<Id, List<Account>>();

        // Getting all the Master Accounts into the Map
        for(Account acc : scope){

            if(!mapMasterDuplicateIDs.containsKey(acc.MasterAccount__c)){
                mapMasterDuplicateIDs.put(acc.MasterAccount__c, new List<Account>());
            }

            if(acc.id != acc.MasterAccount__c){
                mapMasterDuplicateIDs.get(acc.MasterAccount__c).add(acc);
                
                // Update the Master Account if needed
                // Retrieve the fields of the current account
                Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(acc));
                Boolean first = true;

                Account MasterAccount = masterAccounts.get(acc.MasterAccount__c);

                for(String key : m.keySet()){

                    if(first){
                        first = false;
                        continue;
                    }

                    // if we are violating the constraint to have a lookup to ourself 
                    // (meaning we are trying to put in masteraccount field he id of the acc master (himself)) - util after check
                    if(MasterAccount.get('Id') == acc.get(key)){
                        continue;
                    }  

                    if(MasterAccount.get(key) == null && acc.get(key) != null) {
                        try{
                            MasterAccount.put(key, acc.get(key));
                        }
                        catch(Exception e){
                            System.debug('The error is ' + e.getMessage());
                        }
                    }
                }  
            }
        }

        // Merge the duplicates
        for(Id masterId : mapMasterDuplicateIDs.keySet()){

            Account masterAccount;
            List<Account> duplicateIds = mapMasterDuplicateIDs.get(masterId);

            if(masterAccounts.containsKey(masterId))
                masterAccount = masterAccounts.get(masterId);

            // while we have more than 2 duplicates
            While(duplicateIds.size() > 0){

                List<Account> accountsToMerge = new List<Account>();

                accountsToMerge.add(duplicateIds.remove(0));

                if(duplicateIds.size() > 0)
                    accountsToMerge.add(duplicateIds.remove(0));
                
                try {

                    Database.MergeResult[] results = Database.merge(masterAccount, accountsToMerge, false);

                    if(!results[0].isSuccess())
                        System.debug('Failed to merge accounts: ' + results[0].errors[0].getMessage());
        
                    if(accountsToMerge.size() == 2 && !results[1].isSuccess())
                        System.debug('Failed to merge accounts: ' + results[1].errors[0].getMessage());
                    
                }
                catch(Exception e){
                    // log the error
                    System.debug('Failed to merge accounts: ' + e.getMessage());
                }
            }
        }
    }

    public void execute(SchedulableContext ctx){
        // execute Schedule Class
        Database.executeBatch(new BatchMergeDuplicateAccountAfterCheck(),200);
    }

    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations - send emails, notify clients,
    }
 
}