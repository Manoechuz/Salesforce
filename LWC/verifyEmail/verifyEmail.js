import { LightningElement, api } from 'lwc';
import updateVerifiedStatus from '@salesforce/apex/ContactVerificationController.emailConfirmation';


export default class VerifyEmail extends LightningElement {

    @api contactId;
    @api vToken;
    @api msgToDisplay = '';

    isVerifying = false;
    isError = false;

    connectedCallback() {

        // Parse the URL to get the contactId and vToken
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        this.contactId = urlParams.get('id');
        this.vToken = urlParams.get('vToken');

        try{
            this.handleVerifyEmail();
        }
        catch(error){
            console.log('error : ', error);
            this.isError = true;
        }
    }

    handleVerifyEmail() {

        this.isError = false;
        this.isVerifying = true;
        
        
        updateVerifiedStatus({ contactId: this.contactId, vToken: this.vToken })
            .then(result => {
                this.isVerifying = false;
                let response = JSON.parse(result);
                this.msgToDisplay = response.message;
            })
            .catch(error => {
                console.error('error : ', error);
                this.isVerifying = false;
                this.isError = true;
            });
    }
}
