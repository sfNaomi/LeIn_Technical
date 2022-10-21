/**
 * Created by svatopluk.sejkora on 20.09.2022.
 */

import {LightningElement, api, track} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getResults from '@salesforce/apex/DynamicFilterController.getResults';
import filter from '@salesforce/label/c.Filter';
import noRecordsShown from '@salesforce/label/c.NoRecordsShown';
import totalNumberOfRecords from '@salesforce/label/c.TotalNumberOfRecords';
import {replaceStringValues} from 'c/stringOperationsService';
import {processError} from 'c/errorHandlingService';

export default class DynamicFilter extends LightningElement {
    @api filterFields;
    @api queryFields;
    @api sobjectApiName;
    @api toFlatten;
    @api limitOfRowsReturned;
    @api filterSize;
    @api defaultFilter = '';
    @track filterFieldsWithPopulatedFilters = [];
    @track isLoading = false;
    flattenedRecords = [];
    flattenedRecord = {};
    @track returnedDataCount = 0;
    label = {
        filter,
        noRecordsShown
    };

    connectedCallback() {
        // make sure we get any preselected values to the list of populated ones
        this.filterFields.forEach((filterField) => {
            if (filterField.value !== null) {
                this.addFilterValueToList(filterField);
            }
        });
    }

    /**
     * @description method to handle any change on inputs for all child components. Event contains object with all field
     * properties
     *
     * @author Svata Sejkora
     */
    handleChangedData(event) {
        try {
            this.addFilterValueToList(event.detail.updatedFieldDefinition);
        } catch (error) {
            const toastError = new ShowToastEvent({
                title: 'Error',
                message: JSON.stringify(error),
                variant: 'error'
            });
            this.dispatchEvent(toastError);
        }
    }

    /**
     * method to manage filtered fields (field names) and their values based on the index of the filter fields
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    addFilterValueToList(filterValueObject) {
        const filterValuePopulatedIndex = this.filterFieldsWithPopulatedFilters.findIndex(obj => {
            return obj.index === filterValueObject.index;
        })
        if ((filterValueObject.value === '' || filterValueObject.value === null) && filterValuePopulatedIndex !== -1) {
            this.filterFieldsWithPopulatedFilters.splice(filterValuePopulatedIndex, 1);
        }
        else if (filterValuePopulatedIndex !== -1) {
            this.filterFieldsWithPopulatedFilters[filterValuePopulatedIndex].value = filterValueObject.value;
        } else {
            this.filterFieldsWithPopulatedFilters.push(filterValueObject);
        }
    }

    /**
     * Method that handles filter click. calls apex and determine if returned data needs to be flattened, if so it
     * will call necessary methods.
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    @api async handleFilterClick() {
        try {
            this.isLoading = true;
            this.flattenedRecords = [];
            const returnedData = await getResults({
                'sObjectName': this.sobjectApiName,
                'returnFields': this.queryFields,
                'queryFields': JSON.stringify(this.filterFieldsWithPopulatedFilters),
                'limit': this.limitOfRowsReturned
            });
            if (this.toFlatten) {
                this.flattenReturnedData(returnedData);
                this.returnedDataCount = returnedData.length;
                this.sendDataEvent(this.flattenedRecords);
            } else {
                this.sendDataEvent(returnedData);
            }
        } catch (error) {
            processError(this, error);
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Sends event with data up to parent component
     *
     * @param returnedData - object with returned data
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    sendDataEvent(returnedData) {
        const returnedDataEvent = new CustomEvent('returneddata', {
            detail: {returnedData: returnedData, totalNumberOfRows: returnedData.length}
        });
        this.dispatchEvent(returnedDataEvent);
    }

    /**
     * method to iterate over items returned from apex. For each record it will call flattening method. Will update
     * class level list of flattened data nad empties flattened record.
     *
     * @param returnedData set of all data to be flattened
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    flattenReturnedData(returnedData) {
        for (let i = 0; i < returnedData.length; i++) {
            let record = returnedData[i];
            this.flattenData([{'record': record, 'levelPath': ''}]);
            this.flattenedRecords.push(this.flattenedRecord);
            this.flattenedRecord = {};
        }
    }

    /**
     * Recursive method to flatten the data.
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    flattenData(objectArray) {
        let objectHolder = [];
        objectArray.forEach(object => {
            const activeRecord = object.record;
            let levelPath = object.levelPath;
            for (let i = 0; i < Object.keys(activeRecord).length; i++) {
                const property = Object.keys(activeRecord)[i];
                if (typeof activeRecord[property] === 'object') {
                    objectHolder.push({'record': activeRecord[property], 'levelPath': levelPath + property});
                } else {
                    this.flattenedRecord[levelPath + property] = activeRecord[property];
                }
            }
        });
        if (objectHolder.length > 0) {
            this.flattenData(objectHolder);
        }
    }

    /**
     * Checks if there are records with filters
     *
     * @returns {boolean} - true when there is o records => disables filter field
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    get isFilterActive() {
        return Boolean(this.filterFieldsWithPopulatedFilters.length === 0);
    }

    /**
     * Check for number of returned data
     *
     * @returns {boolean} - true when there is at least 1 returned data.
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    get showDataCount() {
        return Boolean(this.returnedDataCount > 0);
    }

    /**
     * gets string to show on page with replaced dynamic values
     *
     * @returns string with replaced values
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    get totalNumberOfRecordsText() {
        const regex = /#([^#]+)#/g;
        const replacingValues = {0: this.returnedDataCount};
        return replaceStringValues(totalNumberOfRecords, regex, replacingValues);
    }
}