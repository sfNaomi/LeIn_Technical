import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { processError } from 'c/errorHandlingService';
import resetOutletBenchmarkByAccount from '@salesforce/apex/ResetBenchmarkController.resetOutletBenchmarkByAccount';
import ResetBenchmarkModalContent from '@salesforce/label/c.ResetBenchmarkModalContent';
import ConfirmButton from '@salesforce/label/c.ConfirmButton';
import CancelButton from '@salesforce/label/c.CancelButton';

export default class ResetBenchmark extends LightningElement {
    @api recordId;
	@api objectApiName;
	@api isAura;
	showSpinner = false;

    get resetBenchmarkModalContent() {
        return ResetBenchmarkModalContent;
    }
    get confirmButton() {
        return ConfirmButton;
    }
    get cancelButton() {
        return CancelButton
    }

	closeModal() {
		if (this.isAura) {
			this.dispatchEvent(new CustomEvent('closeaction'));
		} else {
			this.dispatchEvent(new CloseActionScreenEvent());
		}
	}

    async resetBenchmarks() {
		this.showSpinner = true;
		try {
			switch (this.objectApiName) {
				case 'Account':
					await resetOutletBenchmarkByAccount({ accountId: this.recordId });
					break;
				default:
					break;
			}
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Success',
					message: 'Benchmark Reset Succesfull',
					variant: 'success'
				})
			);
		} catch (error) {
			processError(error);
		}
		this.closeModal();
	}
}