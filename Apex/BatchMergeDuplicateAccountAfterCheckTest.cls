/** 
*
* @author: Moshe Uzan
* @since: 10/03/2024
* Last Modified: Moshe Uzan 10/03/2024
*
* @description: Placeholder
*
*/
//Since we can't check in the same time the batch and the schedulable job, we need to check them separately
@isTest
public class BatchMergeDuplicateAccountAfterCheckTest {

    @TestSetup
    // creation des donnees pour les tests
    static void makeData() {

        Account a = Utils.createAccountWithoutInserting('NumA', 'Shiseido', 'u@u.fr');
        insert a;
        Account b = Utils.createAccountWithoutInserting('NumB', 'Shiseido', 'u@u.fr');
        b.Phone = '0000000001';
        b.shi_city__c = 'Paris';
        b.shi_zone__c = 'EMEA';
        b.shi_DefaultAddressPhoneNumber__c = '+447911123456';

        b.MasterAccount__c = a.Id;
        
        insert b;

        Case c = Utils.createCaseWithoutInserting(b.Id, 'Shiseido', 'Retail');
        insert c;
        // Case d = Utils.createCaseWithoutInserting(a.Id, 'Shiseido', 'Retail');
        // insert d;
    }

    @isTest
    static void TestBatchable(){

        Account b = [SELECT id, Name, Phone, shi_city__c, MasterAccount__c, shi_DefaultAddressPhoneNumber__c FROM Account WHERE SHI_Brand__c = 'Shiseido' AND shi_city__c != null LIMIT 1];
        System.debug('b.shi_city__c - ' + b.shi_city__c);
        System.debug('b - ' + b);

        Account aBe = [SELECT id, Name, Phone, shi_city__c, shi_zone__c, shi_DefaultAddressPhoneNumber__c FROM Account WHERE SHI_Brand__c = 'Shiseido' LIMIT 1];
        System.debug('aBe.shi_city__c - ' + aBe.shi_city__c);
        System.debug('aBe - ' + aBe);

        Case cBe = [SELECT id, AccountId FROM Case WHERE shi_designersbrands__c = 'Shiseido' LIMIT 1];
        System.debug('cBe - ' + cBe);

        // Case dBe = [SELECT id, AccountId FROM Case WHERE shi_designersbrands__c = 'Shiseido' LIMIT 1];
        // System.debug('dBe - ' + dBe);

        Test.startTest();
            Database.executeBatch(new BatchMergeDuplicateAccountAfterCheck());
        Test.stopTest();

        //Insert here some System.assertEquals regarding your Batch execution
        Account a = [SELECT id, Name, Phone, shi_city__c, shi_zone__c, shi_DefaultAddressPhoneNumber__c, (SELECT id FROM Cases) FROM Account WHERE SHI_Brand__c = 'Shiseido' LIMIT 1];
        System.debug('a.shi_city__c - ' + a.shi_city__c);
        System.debug('a - ' + a);

        Case c = [SELECT id, AccountId FROM Case WHERE shi_designersbrands__c = 'Shiseido' LIMIT 1];
        System.debug('c - ' + c);

        // Case d = [SELECT id, AccountId FROM Case WHERE shi_designersbrands__c = 'Shiseido' LIMIT 1];
        // System.debug('d - ' + d);

        System.assertEquals(1, [SELECT count() FROM Account WHERE SHI_Brand__c = 'Shiseido']);
    }

    @isTest
    static void TestSchedulable() {        

        Test.startTest();
            System.schedule('Test Schedule BatchMergeDuplicateAccountAfterCheck', '0 0 0 * * ?', new BatchMergeDuplicateAccountAfterCheck());
        Test.stopTest();
        List<AsyncApexJob> batchJobs = [SELECT Id, Status FROM AsyncApexJob WHERE ApexClass.Name = 'BatchMergeDuplicateAccountAfterCheck' AND JobType = 'BatchApex'];        
        System.assertEquals(1, batchJobs.size(), 'Unexpected number of batch jobs ran: ' + batchJobs);
        System.assertEquals('Queued', batchJobs[0].Status, 'Job planned with an unexpected status.');

    }  
}