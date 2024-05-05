@isTest
public class BatchDispatchCasesToGenUnknownTest {

    @TestSetup
    static void makeData(){

        List<Account> accountsToInsert = new List<Account>{
            new Account(FirstName='Unknown_ZadigVoltaire' , LastName = 'Unknown_French', shi_language__c='FR', SHI_Brand__c='Zadig et Voltaire', IsGenericAccount__c=true, shi_Country__c = 'FR', shi_zone__c = 'EMEA'),
            new Account(FirstName='Unknown_Nars' , LastName = 'Unknown_French', shi_language__c='FR', SHI_Brand__c='NARS', IsGenericAccount__c=true , shi_Country__c = 'FR', shi_zone__c = 'EMEA')
        };
        
        try {
            insert accountsToInsert;
        } catch(DmlException e) {
            System.debug('An error occurred when inserting the accounts: ' + e.getMessage());
        }
        
        List<Account> accList = new List<Account>();

        Account a = Utils.createAccountWithoutInserting('Num', 'NARS', 'unknown@unknown.fr' );
        Account b = Utils.createAccountWithoutInserting('Num', 'Zadig et Voltaire', 'unknown@unknown.fr');

        accList.add(a);
        accList.add(b);

        insert accList;


        List<Case> caseList = new List<Case>();

        for (Integer i = 0; i < 20; i++) {

            Case c = null;

            if(i <= 7){
                Case c1 = Utils.createCaseWithoutInserting(accountsToInsert[0].Id, 'Zadig et Voltaire' , 'SPAM');
                caseList.add(c1);
            }

            if (i >= 5)
                c = Utils.createCaseWithoutInserting(accList[1].Id, 'Zadig et Voltaire' , 'SPAM');
            else{
                c = Utils.createCaseWithoutInserting(accList[0].Id, 'NARS' , 'SPAM');
            }

            c.shi_techCountry__c = 'FR';
            caseList.add(c);
        }

        insert caseList;
        
    }

    @isTest
    static void TestBatchable(){

        Test.startTest();
            Database.executeBatch(new BatchDispatchCasesToGenUnknown());
        Test.stopTest();

        List<Account> accountZadig = [SELECT Id, SHI_Brand__c FROM Account WHERE SHI_Brand__c = 'Zadig et Voltaire' AND isGenericAccount__c = true];
        System.assertEquals(3, accountZadig.size());
    }

    @isTest
    static void TestSchedulable() {        

        Test.startTest();
            System.schedule('Test Schedule BatchDispatchCasesToGenUnknown', '0 0 0 * * ?', new BatchDispatchCasesToGenUnknown());
        Test.stopTest();
        List<AsyncApexJob> batchJobs = [SELECT Id, Status FROM AsyncApexJob WHERE ApexClass.Name = 'BatchDispatchCasesToGenUnknown' AND JobType = 'BatchApex'];        
        System.assertEquals(1, batchJobs.size(), 'Unexpected number of batch jobs ran: ' + batchJobs);
        System.assertEquals('Queued', batchJobs[0].Status, 'Job planned with an unexpected status.');

    }  
}