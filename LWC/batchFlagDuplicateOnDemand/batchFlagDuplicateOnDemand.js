import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import BrandOptions from '@salesforce/apex/BatchStarter.getBrand';
import startMyBatch from '@salesforce/apex/BatchStarter.startMyBatchFlag';

export default class BatchMergeDuplicateAccountOnDemand extends LightningElement {

    
    @track currBrand = null;
    @track toDate = null;
    @track fromDate = null;
    @track isLoading = false;
    @track batchId;

    @wire(BrandOptions)
    options;

    handleComboChange(event) {
        this.currBrand = event.detail.value;
    }

    handleFlagDuplicateAccounts(){
        this.isLoading = true;
        if(this.currBrand === null){
            const event = new ShowToastEvent({
                title: 'Select Brand',
                message: 'Please select a brand to start the batch',
                variant: 'warning',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
            this.isLoading = false;
            return;
        }


        let dateTimeFromDate = null;
        let dateTimeToDate = null;

        if(this.fromDate != null){
            dateTimeFromDate = new Date(this.fromDate).toISOString();
        }

        if(this.toDate != null){
            dateTimeToDate = new Date(this.toDate).toISOString();
        }

        startMyBatch({brand: this.currBrand, fromDate: dateTimeFromDate, toDate: dateTimeToDate})
            .then(result => {
                this.batchId = result;
                // Handle success - e.g., show a success message
                const event = new ShowToastEvent({
                    title: 'Success',
                    message: 'Batch started successfully',
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);

                console.log(`Batch started: ${this.batchId}`);
                this.isLoading = false;
            })
            .catch(error => {
                // Handle errors
                const event = new ShowToastEvent({
                    title: 'Error',
                    message: 'Error starting batch. Please try again.',
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
                console.error('Error starting batch:', error);
                this.isLoading = false;
            });

        this.currBrand = null;
        this.fromDate = null;
        this.toDate = null;
    }

    setFromToday() {
        const today = new Date().toISOString().slice(0, 10); // Get today's date in YYYY-MM-DD format
        this.fromDate = today;
    }

    setToToday() {
        const today = new Date().toISOString().slice(0, 10); // Get today's date in YYYY-MM-DD format
        this.toDate = today;
    }

    handleToDateChange(event){
        this.toDate = event.detail.value;
    }

    handleFromDateChange(event){
        this.fromDate = event.detail.value;
    }
    
}