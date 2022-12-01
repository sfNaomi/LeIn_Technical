/**
 * Created by magdalena.stanciu on 22.11.2022.
 */

import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

import {processError} from 'c/errorHandlingService';

import performRecalculation from '@salesforce/apex/OrderRecalculationWidgetController.performRecalculation';

import orderRecalculation from '@salesforce/label/c.OrderRecalculation';
import chooseOrderRecalculationOption from '@salesforce/label/c.ChooseOrderRecalculationOption';
import zeroOutAmountAndVAT from '@salesforce/label/c.ZeroOutAmountAndVAT';
import productReturnAndRefund from '@salesforce/label/c.productReturnAndRefund';
import recalculate from '@salesforce/label/c.Recalculate';
import recalculationCompleted from '@salesforce/label/c.RecalculationCompleted';

export default class OrderUpdatesScreen extends LightningElement {
    labels = {
        orderRecalculation,
        chooseOrderRecalculationOption,
        zeroOutAmountAndVAT,
        productReturnAndRefund,
        recalculate,
        recalculationCompleted
    }

    options = [
        { label: this.labels.zeroOutAmountAndVAT, value: 'ZERO_OUT_AMOUNT_VAT' },
        { label: this.labels.productReturnAndRefund, value: 'PRODUCT_RETURN_REFUND' },
    ]

    @api recordId;
    selectedOption;
    isLoading = false;

    /** Method to save selected option
     *
     * @author Magdalena Stanciu
     * @date 2022-11-23
     */
    handleOptionChange(event) {
        this.selectedOption = event.detail.value;
    }

    /** Method to perform recalculation on order based on selected option
     *
     * @author Magdalena Stanciu
     * @date 2022-11-23
     */
    async recalculate() {
        this.isLoading = true;
        try {
            await performRecalculation({orderId: this.recordId, selectedOption: this.selectedOption});
            this.showToast(this.labels.recalculationCompleted, 'Success');
            getRecordNotifyChange([{recordId: this.recordId}]);
        } catch (error) {
            processError(this, error);
        } finally {
            this.isLoading = false;
        }
    }

    /** Method to display toast with given variant and message
     *
     * @author Magdalena Stanciu
     * @date 2022-11-23
     */
    showToast(message, variant) {
        const toastSuccess = new ShowToastEvent({
            message: message,
            variant: variant
        });
        this.dispatchEvent(toastSuccess);
    }
}