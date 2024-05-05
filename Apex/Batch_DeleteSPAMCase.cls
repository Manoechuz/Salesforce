/*
    * Created by Moshe Uzan on 23/10/2023.
    * Last modified by Moshe Uzan on 22/02/2024. 
    * Description : An Apex Batch Class for deleting SPAM Cases and their related Accounts under specific conditions.
                    This batch class identifies accounts linked to only SPAM cases and with no orders or returns in the current year,
                    then deletes those SPAM cases and accounts, logging any errors encountered during the process.
*/
public class Batch_DeleteSPAMCase implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts {
    
    // Query to identify Accounts with only SPAM Cases and no orders/returns for deletion
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT ID, (SELECT CaseNumber FROM Cases), (SELECT ID FROM Orders), (SELECT ID FROM Returns__r) '
                     + 'FROM Account WHERE IsGenericAccount__c = False AND ID IN (SELECT AccountId FROM Case WHERE Type = \'SPAM\') '
                     + 'AND ID NOT IN (SELECT AccountId FROM Case WHERE Type != \'SPAM\') '
                     + 'AND (shi_total_number_orders_ytd__c = null OR shi_total_number_orders_ytd__c = 0) '
                     + 'AND (shi_total_number_returns_ytd__c = null OR shi_total_number_returns_ytd__c = 0)';
        return Database.getQueryLocator(query);
    }
    
    // Executes the batch operation, deleting identified Cases and Accounts, logging any errors
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        List<Case> caseList = new List<Case>();
        List<Account> accList = new List<Account>();

        // Initialize the error log object and set its fields
        SHI_Error_Log__c myLog = new SHI_Error_Log__c();
        myLog.shi_errorType__c = 'Batch for delete SPAM Case with Account\n';
        myLog.shi_errorMessage__c = 'Error Log Initialization:\n';

        Boolean hasChanged = false;
        
        for (Account acc : scope) {
            if (!acc.Orders.isEmpty() || !acc.Returns__r.isEmpty()) {
                continue;
            }
            accList.add(acc);
            caseList.addAll(acc.Cases);
        }

        List<Database.DeleteResult> resultsCase = Database.delete(caseList, false);
        
        for (Database.DeleteResult result : resultsCase) {
            for (Database.Error error : result.getErrors()) {
                myLog.shi_errorMessage__c += 'Error on Case' + ' Delete: ' + error.getMessage() + ' *** On the Field: ' + error.getFields() + '\n';
                hasChanged = true;
            }
        }
        
        List<Database.DeleteResult> resultsAcc = Database.delete(accList, false);
        
        for (Database.DeleteResult result : resultsAcc) {
            for (Database.Error error : result.getErrors()) {
                myLog.shi_errorMessage__c += 'Error on Account' + ' Delete: ' + error.getMessage() + ' *** On the Field: ' + error.getFields() + '\n';
                hasChanged = true;
            }
        }
        
        // If there were any errors, insert the log
        if (hasChanged) {
            Database.insert(myLog, false);
        }
    }
    
    // Method to kick off the batch job when scheduled
    public void execute(SchedulableContext ctx) {
        Database.executeBatch(new Batch_DeleteSPAMCase(), 20);
    }

    public void finish(Database.BatchableContext bc) {
        // Implement any necessary post-processing operations here, such as sending notifications or emails
    }
}