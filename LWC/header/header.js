import { LightningElement, wire, track } from 'lwc';
import { subscribe, MessageContext } from 'lightning/messageService';
import FOOTER_CHANNEL from '@salesforce/messageChannel/Footer__c';
import Vo2_IMAGE from '@salesforce/resourceUrl/LogoVo2';

export default class Header extends LightningElement {

    subscription = null;
    isClicked = false;
    imageUrl = Vo2_IMAGE;

    @track isZoomed = true;

    @wire(MessageContext)
    messageContext;

    subscribeToMessageChannel() {
        this.subscription = subscribe(
          this.messageContext,
          FOOTER_CHANNEL,
          (message) => this.handleMessage(message)
        );
      }
    
    handleMessage(message) {
        console.log('message received');
        this.isZoomed = message.isClicked;
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    get zoomClass() {
        return this.isZoomed ? 'zoom-in' : 'zoom-out';
    }
}