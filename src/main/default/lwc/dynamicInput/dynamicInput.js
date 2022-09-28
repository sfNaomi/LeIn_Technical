/**
 * Created by svatopluk.sejkora on 20.09.2022.
 */

import {LightningElement, api} from 'lwc';
import {processError} from 'c/errorHandlingService';

export default class DynamicInput extends LightningElement {

    @api fieldDefinition;

    /**
     * Check for Date DisplayType.
     *
     * @returns {boolean} - true for Date
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    get isDate() {
        return this.fieldDefinition.type === 'Date';
    }

    /**
     * Check for Integer or Long DisplayType.
     *
     * @returns {boolean} - true for whole number
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    get isWholeNumber() {
        return this.fieldDefinition.type === 'Integer' || this.fieldDefinition.type === 'Long';
    }

    /**
     * Check for Picklist DisplayType.
     *
     * @returns {boolean} - true for whole number
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    get isCombobox() {
        return this.fieldDefinition.type === 'Picklist';
    }

    /**
     * @description methods to fire an event to parent with changed data. Includes name of the Application object API name
     * and its value.
     *
     * @author Svata Sejkora
     */
    handleSelection(event) {
        try {
            let updatedFieldDefinition = JSON.parse(JSON.stringify(this.fieldDefinition));
            updatedFieldDefinition.value = event.target.value;
            this.sendChangeEvent(updatedFieldDefinition);
        } catch (error) {
            processError(this, error);
        }
    }

    /**
     * Method to fire an event with changed data
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    sendChangeEvent(updatedFieldDefinition) {
        const changedData = new CustomEvent('changeddata', {
            detail: {updatedFieldDefinition: updatedFieldDefinition}
        });
        this.dispatchEvent(changedData);
    }
}