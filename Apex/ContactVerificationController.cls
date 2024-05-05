public without sharing class ContactVerificationController {
    @AuraEnabled
    public static String confirmationIsUpdate(String contactId, String vToken) {

        String result = '0';
        List<Contact> contacts = [SELECT Id, vToken__c, emailVerify__c FROM Contact WHERE Id = :contactId LIMIT 1];

        if (contacts.size() > 0 && contacts[0].vToken__c == hashPassword(vToken) && contacts[0].emailVerify__c == false) {
            contacts[0].emailVerify__c = true;
            Database.SaveResult s = Database.update(contacts[0]);

            if(!s.isSuccess()){
                result = '0';
                for(Database.Error e : s.getErrors()){
                    System.debug('The error is ' + e.getMessage());
                }
            }
            else{
                result = '1';
            }

            return result;
        }

        else if (contacts.size() == 0) {
            result = '4';
        }
        else if(contacts[0].vToken__c != hashPassword(vToken)){
            result = '2';
        }
        else if (contacts[0].emailVerify__c == true) {
            result = '3';
        }
        return result;
    }


    @AuraEnabled
    public static String passwordUpdate(String contactId, String rToken, String newPassword) {

        String result = '0';
        List<Contact> contacts = [SELECT Id, rToken__c, Password__c FROM Contact WHERE Id = :contactId LIMIT 1];

        if (contacts.size() == 1 && contacts[0].rToken__c == hashPassword(rToken)) {
            contacts[0].Password__c = hashPassword(newPassword);

            Database.SaveResult s = Database.update(contacts[0]);
            if(!s.isSuccess()){
                result = '0';
                for(Database.Error e : s.getErrors()){
                    System.debug('The error is ' + e.getMessage());
                }
            }
            else{
                result = '1';
            }

            return result;
        }
        
        else if (contacts.size() == 0) {
            result = '3';
        }
        else if(contacts[0].rToken__c != hashPassword(rToken)){
            result = '2';
        }

        return result;
    }

    public static String hashPassword(String password) {

        Blob passwordBlob = Blob.valueOf(password);
        Blob hashedPassword = Crypto.generateDigest('SHA-256', passwordBlob);
        return EncodingUtil.base64Encode(hashedPassword);

    }
}