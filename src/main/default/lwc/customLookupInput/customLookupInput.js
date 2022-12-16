/*
 * Component that mimics lightning input for lookup and allows more customizations
 *
 * parameters :
 *      objectName - API name of lookup SObject
 *      returnFields - fields which are selected and displayed in result row as detail - default Name
 *      queryFields - fields in which is provided text searched separated with OR - default Name
 *      filter - where condition in String format (eg. Name = 'Test')
 *      label - input label
 *      placeholder - text placeholder when no text is written in input
 *      variant - label-hidden or standard - default standard
 *      disabled - true/false - disables input
 *      selectRecordId - default input value
 *      dropdownLength - maximum number of records to show in the dropdown before scrolling
 *
 * @author  Svatopluk Sejkora, BearingPoint
 * @date    2020-04-03
 */
import {LightningElement, api, track} from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';
import {loadStyle} from 'lightning/platformResourceLoader';
import lwcStyles from '@salesforce/resourceUrl/lwcStyles';

import getInitRecord from '@salesforce/apex/CustomLookupInputController.getInitRecord';
import getRecentlyViewed from '@salesforce/apex/CustomLookupInputController.getRecentlyViewed';
import getResults from '@salesforce/apex/CustomLookupInputController.getResults';

import completeThisFieldLabel from '@salesforce/label/c.CompleteThisField';
import noRecordFoundLabel from '@salesforce/label/c.NoRecordFound';

export default class CustomLookupInput extends LightningElement {

    _hasRendered = false;
    labels = {
        completeThisFieldLabel,
        noRecordFoundLabel
    };

    @api objectName;
    @api returnFields = ['Name'];
    @api queryFields = ['Name'];
    @api mainField = 'Name';
    @api returnDifferentObjectId;
    @api fieldName;
    @api label;
    @api required;
    @api iconName;
    @api disabled;
    @api placeholder;
    @api variant = 'label-stacked';
    @api selectRecordName;
    @api searchRecords = [];
    @api dropdownLength;
    @api
    get maxResults() {
        return typeof this._maxResults === 'number' ? this._maxResults : 0;
    }

    set maxResults(value) {
        this._maxResults = value;
    }
    _maxResults;
    _filter = '';
    @api
    get filter() {
        return this._filter;
    }

    set filter(value) {
        if (this._filter !== value) {
            this._filter = value;
            if (!this._selectRecordId && this._hasRendered) {
                this._recentlySelectedCache = null;
                this.searchRecords = [];
                this.getRecentlyViewedRecords();
            }
        }
    }

    _selectRecordId;
    @api
    get selectRecordId() {
        return this._selectRecordId;
    }

    set selectRecordId(value) {
        if (this._selectRecordId && !value) {
            this.selectRecordName = undefined;
            this.currentSearchedText = undefined;
            this.searchRecords = [];
            this.loadingFlag = false;
            this.inputReadOnly = false;
            this.iconFlag = true;
            this.clearIconFlag = false;
        }
        this._selectRecordId = value;
        this.initRecord();
    }

    @track comboboxClasses = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    @track currentSearchedText;
    @track iconFlag = true;
    @track clearIconFlag = false;
    @track loadingFlag = false;
    @track messageFlag = false;
    @track inputReadOnly = false;
    @track openModal = false;
    @track blurTimeout;
    @track hasError;
    _recentlySelectedCache;

    @api checkValidity() {
        if (this.disabled) {
            return true;
        }
        const input = this.template.querySelector('lightning-input');
        this.checkIsNotFilledWhenRequired();
        input.reportValidity();
        return input.checkValidity();
    }

    @api reportValidity() {
        this.checkIsNotFilledWhenRequired();
        setTimeout(() => {
            const input = this.template.querySelector('lightning-input');
            //To rerender input;
            input.reportValidity();
        }, 0);
    }

    checkIsNotFilledWhenRequired() {
        const input = this.template.querySelector('lightning-input');
        if (!input) {
            return false;
        }
        if (this.required && this._selectRecordId !== undefined && !this._selectRecordId) {
            input.setCustomValidity(this.labels.completeThisFieldLabel);
            this.hasError = true;
        } else {
            input.setCustomValidity('');
            this.hasError = false;
        }
    }

    /*
     * Rendered callback - loads styles and default record if selectRecordId is provided
     *
     * @author  Svatopluk Sejkora, BearingPoint
     * @date    2022-10-08
     */
    async renderedCallback() {
        try {
            if (!this._hasRendered) {
                this._hasRendered = true;
                await loadStyle(this, lwcStyles + '/customLookupInput.css');

                if (!this._selectRecordId) {
                    await this.getRecentlyViewedRecords();
                }
            }
        } catch (error) {
            console.error(error);
        }
    }

    async initRecord() {
        try {
            if (this.selectRecordId) {
                const initRecord = await getInitRecord({
                    recordId: this.selectRecordId,
                    sObjectName: this.objectName,
                    mainField: this.mainField
                });
                if (this.selectRecordId && initRecord) {
                    this.selectRecordName = initRecord[this.mainField];
                    this.fireSelectedEvent();
                    this.iconFlag = false;
                    this.clearIconFlag = true;
                    this.inputReadOnly = true;
                }
            }
        } catch (error) {
            console.error(error);
        }
    }

    async getRecentlyViewedRecords() {
        try {
            if (this._recentlySelectedCache || !this.objectName) {
                this.searchRecords = this._recentlySelectedCache;
                return;
            }
            const recentlyViewed = await getRecentlyViewed({
                sObjectName: this.objectName,
                mainField: this.mainField,
                returnFields: this.returnFields,
                filter: this.filter
            });
            this._recentlySelectedCache = recentlyViewed;
            this.searchRecords = recentlyViewed;
        } catch (error) {
            console.error(error);
        }
    }

    /*
     * handles change in search input, fetches records that contain searched text in one of queryFields
     *
     * @author  Svatopluk Sejkora, BearingPoint
     * @date    2022-10-08
     */
    async handleInputChange(event) {
        try {
            this.currentSearchedText = event.target.value;
            this.loadingFlag = true;
            if (!this.currentSearchedText || this.currentSearchedText === '') {
                await this.resetData();
                return;
            }
            this.searchRecords = await getResults({
                sObjectName: this.objectName,
                returnFields: this.returnFields,
                queryFields: this.queryFields,
                searchText: this.currentSearchedText,
                maxResults: this.maxResults,
                filter: this.filter,
                mainField: this.mainField
            });
            this.setFlagsAndOpenCombobox();
        } catch (error) {
            console.error(error);
        } finally {
            this.loadingFlag = false;
        }
    }

    setFlagsAndOpenCombobox() {
        this.messageFlag = this.currentSearchedText && this.currentSearchedText.length > 0 && this.searchRecords.length === 0;
        if (this.selectRecordId && this.selectRecordId.length > 0) {
            this.iconFlag = false;
            this.clearIconFlag = true;
        } else {
            this.iconFlag = true;
            this.clearIconFlag = false;
        }
        this.openCombobox();
    }

    /*
     * handles clicking on one of records in combobox - sets it as selected record and fires selected event
     *
     * @author  Svatopluk Sejkora, BearingPoint
     * @date    2022-10-08
     */
    setSelectedRecord(event) {
        this.selectRecordName = event.currentTarget.dataset.name;
        this.selectRecordId = event.currentTarget.dataset.id;
        this.iconFlag = false;
        this.clearIconFlag = true;
        this.inputReadOnly = true;
        if (this.blurTimeout) {
            clearTimeout(this.blurTimeout);
        }
        this.closeCombobox();
        this.searchRecords = [];
        this.currentSearchedText = undefined;
        this.reportValidity();
        this.fireSelectedEvent();
    }

    /*
     * fires selected event containing id and name of selected record
     *
     * @author  Svatopluk Sejkora, BearingPoint
     * @date    2022-10-08
     */
    fireSelectedEvent() {
        const selectedEvent = new CustomEvent('selected', {
            detail: {
                name: this.selectRecordName,
                id: (this.selectRecordId ? this.selectRecordId : '')
            }
        });
        this.dispatchEvent(selectedEvent);
    }

    /*
     * resets input - deleting all fetched and selected data
     *
     * @author  Svatopluk Sejkora, BearingPoint
     * @date    2022-10-08
     */
    async resetData() {
        try {
            this.selectRecordName = undefined;
            this.selectRecordId = undefined;
            this.currentSearchedText = undefined;
            if (!this._selectRecordId) {
                await this.getRecentlyViewedRecords();
            }
            this.loadingFlag = false;
            this.inputReadOnly = false;
            this.iconFlag = true;
            this.clearIconFlag = false;
            this.closeCombobox();
            this.fireSelectedEvent();
        } catch (error) {
            console.error(error);
        }
    }

    /*
     * sets classes to close combobox
     *
     * @author  Svatopluk Sejkora, BearingPoint
     * @date    2022-10-08
     */
    closeCombobox() {
        this.comboboxClasses = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        this.reportValidity();
    }

    closeComboboxTimeout() {
        this.blurTimeout = setTimeout(() => {
            this.closeCombobox();
        }, 300);
    }

    /*
     * sets classes to open combobox if searched text is filled, otherwise closes combobox
     *
     * @author  Svatopluk Sejkora, BearingPoint
     * @date    2022-10-08
     */
    openCombobox() {
        if ((this.currentSearchedText && this.currentSearchedText.length > 0)
            || (this.searchRecords && this.searchRecords.length > 0)) {
            this.comboboxClasses = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open';
        } else {
            this.closeCombobox();
        }
    }

    /*
     * converts fetched sobjects into dtos to dynamically render html
     *
     * @author  Svatopluk Sejkora, BearingPoint
     * @date    2022-10-08
     */
    get searchRecordsDtos() {
        const searchRecordsDtos = [];
        if (!this.searchRecords) {
            return searchRecordsDtos;
        }
        const returnFields = this.returnFields;
        this.searchRecords.forEach(searchRecord => {
            let returnId;
            if (this.returnDifferentObjectId === undefined) {
                returnId = searchRecord.Id;
            } else {
                returnId = searchRecord[this.returnDifferentObjectId];
            }
            const dto = {Id: returnId, Name: searchRecord[this.mainField], detailFields: []};
            returnFields.forEach(field => {
                if (returnFields.indexOf(field) !== 0) {
                    let fieldValue = this.getFieldFromRelationObject(searchRecord, field);
                    if (!fieldValue) {
                        fieldValue = '---';
                    }
                    dto.detailFields.push([fieldValue]);
                }
            });
            searchRecordsDtos.push(dto);
        });
        return searchRecordsDtos;
    }

    /*
     * retrieves field value from related objects
     *
     * @author  Svatopluk Sejkora, BearingPoint
     * @date    2022-10-08
     */
    getFieldFromRelationObject(object, fieldName) {
        if (!object || !fieldName) {
            return;
        }
        if (fieldName.includes('.')) {
            const splitFieldNameByFirstDot = fieldName.split(/\.(.+)/);
            return this.getFieldFromRelationObject(object[splitFieldNameByFirstDot[0]], splitFieldNameByFirstDot[1]);
        }

        return object[fieldName];
    }

    /*
     * returns dynamic css classes for icon, whether left icon should be displayed or not
     *
     * @author  Svatopluk Sejkora, BearingPoint
     * @date    2022-10-08
     */
    get iconClasses() {
        return this.inputReadOnly ? 'slds-form-element__control slds-input-has-icon slds-input-has-icon--left-right'
            : 'slds-form-element__control slds-input-has-icon slds-input-has-icon_right';
    }

    get inputIconClasses() {
        let classes = '';
        if (this.variant !== 'label-hidden') {
            classes += 'icon-margin-input-has-label';
        } else {
            classes += 'icon-margin-input-has-not-label';
        }
        if (this.isMobile) {
            classes += ' mobile';
        }
        return classes;
    }

    get rightIconStyles() {
        let classes = 'slds-icon slds-icon slds-icon_small right-icon-margin-input';
        if (this.variant === 'label-hidden') {
            classes += ' right-icon-margin-input-has-not-label';
        }
        if (this.hasError) {
            classes += ' right-icon-margin-input-error';
        }
        if (this.isMobile) {
            classes += ' mobile';
        }
        return classes;
    }

    get clearButtonStyles() {
        let classes = 'slds-button slds-button_icon slds-input__icon slds-input__icon_right';
        if (this.variant !== 'label-hidden') {
            classes += ' right-clear-icon-margin-input-has-label';
        }
        if (this.isMobile) {
            classes += ' mobile';
        }
        return classes;
    }

    get showClearButton() {
        return Boolean(this.clearIconFlag && !this.disabled);
    }

    get isMobile() {
        // considers tablet as mobile also
        return Boolean(FORM_FACTOR !== 'Large');
    }

    get displayLabel() {
        return Boolean(this.variant !== 'label-hidden');
    }

    // dropdown with 7 records is the default
    get dropdownClasses() {
        return 'slds-dropdown slds-dropdown_fluid slds-dropdown_length-with-icon-' + (this.dropdownLength && ['5', '7', '10'].find(this.dropdownLength) ? this.dropdownLength : '7');
    }

    /*handleAdvancedSearchClick() {
        this.openModal = true;
    }

    closeAdvancedSearch() {
        this.openModal = false
    }*/
}