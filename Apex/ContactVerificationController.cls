public without sharing class ContactVerificationController {
    @AuraEnabled
    public static String emailConfirmation(String contactId, String vToken) {

        Map<String, Object> response = new Map<String, Object>();

        List<Contact> contacts = [SELECT Id, vToken__c, emailVerify__c FROM Contact WHERE Id = :contactId LIMIT 1];

        if (contacts.size() > 0 && contacts[0].vToken__c == hashPassword(vToken) && !contacts[0].emailVerify__c) {

            Contact contact = contacts[0];

            contact.emailVerify__c = true;
            Database.SaveResult s = Database.update(contact);

            if(!s.isSuccess()){
                String errorMsg = '';
                for(Database.Error err : s.getErrors()){
                    errorMsg += err.getMessage() + '; ';
                }
                response.put('status', 0);
                response.put('isSuccess', false);
                response.put('message', 'Update failed: ' + errorMsg);
            }
            else{
                response.put('status', 1);
                response.put('isSuccess', true);
                response.put('message', 'Email verification successful.');
            }

            return JSON.serialize(response);

        }

        else if (contacts.size() == 0) {
            response.put('status', 4);
            response.put('isSuccess', false);
            response.put('message', 'No contact found with the given ID.');
        }
        else if(contacts[0].vToken__c != hashPassword(vToken)){
            response.put('status', 2);
            response.put('isSuccess', false);
            response.put('message', 'Verification token mismatch.');
        }
        else if (contacts[0].emailVerify__c == true) {
            response.put('status', 3);
            response.put('isSuccess', false);
            response.put('message', 'Email already verified.');
        }
        return JSON.serialize(response);
    }


    @AuraEnabled
    public static String passwordUpdate(String contactId, String rToken, String newPassword) {

        Map<String, Object> response = new Map<String, Object>();

        List<Contact> contacts = [SELECT Id, rToken__c, Password__c FROM Contact WHERE Id = :contactId LIMIT 1];

        if (contacts.size() == 1 && contacts[0].rToken__c == hashPassword(rToken)) {
            Contact contact = contacts[0];
            contact.Password__c = hashPassword(newPassword);

            Database.SaveResult s = Database.update(contact);
            if(!s.isSuccess()){
                String errorMsg = '';
                for(Database.Error e : s.getErrors()){
                    System.debug('The error is ' + e.getMessage());
                }
                response.put('status', 0);
                response.put('isSuccess', false);
                response.put('message', 'Update failed: ' + errorMsg);
            }
            else{
                response.put('status', 1);
                response.put('isSuccess', true);
                response.put('message', 'Password reset successfully !');
            }
            return JSON.serialize(response);
        }
        
        else if (contacts.size() == 0) {
            response.put('status', 3);
            response.put('isSuccess', false);
            response.put('message', 'Contact not registered to Salesforce.');
        }
        else if(contacts[0].rToken__c != hashPassword(rToken)){
            response.put('status', 2);
            response.put('isSuccess', false);
            response.put('message', 'Verification token mismatch.');
        }

        return JSON.serialize(response);
    }

    public static String hashPassword(String password) {

        Blob passwordBlob = Blob.valueOf(password);
        Blob hashedPassword = Crypto.generateDigest('SHA-256', passwordBlob);
        return EncodingUtil.base64Encode(hashedPassword);

    }
}
