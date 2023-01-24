/**
 * Created by svatopluk.sejkora on 20.09.2022.
 */

import {LightningElement, track} from 'lwc';
import changeOwnerOfVisits from "@salesforce/apex/CallBaseManagementController.changeOwnerOfVisits";
import fetchTamUsers from "@salesforce/apex/CallBaseManagementController.fetchTamUsers";
import {replaceStringValues} from 'c/stringOperationsService';
import {processError} from 'c/errorHandlingService';
import {setTabNameAndIcon} from 'c/workspaceApiService';
import selectedNumberOfRowsLabel from '@salesforce/label/c.SelectedNumberOfRows';
import successMoveMessage from '@salesforce/label/c.SuccessMoveMessage'
import move from '@salesforce/label/c.Move'
import newTam from '@salesforce/label/c.NewTam';
import currentTamLabel from '@salesforce/label/c.CurrentTam';
import dateFromLabel from '@salesforce/label/c.DateFrom';
import dateToLabel from '@salesforce/label/c.DateTo';
import priorityLabel from '@salesforce/label/c.Priority';
import tradingFrequencyLabel from '@salesforce/label/c.TradingFrequency';
import callDateLabel from '@salesforce/label/c.CallDate';
import callStatusLabel from '@salesforce/label/c.CallStatus';
import originalOwnerLabel from '@salesforce/label/c.OriginalOwner';
import callOwnerLabel from '@salesforce/label/c.CallOwner';
import deliveryPointNameLabel from '@salesforce/label/c.DeliveryPointName';
import deliveryPointPostCodeLabel from '@salesforce/label/c.DeliveryPointPostCode';
import dpReferenceLabel from '@salesforce/label/c.DpReference';
import primaryGridLabel from '@salesforce/label/c.PrimaryGrid';
import secondaryGridLabel from '@salesforce/label/c.SecondaryGrid';
import depotLabel from '@salesforce/label/c.Depot';
import creditStatusLabel from '@salesforce/label/c.CreditStatus';
import visitTransferTabNameLabel from '@salesforce/label/c.VisitTransferTabName'
import {ShowToastEvent} from "lightning/platformShowToastEvent";

const columns = [
    {
        label: callDateLabel, fieldName: 'aforza__Planned_Time__c', type: 'date', typeAttributes: {
            day: 'numeric',
            month: 'numeric',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hour12: false
        }
    },
    {label: callStatusLabel, fieldName: 'aforza__Status__c'},
    {label: originalOwnerLabel, fieldName: 'aforza__Account__rOwnerLastName'},
    {label: callOwnerLabel, fieldName: 'aforza__Owner__rLastName'},
    {label: deliveryPointNameLabel, fieldName: 'aforza__Account__rStoreName__c'},
    {label: deliveryPointPostCodeLabel, fieldName: 'aforza__Account__rShippingPostalCode'},
    {label: dpReferenceLabel, fieldName: 'aforza__Account__rDeliveryPointReference__c'},
    {label: primaryGridLabel, fieldName: 'aforza__Account__rPrimaryGridNumber__c'},
    {label: secondaryGridLabel, fieldName: 'aforza__Account__rSecondaryGridNumber__c'},
    {label: depotLabel, fieldName: 'aforza__Account__rDepot__c'},
    {label: creditStatusLabel, fieldName: 'aforza__Account__rCreditStatus__c'},
    {label: priorityLabel, fieldName: 'aforza__Account__rCallPriority__c'},
    {label: tradingFrequencyLabel, fieldName: 'aforza__Account__rTradingFrequencyBucketed__c'},
];

export default class CallBaseManagement extends LightningElement {

    @track isLoading = false;
    @track tableData = [];
    columns = columns;
    toFlatten = true;
    tamUsers = [];
    limitOfRowsReturned = 900;
    sObjectApiName = 'aforza__Visit__c';
    filterSize = 2;
    @track selectedIds = [];
    @track filterFields = [];
    @track tamToMove;
    label = {
        move,
        newTam
    }

    queryFields = 'Id, aforza__Status__c,aforza__Planned_Time__c,aforza__Account__r.Owner.LastName,aforza__Account__r.Owner.FirstName,' +
        'aforza__Owner__r.LastName,aforza__Owner__r.FirstName,aforza__Account__r.StoreName__c,aforza__Account__r.ShippingPostalCode,' +
        'aforza__Account__r.DeliveryPointReference__c,aforza__Account__r.PrimaryGridNumber__c,aforza__Account__r.SecondaryGridNumber__c,' +
        'toLabel(aforza__Account__r.Depot__c),aforza__Account__r.CreditStatus__c,aforza__Account__r.CallPriority__c,aforza__Account__r.TradingFrequencyBucketed__c';

    /**
     * obtaining data for component within connected callback. calls apex to obtain TAM users
     * Calls method to prepare filter data
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    connectedCallback() {
        Promise.all([this.fetchTamUsers()]).then(() => {
            this.prepareFieldDefinitionVisit();
        });
        setTabNameAndIcon(visitTransferTabNameLabel, 'action:change_owner', visitTransferTabNameLabel, this);
    }

    /** Method to prepare filter fields definition for filter component
     *
     * @returns {boolean} - true for Date
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    prepareFieldDefinitionVisit() {
        this.filterFields.push(this.createInputFieldDefinitionJson('Picklist', 'aforza__Owner__c',
            currentTamLabel, null, this.tamUsers, null, 'equals'));
        this.filterFields.push(this.createInputFieldDefinitionJson('Date', 'aforza__Planned_Time__c',
            dateFromLabel, null, null, null, 'equalGreater'));
        this.filterFields.push(this.createInputFieldDefinitionJson('Date', 'aforza__Planned_Time__c',
            dateToLabel, null, null, null, 'equalSmaller'));
        this.filterFields.push(this.createInputFieldDefinitionJson('Picklist', 'CallPriority__c',
            priorityLabel, null, [{"label": "", "value": ""}, {"label": "P1", "value": "P1"}, {
                "label": "P2",
                "value": "P2"
            },
                {"label": "P3", "value": "P3"}], 'aforza__Account__r.CallPriority__c', 'equals'));
        this.filterFields.push(this.createInputFieldDefinitionJson('Picklist', 'TradingFrequencyBucketed__c',
            tradingFrequencyLabel, null, [{"label": "", "value": ""}, {"label": "0-4", "value": "0-4"}, {
                "label": "5-9", "value": "5-9"
            },
                {"label": "10-13", "value": "10-13"}, {"label": "14-20", "value": "14-20"}, {
                    "label": "20+",
                    "value": "20+"
                }],
            'aforza__Account__r.TradingFrequencyBucketed__c', 'equals'));
    }

    /**
     * takes passed values and builds object with them
     *
     * @param dataType - type of data (Picklist, Integer, Date)
     * @param apiName - api name of the field
     * @param label - label to be used in filter
     * @param value - predefined value (not yet working)
     * @param options - list of options for sf combobox input field
     * @param soqlName - name to be used within SOQL for filtering (needed for fields to be accessed via dot notation
     * (if same as apiName should be empty)
     * @param operand - operand to be used for this specific field (equals, equalSmaller, equalGreater)
     *
     * @returns {Object} - object with filter field definition
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    createInputFieldDefinitionJson(dataType, apiName, label, value, options, soqlName, operand) {
        let inputFieldDefinition = {};
        inputFieldDefinition.type = dataType;
        inputFieldDefinition.name = apiName;
        inputFieldDefinition.label = label;
        inputFieldDefinition.value = value;
        inputFieldDefinition.options = [] = options;
        inputFieldDefinition.soqlName = soqlName === null ? apiName : soqlName;
        inputFieldDefinition.operand = operand;
        inputFieldDefinition.index = this.filterFields.length
        return inputFieldDefinition;
    }

    /** Method to process returned data from filter. Will empty the data table first.
     *
     * @param event event from filter component with data
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    processReturnedData(event) {
        this.tableData = [];
        console.log('processing data');
        this.tableData = event.detail.returnedData;
        console.log('copy data?');
        this.mergeNamesToSingleColumn();
    }

    /** Method to return true when there are data to show
     *
     * @returns {boolean} - true when there is at least 1 returned data
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    get showTable() {
        return Boolean(this.tableData.length > 0);
    }

    /** Method to obtain text with replaced dynamic values
     *
     * @returns {string} - label with replaced dynamic data
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    get selectedRowsText() {
        const regex = /#([^#]+)#/g;
        const replacingValues = {0: this.selectedIds.length};
        return replaceStringValues(selectedNumberOfRowsLabel, regex, replacingValues);
    }

    /** Method to control if the move button is clickable
     *
     * @returns {boolean} - true when no new owner selected or no rows selected => not clickable
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    get showMove() {
        return Boolean(this.tamToMove === undefined || this.selectedIds.length === 0);
    }

    /** Method to cal apex to get TAM users and prepares structure for picklist
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    async fetchTamUsers() {
        try {
            this.isLoading = true;
            const users = await fetchTamUsers();
            this.tamUsers.push({label: "", value: ""});
            if (users) {
                users.forEach((user) => {
                    this.tamUsers.push({label: user.FirstName + ' ' + user.LastName, value: user.Id});
                });
            }
        } catch (error) {
            processError(this, error);
        } finally {
            this.isLoading = false;
        }
    }

    /** Method to handle selection of rows. Currently all current selection is removed and new fields are added
     *
     * @param event - event that fires when rows are selected
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    getSelectedRows(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedIds = [];
        for (let i = 0; i < selectedRows.length; i++) {
            this.selectedIds.push(selectedRows[i].Id);
        }
    }

    mergeNamesToSingleColumn() {
        this.tableData.forEach((visit) => {
            const visitOwner = `${visit.aforza__Owner__rLastName} ${visit.aforza__Owner__rFirstName}`;
            const accountOwner = `${visit.aforza__Account__rOwnerLastName} ${visit.aforza__Account__rOwnerFirstName}`;
            visit.aforza__Owner__rLastName = visitOwner;
            visit.aforza__Account__rOwnerLastName = accountOwner;
        });
    }

    /** Method to assign new TAM owner to attribute
     *
     * @param event - event with the new TAM id
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    handleNewTamSelection(event) {
        this.tamToMove = event.target.value;
    }

    /** Method to call apex to change owner of visits. then remove any selected rows. and then fire filter operation in
     * filter to reload data
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    async handleMoveClick() {
        try {
            this.isLoading = true;
            await changeOwnerOfVisits({'visits': this.selectedIds, 'newOwner': this.tamToMove});
            this.template.querySelector('.table').selectedRows = [];
            const dynamicFilter = this.template.querySelector('c-dynamic-filter');
            await dynamicFilter.handleFilterClick();
            this.selectedIds = [];
            this.tamToMove = '';
            const toastSuccess = new ShowToastEvent({
                title: 'Success',
                message: successMoveMessage,
                variant: 'success'
            });
            this.dispatchEvent(toastSuccess);
        } catch (error) {
            processError(this, error);
        } finally {
            this.isLoading = false;
        }
    }
}