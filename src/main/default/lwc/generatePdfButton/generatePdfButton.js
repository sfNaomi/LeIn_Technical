import {LightningElement, api} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {CloseActionScreenEvent} from 'lightning/actions';
import {processError} from 'c/errorHandlingService';
import attachInvoicePDF from '@salesforce/apex/InvoicePDFController.attachPDF';
import attachDeliveryNotePDF from '@salesforce/apex/DeliveryNotePDFController.attachPDF';

export default class GeneratePdfButton extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api isAura;
    showSpinner = false;

    closeModal() {
        if (this.isAura) {
            this.dispatchEvent(new CustomEvent('closeaction'));
        } else {
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }

    async generatePDF() {
        this.showSpinner = true;
        try {
            switch (this.objectApiName) {
                case 'aforza__Invoice__c':
                    await attachInvoicePDF({invoiceId: this.recordId});
                    break;
                case 'Order':
                    await attachDeliveryNotePDF({orderId: this.recordId});
                    break;
                default:
                    break;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'PDF Created Succesfully',
                    variant: 'success'
                })
            );
        } catch (error) {
            processError(error);
        }
        this.closeModal();
    }
}