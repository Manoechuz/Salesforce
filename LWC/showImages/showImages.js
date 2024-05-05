import { LightningElement, wire, api, track } from 'lwc';
import NAME_FIELD from "@salesforce/schema/Product2.Name";
import Img from "@salesforce/schema/Product2.shi_cc_product_img_link__c";
import Img2 from "@salesforce/schema/Product2.shi_cc_product_img2_link__c";
import Img3 from "@salesforce/schema/Product2.shi_cc_product_img3_link__c";
import Img4 from "@salesforce/schema/Product2.shi_cc_product_img4_link__c";
import Img5 from "@salesforce/schema/Product2.shi_cc_product_img5_link__c";
import Img6 from "@salesforce/schema/Product2.shi_cc_product_img6_link__c";
import Img7 from "@salesforce/schema/Product2.shi_cc_product_img7_link__c";
import Img8 from "@salesforce/schema/Product2.shi_cc_product_img8_link__c";
import { getRecord } from 'lightning/uiRecordApi';

export default class ShowImages extends LightningElement {
    @api recordId; // L'ID du record est passé au composant
    @track imgExist = [];
    @track productRecord = {};

    // @wire(getProduct, { recordId: '$recordId' })
    @wire(getRecord, {
        recordId: '$recordId',
        fields: [NAME_FIELD, Img, Img2, Img3, Img4, Img5, Img6, Img7, Img8]
    })
    productRecord1({ error, data }) {

        if (data) {
            this.productRecord = data.fields;

            if (this.productRecord.shi_cc_product_img_link__c.value != null)
                this.imgExist.push(this.productRecord.shi_cc_product_img_link__c.value);

            if (this.productRecord.shi_cc_product_img2_link__c.value != null)
                this.imgExist.push(this.productRecord.shi_cc_product_img2_link__c.value);

            if (this.productRecord.shi_cc_product_img3_link__c.value != null)
                this.imgExist.push(this.productRecord.shi_cc_product_img3_link__c.value);

            if (this.productRecord.shi_cc_product_img4_link__c.value != null)
                this.imgExist.push(this.productRecord.shi_cc_product_img4_link__c.value);

            if (this.productRecord.shi_cc_product_img5_link__c.value != null)
                this.imgExist.push(this.productRecord.shi_cc_product_img5_link__c.value);

            if (this.productRecord.shi_cc_product_img6_link__c.value != null)
                this.imgExist.push(this.productRecord.shi_cc_product_img6_link__c.value);

            if (this.productRecord.shi_cc_product_img7_link__c.value != null)
                this.imgExist.push(this.productRecord.shi_cc_product_img7_link__c.value);

            if (this.productRecord.shi_cc_product_img8_link__c.value != null)
                this.imgExist.push(this.productRecord.shi_cc_product_img8_link__c.value);
        }

        else if (error) {
            console.error('Error fetching data: ', error);
        }
    }

}