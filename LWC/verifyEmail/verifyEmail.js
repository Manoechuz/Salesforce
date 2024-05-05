import { LightningElement, api } from 'lwc';
import updateVerifiedStatus from '@salesforce/apex/ContactVerificationController.confirmationIsUpdate';


export default class VerifyEmail extends LightningElement {

    @api contactId;
    @api vToken;

    isVerifying = false;
    isVerified = false;
    isError = false;

    isTwo = false;
    isThree = false;
    isFour = false;

    connectedCallback() {
        // Parse the URL to get the contactId and vToken
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        this.contactId = urlParams.get('id');
        this.vToken = urlParams.get('vToken');

        this.resetFlags();
        
        try{
            this.handleVerifyEmail();
            this.isVerifying = true;
        }
        catch(error){
            console.log('error : ', error);
            this.isError = true;
        }
        

    }


    handleVerifyEmail() {

        this.resetFlags();
        this.isVerifying = true;
        
        updateVerifiedStatus({ contactId: this.contactId, vToken: this.vToken })
            .then(result => {
                this.isVerifying = false;

                switch (result) {
                    case '1':
                        this.isVerified = true;
                        break;
                    case '0':
                        this.isError = true;
                        break;
                    case '2':
                        this.isTwo = true;
                        break;
                    case '3':
                        this.isThree = true;
                        break;
                    case '4':
                        this.isFour = true;
                        break;
                    default:
                        this.isError = true;  // Handle unexpected result
                        break;
                }
            })
            .catch(error => {
                console.error('error : ', error);
                this.resetFlags();
                this.isError = true;
            });
    }

    resetFlags() {
        this.isVerifying = false;
        this.isVerified = false;
        this.isError = false;
        this.isTwo = false;
        this.isThree = false;
        this.isFour = false;
    }
}