@isTest
public with sharing class ContactVerificationControllerTest {
    @TestSetup
    static void setup() {

        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@vo2-group.com',
            vToken__c = ContactVerificationController.hashPassword('0000000'),
            rToken__c = ContactVerificationController.hashPassword('0000000'),
            emailVerify__c = false,
            Password__c = 'initialPassword'
        );

        insert testContact;
    }

    @isTest
    static void testConfirmationIsUpdate() {

        String vToken = '0000000';

        List<Contact> contacts = [SELECT Id FROM Contact LIMIT 1];
        String contactId = contacts[0].Id;

        Test.startTest();
        String result = ContactVerificationController.confirmationIsUpdate(contactId, vToken);
        String resultTwo = ContactVerificationController.confirmationIsUpdate(contactId, '000001');
        String resultThree = ContactVerificationController.confirmationIsUpdate('00000000', vToken);
        String resultFour = ContactVerificationController.confirmationIsUpdate(contactId, vToken);
        Test.stopTest();

        System.assertEquals('1', result, 'The email verification status should be updated successfully.');
        System.assertEquals('2', resultTwo, 'The Token should not be work successfully.');
        System.assertEquals('4', resultThree, 'The Contact should not be found.');
        System.assertEquals('3', resultFour, 'The email verification status should not be updated.');
    }

    @isTest
    static void testPasswordUpdate() {

        String rToken = '0000000';

        List<Contact> contacts = [SELECT Id FROM Contact LIMIT 1];
        String contactId = contacts[0].Id;

        Test.startTest();
        String result = ContactVerificationController.passwordUpdate(contactId, rToken, 'newPassword');
        String resultTwo = ContactVerificationController.passwordUpdate(contactId, '000001', 'newPassword');
        String resultThree = ContactVerificationController.passwordUpdate('00000000', rToken, 'newPassword');

        Test.stopTest();

        System.assertEquals('1', result, 'The password should be updated successfully.');
        System.assertEquals('2', resultTwo, 'The Token should not be work successfully.');
        System.assertEquals('3', resultThree, 'The Contact should not be found.');
    }
}
