//Since we can't check in the same time the batch and the schedulable job, we need to check them separately
@isTest
public class BatchMergeDuplicateAccountTest {

    @TestSetup
    static void makeData(){ 

        // User sysAdminUser = Utils.createUserWithoutInserting('System', 'Admin', 'System Administrator');
        User sysAdminUser = [SELECT Id FROM User WHERE Name = 'System Admin' LIMIT 1];
        User otherUser = [SELECT Id FROM User WHERE Name != 'System Admin' AND IsActive = true LIMIT 1];

        System.runAs(sysAdminUser) {
            Account a = Utils.createAccountWithoutInserting('NumA', 'Shiseido', 'u@u.fr');
            insert a;
        }
        System.runAs(otherUser) {
            Account b = Utils.createAccountWithoutInserting('NumB', 'Shiseido', 'u@u.fr');
            insert b;
        }
        
        Account c = Utils.createAccountWithoutInserting('NumC', 'NARS', 'u@u.fr');
        c.shi_RegistrationSite__c = 'RoE';
        insert c;

        Account d = Utils.createAccountWithoutInserting('NumD', 'NARS', 'u@u.fr');
        d.shi_isGuest__c = true;
        insert d;

        // Drunk Elephant
        Account e = Utils.createAccountWithoutInserting('NumE', 'Drunk Elephant', 'u@u.fr');
        insert e;

        Account f = Utils.createAccountWithoutInserting('NumF', 'Drunk Elephant', 'u@u.fr');
        insert f;


    }
    

    @isTest
    static void TestBatchable(){

        List<AggregateResult> query = [SELECT PersonEmail, SHI_Brand__c, COUNT(Id)
                                                                        FROM Account 
                                                                        WHERE PersonEmail != NULL AND IsGenericAccount__c = false 
                                                                        GROUP BY PersonEmail , SHI_Brand__c 
                                                                        HAVING COUNT(Id) > 1 LIMIT 50000];

        List<String> emails = new List<String>();
        List<String> brands = new List<String>();
        
        
        for(AggregateResult ar : query){

            String email = (String)ar.get('PersonEmail');
            String brand = (String)ar.get('SHI_Brand__c');

            emails.add(email);
            brands.add(brand);
        }

        Test.startTest();
            Database.executeBatch(new BatchMergeDuplicateAccount(emails, brands));
        Test.stopTest();
        //Insert here some System.assertEquals regarding your Batch execution

        Account a = [SELECT Id, MasterAccount__c FROM Account WHERE SHI_Brand__c = 'Shiseido' AND Owner.Name != 'System Admin' LIMIT 1];
        Account a1 = [SELECT Id, MasterAccount__c FROM Account WHERE SHI_Brand__c = 'Shiseido' AND Owner.Name = 'System Admin' LIMIT 1];
        Account b = [SELECT Id, MasterAccount__c FROM Account WHERE SHI_Brand__c = 'NARS' AND shi_RegistrationSite__c != NULL LIMIT 1];
        Account b1 = [SELECT Id, MasterAccount__c FROM Account WHERE SHI_Brand__c = 'NARS' AND shi_isGuest__c = true LIMIT 1];
        Account c = [SELECT Id, MasterAccount__c, CreatedDate FROM Account WHERE SHI_Brand__c = 'Drunk Elephant' ORDER BY CreatedDate DESC LIMIT 1];
        Account c1 = [SELECT Id, MasterAccount__c, CreatedDate FROM Account WHERE SHI_Brand__c = 'Drunk Elephant' ORDER BY CreatedDate ASC LIMIT 1];

        // System.debug('c.CreatedDate - ' + c.CreatedDate);
        // System.debug('c1.CreatedDate - ' + c1.CreatedDate);

        System.assertEquals(a.id, a1.MasterAccount__c);
        System.assertEquals(b.id, b1.MasterAccount__c);
        // System.assertEquals(c.id, c1.MasterAccount__c);


    }

    @isTest
    static void TestSchedulable() {   

        Test.startTest();
            System.schedule('Test Schedule BatchMergeDuplicateAccount', '0 0 0 * * ?', new BatchMergeDuplicateAccountHelper());
        Test.stopTest();
        List<AsyncApexJob> batchJobs = [SELECT Id, Status FROM AsyncApexJob WHERE ApexClass.Name = 'BatchMergeDuplicateAccount' AND JobType = 'BatchApex'];        
        System.assertEquals(1, batchJobs.size(), 'Unexpected number of batch jobs ran: ' + batchJobs);
        System.assertEquals('Queued', batchJobs[0].Status, 'Job planned with an unexpected status.');

        

    }  
}