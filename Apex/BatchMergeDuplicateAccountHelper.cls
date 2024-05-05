/** 
*
* @author: Moshe Uzan
* @since: 10/03/2024
* Last Modified: Moshe Uzan 10/03/2024
*
* @description: This class is a helper class for the BatchMergeDuplicateAccount class. It is used to schedule the BatchMergeDuplicateAccount class to run on a daily basis.
*
*/
global class BatchMergeDuplicateAccountHelper implements Schedulable {

    public String brand;
    public Datetime fromDate;
    public Datetime toDate;

    public BatchMergeDuplicateAccountHelper() {

    }

    public BatchMergeDuplicateAccountHelper(String brand, Datetime fromDate, Datetime toDate) {
        // Constructor
        this.brand = brand;
        this.fromDate = fromDate;
        this.toDate = toDate;
    }

    @ReadOnly   
    global void execute(SchedulableContext ctx){
        
        List<AggregateResult> query;

        if(brand == null && fromDate == null && toDate == null){
            query = [SELECT PersonEmail, SHI_Brand__c, COUNT(Id)
                                        FROM Account 
                                        WHERE PersonEmail != NULL AND IsGenericAccount__c = false 
                                        GROUP BY PersonEmail , SHI_Brand__c 
                                        HAVING COUNT(Id) > 1 LIMIT 50000];
        }
        else{
            query = [SELECT PersonEmail, SHI_Brand__c, COUNT(Id)
                                        FROM Account 
                                        WHERE PersonEmail != NULL AND IsGenericAccount__c = false
                                        AND SHI_Brand__c = :brand AND CreatedDate >= :fromDate AND CreatedDate <= :toDate 
                                        GROUP BY PersonEmail , SHI_Brand__c 
                                        HAVING COUNT(Id) > 1 LIMIT 50000];
        }


        List<String> emails = new List<String>();
        List<String> brands = new List<String>();
        
        
        for(AggregateResult ar : query){

            String email = (String)ar.get('PersonEmail');
            String brand = (String)ar.get('SHI_Brand__c');

            emails.add(email);
            brands.add(brand);
        }

        BatchMergeDuplicateAccount rq = new BatchMergeDuplicateAccount(emails, brands);
        Database.executeBatch(rq, 100);
    }
}