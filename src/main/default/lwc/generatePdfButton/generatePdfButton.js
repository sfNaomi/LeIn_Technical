import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import attachPDF from '@salesforce/apex/InvoicePDFController.attachPDF';
export default class GeneratePdfButton extends LightningElement {
	@api recordId;
	showSpinner = false;

	closeModal() {
		this.dispatchEvent(new CloseActionScreenEvent());
	}

	generatePDF() {
		this.showSpinner = true;
		attachPDF({ invoiceId: this.recordId })
			.then(() => {
				this.closeModal();
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Success',
						message: 'PDF Created Succesfully',
						variant: 'success'
					})
				);
			})
			.catch((error) => {
				this.closeModal();
				console.log(error);
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Error',
						message: 'Error Generating PDF',
						variant: 'error'
					})
				);
			});
	}
}
