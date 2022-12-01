import {LightningElement, api} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {CloseActionScreenEvent} from 'lightning/actions';
import {processError} from 'c/errorHandlingService';
import attachPdf from '@salesforce/apex/GeneratePdfButtonController.attachPdf';

export default class GeneratePdfButton extends LightningElement {
    @api recordId;
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
            await attachPdf({recordId: this.recordId});
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Document was successfully generated',
                    variant: 'success'
                })
            );
        } catch (error) {
            processError(error);
        }
        this.closeModal();
    }
}