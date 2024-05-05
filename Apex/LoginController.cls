//Used by Flutter Hour App
@RestResource(urlMapping='/login/*')
global with sharing class LoginController {
    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request; 
        RestResponse res = RestContext.response;

        // Get the body of the request
        String jsonString = req.requestBody.toString();
        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        Map<String, String> funcRes = new Map<String, String>();

        if (req.requestURI == '/login') {
            // Login
            String email = (String) data.get('email');
            String password = (String) data.get('password');
            String fcmToken = (String) data.get('fcmToken');
            funcRes = login(email, password, fcmToken);
        } else if (req.requestURI == '/login/signup') {
            // Signup
            String email = (String) data.get('email');
            String password = (String) data.get('password');
            String fcmToken = (String) data.get('fcmToken');

            funcRes = signup(email, password, fcmToken);
        } else {
            res.statusCode = 404;
            res.responseBody = Blob.valueOf('{"error": "Not found"}');
            return;
        }

        res.statusCode = Integer.valueOf(funcRes.get('statusCode'));
        res.responseBody = Blob.valueOf(funcRes.get('body'));
    }

    @HttpPatch
    global static void doPatch() {
        RestRequest req = RestContext.request; 
        RestResponse res = RestContext.response;

        // Get the body of the request
        String jsonString = req.requestBody.toString();
        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        Map<String, String> funcRes = new Map<String, String>();

        if (req.requestURI == '/login/reset-password') {
            // Login
            String email = (String) data.get('email');

            funcRes = resetPassword(email);
        } else {
            res.statusCode = 404;
            res.responseBody = Blob.valueOf('{"error": "Not found"}');
            return;
        }

        res.statusCode = Integer.valueOf(funcRes.get('statusCode'));
        res.responseBody = Blob.valueOf(funcRes.get('body'));
    }

    /**
     * Signup method.
     * Returns a JSON response with the status code and the user ID if the signup is successful.
     * If the signup fails, it returns a JSON response with the status code and an error message.
     * 
     * @param {String} username
     * @param {String} password
     * 
     * @return {String} JSON response
     * @property {String} statusCode
     * @property {String} userId
     * @property {String} errorMessage
     */
    public static Map<String, String> signup(String email, String password, String fcmToken) {
        if (String.isBlank(email)) { return errorMessage('400', 'Username is required', 1); }
        if (String.isBlank(password)) { return errorMessage('400', 'Password is required', 2); }
        
        List<Contact> contact = [SELECT Id, Email, FCMToken__c, vToken__c FROM Contact WHERE Email =: email];
        //if a FCMToken is already registered, it means the user already sign up
        if (contact.size() > 0 && contact[0].FCMToken__c != null) { return errorMessage('400', 'User already exists', 3); }
        if(contact.size() > 0 && contact[0].FCMToken__c == null){
            contact[0].FCMToken__c = fcmToken;
            contact[0].Password__c = hashPassword(password);
            update contact[0];
            return successMessage('200', Id.valueOf(contact[0].Id));
        }
        else if(contact.size() == 0){
            Contact c = new Contact();
            c.Email = email;
            c.Password__c = hashPassword(password);

            // Generate a random verification token (6 digits)
            String vToken = String.valueOf((100000 + (Integer) Math.floor(Math.random() * 900000)));

            c.vToken__c = hashPassword(vToken);


            if (c.email.endsWith('@vo2-group.com')) {
                c.LastName = email.substringBefore('@').substringAfter('.').capitalize();
                c.FirstName = email.substringBefore('@').substringBefore('.').capitalize();
            } else {
                c.LastName = 'User Last Name - ' + email.substringBefore('@');
                c.FirstName = 'User First Name';
            }
            
            try {
                insert c;

                verifyEmail(c.Id, c.Email, vToken);

                return successMessage('201', c.Id);
            } catch (Exception e) {
                System.debug(e);
                return errorMessage('500', 'Failed to create the user' + e.getStackTraceString() + e.getMessage(), 999);
            }
        }else{
            return errorMessage('500', 'Failed to create the user', 999);
        }

    }

    /**
     * Sends an email to the user with a verification link.
     * 
     * @param {Id} contactId
     * @param {String} email
     */
    private static void verifyEmail(Id contactId, String email, String vToken) {

        // // Reserve a single email capacity
        // Messaging.reserveSingleEmailCapacity(1);

        List<Site> s = [SELECT Id FROM Site WHERE UrlPathPrefix = 'hourapp' LIMIT 1];
        
        List<SiteDetail> sd = new List<SiteDetail>();
        if(s.size() > 0)
           sd = [SELECT SecureUrl FROM SiteDetail WHERE DurableId = :s[0].Id LIMIT 1];
        
        String baseUrl = '';

        if(sd.size() > 0){
            baseUrl = sd[0].SecureUrl;
        }

        String verificationLink = baseUrl + '/verifyemail' + '?id=' + contactId + '&vToken=' + vToken;

        String emailBody = 'Please verify your email address by clicking the link below. \n' + verificationLink;

        String emailSubject = 'Verify your email address - VO2 Hour App';

        sendEmail(email, emailSubject, emailBody);
    }

    /**
     * Sends an email to the user with a verification link.
     * 
     * @param {Id} contactId
     * @param {String} email
     */

    private static Map<String,String> sendEmail(String email, String subject, String body) {

        // Reserve a single email capacity
        Messaging.reserveSingleEmailCapacity(1);

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{email});
        mail.setSubject(subject);
        mail.setPlainTextBody(body);

        // Set the Organization-Wide Email Address ID;
        // Query for the Organization-Wide Email Address with the same email as the current user
        List<OrgWideEmailAddress> owea = [
            SELECT Id, Address
            FROM OrgWideEmailAddress
            WHERE Address = 'yehiel.zafrany@vo2-group.com' LIMIT 1
        ];

        if(owea.size() == 0) {
            System.debug('Error - baseUrl, sd or owea is empty');
            return errorMessage('500', 'Failed to send the email', 999);
        }
        
        Id oweaId = owea[0].Id;
        // Id oweaId = '0D2N2000000MxvtKAC';
        // for(OrgWideEmailAddress o : owea){
        //     if(!o.Address.endsWith('@vo2-group.com')){
        //         oweaId = o.Id;
        //         break;
        //     }
        // }

        mail.setOrgWideEmailAddressId(oweaId);
        // To use a custom signature, set the UseSignature property to true and specify the name of the custom signature.
        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
            return successMessage('200', 'Email sent');
        } 
        catch (Exception e) {
            System.debug('Email exception: ' + e);
            return errorMessage('500', 'Failed to send the email', 999);
        }
    }


    /**
     * Login method. 
     * Returns a JSON response with the status code and the user ID if the login is successful.
     * If the login fails, it returns a JSON response with the status code and an error message.
     * 
     * @param {String} username
     * @param {String} password
     * 
     * @return {String} JSON response
     * @property {String} statusCode
     * @property {String} userId
     * @property {String} errorMessage
     */
    private static Map<String, String> login(String email, String password, String fcmToken) {
        System.debug('email - ' + email);
        if (String.isBlank(email)) { return errorMessage('400', 'Username is required', 1); }
        if (String.isBlank(password)) { return errorMessage('400', 'Password is required', 2); }
        
        List<Contact> contact = [SELECT Id, Email, Password__c, FCMToken__c FROM Contact WHERE Email =: email];

        if (contact.size() == 0) { return errorMessage('400', 'User not found', 4); } 
        if (contact.size() > 1) { return errorMessage('400', 'Multiple users found', 5); }
        if (contact[0].Password__c != hashPassword(password)) { return errorMessage('400', 'Invalid password', 6); }
        System.debug('contact[0].fcmtoken__c - ' + contact[0].fcmtoken__c);
        System.debug('fcmtoken - ' + fcmtoken);
        if(fcmToken != null && contact[0].FCMToken__c != fcmToken){
            contact[0].FCMToken__c = fcmToken;
            update contact;
        }
        return successMessage('200', Id.valueOf(contact[0].Id));
    }

    /**
     * Resets the password for the user.
     * Returns a JSON response with the status code and the user ID if the reset is successful.
     * If the reset fails, it returns a JSON response with the status code and an error message.
     * 
     * @param {String} username
     * 
     * @return {String} JSON response
     * @property {String} statusCode
     * @property {String} userId
     * @property {String} errorMessage
     */
    public static Map<String, String> resetPassword(String email) {
        System.debug('email - ' + email);
        if (String.isBlank(email)) { return errorMessage('400', 'Email is required', 6); }
        
        Map<String, String> res = new Map<String, String>();
        List<Contact> contact = [SELECT Id, Email, rToken__c FROM Contact WHERE Email =: email];
        System.debug('contact - ' + contact);

        if (contact.size() == 0) { return errorMessage('400', 'User not found', 4); } 
        if (contact.size() > 1) { return errorMessage('400', 'Multiple users found', 5); }

        // Generate a random verification token (6 digits)
        String rToken = String.valueOf((100000 + (Integer) Math.floor(Math.random() * 900000)));

        contact[0].rToken__c = hashPassword(rToken);

        try{
            update contact[0];
            return sendResetPasswordEmail(contact[0].Id, contact[0].Email, rToken);
        }
        catch(Exception e){
            return errorMessage('500', 'Failed to reset the password', 999);
        }

    }

    /**
     * Sends an email to the user with a new password.
     * 
     * @param {Id} contactId
     * @param {String} email
     * 
     * @return {String} JSON response
     * @property {String} statusCode
     * @property {String} userId
     * @property {String} errorMessage
     */
    private static Map<String, String> sendResetPasswordEmail(Id contactId, String email, String rToken) {

        List<Site> s = [SELECT Id FROM Site WHERE UrlPathPrefix = 'hourapp' LIMIT 1];
        
        List<SiteDetail> sd = new List<SiteDetail>();
        if(s.size() > 0){
            sd = [SELECT SecureUrl FROM SiteDetail WHERE DurableId = :s[0].Id LIMIT 1];
        }
           
        
        String baseUrl = '';

        if(sd.size() == 1){
            baseUrl = sd[0].SecureUrl;
        }
        else{
            return errorMessage('500', 'Failed to send the email', 999);
        }

        String verificationLink = baseUrl + '/reset-password' + '?id=' + contactId + '&rToken=' + rToken;
        String emailBody = 'Please reset your password by clicking the link below. \n' + verificationLink;
        String emailSubject = 'Reset password - VO2 Hour App';
        
        return sendEmail(email, emailSubject, emailBody);
    }
    
    /**
     * Updates the password for the user.
     * 
     * @param {String} contactId
     * @param {String} password
     */
    private static void updatePasswordById(String contactId, String password) {
        Contact c = [SELECT Id, Password__c FROM Contact WHERE Id =: contactId];
        c.Password__c = hashPassword(password);
        update c;
    }

    /**
     * Returns a JSON response with the status code and an error message.
     * 
     * @param {String} statusCode
     * @param {String} errorMessage
     * 
     * @return {String} JSON response
     * @property {String} statusCode
     * @property {String} errorMessage
     */
    private static Map<String, String> errorMessage(String statusCode, String message, Integer errorCode) {
        Map<String, String> res = new Map<String, String>();
        res.put('statusCode', statusCode);

        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeBooleanField('success', false);
        gen.writeStringField('error', message);
        gen.writeNumberField('errorCode', errorCode);
        gen.writeEndObject();
        res.put('body', gen.getAsString());

        return res;
    }

    /**
     * Returns a JSON response with the status code and an error message.
     * 
     * @param {String} userId
     * 
     * @return {String} JSON response
     * @property {String} statusCode
     * @property {String} userId
     */
    private static Map<String, String> successMessage(String statusCode, String userId) {
        Map<String, String> res = new Map<String, String>();
        res.put('statusCode', statusCode);

        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeBooleanField('success', true);
        gen.writeStringField('contactId', userId);
        gen.writeEndObject();
        res.put('body', gen.getAsString());

        return res;
    }

    /**
     * Hashes the password using SHA-256.
     * 
     * @param {String} password
     * 
     * @return {String} hashed password
     */
    private static String hashPassword(String password) {
        Blob passwordBlob = Blob.valueOf(password);
        Blob hashedPassword = Crypto.generateDigest('SHA-256', passwordBlob);
        return EncodingUtil.base64Encode(hashedPassword);    
    }
}