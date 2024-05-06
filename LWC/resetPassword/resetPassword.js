import { LightningElement, api, wire } from 'lwc';
import passwordUpdate from '@salesforce/apex/ContactVerificationController.passwordUpdate';
import { publish, MessageContext } from 'lightning/messageService';
import FOOTER_CHANNEL from '@salesforce/messageChannel/Footer__c';

export default class ResetPassword extends LightningElement {

    @api contactId;
    @api rToken;
    @api msgToDisplay = ''; // Message that will display the result

    newPassword = ''; // current new password entered by the user
    confirmPassword = ''; // current confirm password entered by the user

    isResetting = false; // Flag to show spinner
    isError = false; // Flag to show error message
    isHome = true; // Flag to show home form
    passwordsNotMatch = false; // Flag to show error message
    passwordIsMatch = false; // Flag to show password match message
    passwordFormat = false; // Flag to show password format message
    passwordIsFormat = false; // Flag to show password format message

    cantRun = false; // flag to show message
    firstTime = true; // flag to show message

    isClicked = true;


    @wire(MessageContext)
    messageContext;
   

    connectedCallback() {
        // Parse the URL to get the contactId and vToken
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        
        this.contactId = urlParams.get('id');
        this.rToken = urlParams.get('rToken');

        this.resetFlags(true);
    }

    checkPassword() {
        if(this.newPassword !== '' || this.confirmPassword !== '') {
            if(this.newPassword !== this.confirmPassword) {
                this.passwordsNotMatch = true;
                this.passwordsIsMatch = false;
            }
            else {
                this.passwordsIsMatch = true;
                this.passwordsNotMatch = false;
            }
        }
        
        if(!this.firstTime){
            if(this.newPassword.length >= 4 || this.confirmPassword.length >= 4) {
                this.passwordIsFormat = true;
                this.passwordFormat = false;
            }
            else {
                this.passwordFormat = true;
                this.passwordIsFormat = false;
            }
        }
        else{
            this.firstTime = false;
        }
    }

    handleNewPasswordChange(event) {
        this.newPassword = event.target.value;
        this.checkPassword();
    }


    handleConfirmPasswordChange(event) {
        this.confirmPassword = event.target.value;
        this.checkPassword();
    }

    canRun() {
        return this.newPassword.length >= 4 && this.confirmPassword.length >= 4 && this.newPassword === this.confirmPassword;
    }

    handleResetPassword() {

        this.isClicked = !this.isClicked;
        const payload = { 
            isClicked: this.isClicked
        };
        publish(this.messageContext, FOOTER_CHANNEL, payload);

        if(!this.canRun()) {
            this.cantRun = true;
            return;
        }

        this.resetFlags(false);
        this.isResetting = true;
        
        passwordUpdate({contactId: this.contactId, rToken: this.rToken, newPassword: this.newPassword})
        .then(result => {

            this.isResetting = false;
            
            let response = JSON.parse(result);
            this.msgToDisplay = response.message;
        })
        .catch(error => {
            console.log('error : ', error);
            this.resetFlags(false);
            this.isError = true;
        });
    }

    handleResetButton() {
        this.newPassword = '';
        this.confirmPassword = '';
        this.resetFlags(true);
    }


    resetFlags(check) {

        this.isHome = check;
        this.firstTime = check;

        this.isResetting = false;
        this.isError = false;
        this.passwordsNotMatch = false;
        this.passwordsIsMatch = false;
        this.passwordFormat = false;
        this.cantRun = false;
        this.isClicked = true;
        this.passwordIsFormat = false;
    }

}
