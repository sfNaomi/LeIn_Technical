/**
 * Created by svatopluk.sejkora on 05.10.2022.
 */

import {LightningElement, track} from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import fetchNeededPicklistValues from '@salesforce/apex/LogisticUpdateScreenController.fetchNeededPicklistValues'
import updateOrderStatus from '@salesforce/apex/LogisticUpdateScreenController.updateOrderStatus'
import {processError} from 'c/errorHandlingService';
import {replaceStringValues} from 'c/stringOperationsService';
import {setTabNameAndIcon} from 'c/workspaceApiService';


import isDepotUser from '@salesforce/customPermission/DepotUser';
import isPickingUser from '@salesforce/customPermission/PickingUser';

import selectedNumberOfOrderRowsLabel from '@salesforce/label/c.SelectedNumberOfOrderRows';
import action from '@salesforce/label/c.Action';
import printUpdate from '@salesforce/label/c.PrintUpdate';
import loadId from '@salesforce/label/c.LoadId';
import depot from '@salesforce/label/c.Depot';
import deliveryDate from '@salesforce/label/c.DeliveryDate';
import orderId from '@salesforce/label/c.OrderId';
import accountName from '@salesforce/label/c.AccountName';
import status from '@salesforce/label/c.Status';
import pickingSheetPrinted from '@salesforce/label/c.PickingSheetPrinted';
import pickingCompleted from '@salesforce/label/c.PickingCompleted';
import isLoaded from '@salesforce/label/c.IsLoaded';
import deliveryManifestPrinted from '@salesforce/label/c.DeliveryManifestPrinted';
import deliveryNotePrinted from '@salesforce/label/c.DeliveryNotePrinted';
import receipt from '@salesforce/label/c.Receipt';
import invoicePrinted from '@salesforce/label/c.InvoicePrinted';

const columns = [
    {label: loadId, fieldName: 'Load__rName'},
    {label: depot, fieldName: 'Depot__c'},
    {
        label: deliveryDate, fieldName: 'DeliveryDate__c', type: 'date', typeAttributes: {
            day: 'numeric',
            month: 'numeric',
            year: 'numeric',
            hour12: false
        }
    },
    {
        label: orderId,
        fieldName: 'orderUrl',
        type: 'url',
        typeAttributes: {label: {fieldName: 'OrderNumber'}},
        target: '_blank'
    },
    {label: accountName, fieldName: 'AccountName__c'},
    {label: status, fieldName: 'Status'},
    {label: pickingSheetPrinted, fieldName: 'PickingSheetPrinted__c', type: 'boolean'},
    {label: pickingCompleted, fieldName: 'PickingCompleted__c', type: 'boolean'},
    {label: isLoaded, fieldName: 'IsLoaded__c', type: 'boolean'},
    {label: deliveryManifestPrinted, fieldName: 'DeliveryManifestPrinted__c', type: 'boolean'},
    {label: deliveryNotePrinted, fieldName: 'DeliveryNotePrinted__c', type: 'boolean'},
    {label: receipt, fieldName: 'Receipt__c', type: 'boolean'},
    {label: invoicePrinted, fieldName: 'Invoice__rInvoicePrinted__c', type: 'boolean'}
];

const pickingUserActions = [
    {"label": "", "value": ""},
    {"label": "Print Pick Sheets", "value": "Print Pick Sheets"},
    {"label": "Picked", "value": "Picked"}
];

const depotUserActions = [
    {"label": "", "value": ""},
    {"label": "Print Pick Sheets", "value": "Print Pick Sheets"},
    {"label": "Picked", "value": "Picked"},
    {"label": "Print Manifest", "value": "Print Manifest"},
    {"label": "Print Delivery Note", "value": "Print Delivery Note"},
    {"label": "Loaded", "value": "Loaded"},
    {"label": "Receipted", "value": "Receipted"},
    {"label": "Print Invoices", "value": "Print Invoices"},
    {"label": "Cancel Order", "value": "Cancel Order"},
    {"label": "Replan", "value": "Replan"}
];

export default class LogisticUpdateScreen extends LightningElement {

    @track filterFields = [];
    @track tableData = [];
    @track selectedRows = [];
    columns = columns;
    toFlatten = true;
    limitOfRowsReturned = 900;
    isLoading = false;
    filterSize = 2;
    sObjectApiName = 'Order';
    depotPicklist = [];
    statusPicklist = [];
    actions = [];
    @track selectedAction = '';
    @track actionConfirmDisabled = true;
    label = {
        action,
        printUpdate
    }
    queryFields = 'Id,Load__r.Name,Depot__c,DeliveryDate__c,OrderNumber,AccountName__c,Status,PickingSheetPrinted__c,PickingCompleted__c,' +
        'IsLoaded__c,DeliveryManifestPrinted__c,DeliveryNotePrinted__c,Receipt__c,Invoice__r.InvoicePrinted__c';

    connectedCallback() {
        setTabNameAndIcon('Logistic Update Screen', 'standard:planogram', 'Logistic Update Screen', this);
        Promise.all([this.fetchPicklistValues()]).then(() => {
            this.prepareFilterDefinition();
            this.prepareActionValues();
        });
    }

    /** Method to prepare filter fields definition for filter component. Sets class attribute.
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    prepareFilterDefinition() {
        this.filterFields.push(this.createInputFieldDefinitionJson('Text', 'Load__c',
            'Load ID', null, [{"label": "", "value": ""}], 'Load__r.Name', 'equals'));

        this.filterFields.push(this.createInputFieldDefinitionJson('Picklist', 'Depot__c',
            'Depot', null, this.depotPicklist, null, 'equals'));

        this.filterFields.push(this.createInputFieldDefinitionJson('Date', 'DeliveryDate__c',
            'Delivery Date', null, null, null, 'equals'));

        this.filterFields.push(this.createInputFieldDefinitionJson('Picklist', 'Status',
            'Status', null, this.statusPicklist, null, 'equals'));
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
        // add clickable URL to the Order Number
        let orderUrl;
        this.tableData = event.detail.returnedData.map(row => {
            orderUrl = `/${row.Id}`;
            return {...row, orderUrl}
        });
    }

    /** Method to call apex to get picklist values
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    async fetchPicklistValues() {
        try {
            this.isLoading = true;
            const picklists = await fetchNeededPicklistValues({
                objectName: this.sObjectApiName,
                fieldNames: ['Depot__c', 'Status']
            });
            this.statusPicklist.push({label: "", value: ""});
            this.depotPicklist.push({label: "", value: ""});
            picklists.forEach((picklist) => {
                if (picklist.fieldName === 'Depot__c') {
                    this.depotPicklist.push({label: picklist.label, value: picklist.value});
                } else if (picklist.fieldName === 'Status') {
                    this.statusPicklist.push({label: picklist.label, value: picklist.value});
                }
            });
        } catch (error) {
            processError(this, error);
        } finally {
            this.isLoading = false;
        }
    }

    /** Method to handle selection of rows. Currently, all current selection is removed and new fields are added
     *
     * @param event - event that fires when rows are selected
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    getSelectedRows(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedRows = [];
        this.selectedRows = [...selectedRows];
    }

    /** Method to update selected action and to check that the action is allowed to be used. Triggered on change of action
     *
     * @author Svata Sejkora
     * @date 2022-10-07
     */
    handleActionSelection(event) {
        const selectedAction = event.target.value;
        this.checkOrderStatusesForSelectedAction(selectedAction);
        this.selectedAction = selectedAction;
    }

    /** Method to call apex when action button is clicked
     *
     * @author Svata Sejkora
     * @date 2022-10-07
     */
    handleActionButton() {
        try {
            this.isLoading = true;
            switch (this.selectedAction) {
                case 'Print Pick Sheets':
                    //TODO add proper action once this is finished
                    this.showActionNotYetImplemented(this.selectedAction);
                    break;
                case 'Picked':
                    this.changeOrderStatus(this.getSelectedOrdersIds(), 'Ready to Load');
                    break;
                case 'Print Manifest':
                    //TODO add proper action once this is finished
                    this.showActionNotYetImplemented(this.selectedAction);
                    break;
                case 'Print Delivery Note':
                    //TODO add proper action once this is finished
                    this.showActionNotYetImplemented(this.selectedAction);
                    break;
                case 'Loaded':
                    this.changeOrderStatus(this.getSelectedOrdersIds(), 'Pending Delivery');
                    break;
                case 'Receipted':
                    this.changeOrderStatus(this.getSelectedOrdersIds(), 'Receipted');
                    break;
                case 'Print Invoices':
                    //TODO add proper action once this is finished
                    this.showActionNotYetImplemented(this.selectedAction);
                    break;
                case 'Cancel Order':
                    this.changeOrderStatus(this.getSelectedOrdersIds(), 'Cancelled');
                    break;
                case 'Replan':
                    this.changeOrderStatus(this.getSelectedOrdersIds(), 'Unplanned');
                    break;
                default:
            }
        } catch (error) {
            processError(this, error);
        } finally {
            this.isLoading = false;
        }
    }

    /** temporary method to show toast with info
     *
     * @author Svata Sejkora
     * @date 2022-10-07
     */
    showActionNotYetImplemented(selectedAction) {
        const toastSuccess = new ShowToastEvent({
            title: 'Action not yet implemented',
            message: `Action "${selectedAction}" is not yet implemented. Nothing is happening`,
            variant: 'warning'
        });
        this.dispatchEvent(toastSuccess);
    }

    /** Method to obtain Ids of orders from the list of order objects
     *
     * @author Svata Sejkora
     * @date 2022-10-07
     */
    getSelectedOrdersIds() {
        let selectedIds = [];
        this.selectedRows.forEach((order) => {
            selectedIds.push(order.Id);
        });
        return selectedIds;
    }

    /** Method to call apex to change the status of the orders
     *
     * @author Svata Sejkora
     * @date 2022-10-07
     */
    async changeOrderStatus(orderIds, newStatus) {
        await updateOrderStatus({orderIds: orderIds, newStatus: newStatus});
        this.template.querySelector('.table').selectedRows = [];
        const dynamicFilter = this.template.querySelector('c-dynamic-filter');
        await dynamicFilter.handleFilterClick();
        this.selectedRows = [];
        this.selectedAction = '';
        const toastSuccess = new ShowToastEvent({
            title: 'Success',
            message: 'Orders have been updated.',
            variant: 'success'
        });
        this.dispatchEvent(toastSuccess);
    }

    /** Method containing definition of allowed statuses for each action. It also triggers necessary check to be sure selected data are valid
     *
     * @author Svata Sejkora
     * @date 2022-10-07
     */
    checkOrderStatusesForSelectedAction(selectedAction) {
        switch (selectedAction) {
            case 'Print Pick Sheets':
                this.checkIfSelectedOrdersHaveValidStatuses(selectedAction, ['Ready to Pick', 'Picking in Progress', 'Ready to Load', 'Delivered', 'Receipted']);
                break;
            case 'Picked':
                this.checkIfSelectedOrdersHaveValidStatuses(selectedAction, ['Picking in Progress']);
                break;
            case 'Print Manifest':
                this.checkIfSelectedOrdersHaveValidStatuses(selectedAction, ['Ready to Load', 'Delivered', 'Receipted']);
                break;
            case 'Print Delivery Note':
                this.checkIfSelectedOrdersHaveValidStatuses(selectedAction, ['Ready to Load', 'Delivered', 'Receipted']);
                break;
            case 'Loaded':
                this.checkIfSelectedOrdersHaveValidStatuses(selectedAction, ['Ready to Load']);
                break;
            case 'Receipted':
                this.checkIfSelectedOrdersHaveValidStatuses(selectedAction, ['Delivered']);
                break;
            case 'Print Invoices':
                this.checkIfSelectedOrdersHaveValidStatuses(selectedAction, ['Receipted']);
                break;
            case 'Cancel Order':
                this.checkIfSelectedOrdersHaveValidStatuses(selectedAction, ['Delivery Failed']);
                break;
            case 'Replan':
                this.checkIfSelectedOrdersHaveValidStatuses(selectedAction, ['Delivery Failed']);
                break;
            default:
                this.actionConfirmDisabled = false;
        }
    }

    /** Method to iterate through selected orders to check if their statuses are valid
     *
     * @author Svata Sejkora
     * @date 2022-10-07
     */
    checkIfSelectedOrdersHaveValidStatuses(selectedAction, allowedStatuses) {
        const filteredValues = this.selectedRows.filter(order => allowedStatuses.includes(order.Status));
        if (filteredValues.length === this.selectedRows.length) {
            this.actionConfirmDisabled = false;
        } else {
            this.actionConfirmDisabled = true;
            const toastSuccess = new ShowToastEvent({
                title: 'Selected Orders do not have correct Status',
                message: `For Action "${selectedAction}" all selected orders have to have status(es): ${JSON.stringify(allowedStatuses)}`,
                variant: 'warning',
                mode: 'sticky'
            });
            this.dispatchEvent(toastSuccess);
        }
    }

    /** Method to prepare different action lists for different custom permissions
     *
     * @author Svata Sejkora
     * @date 2022-10-07
     */
    prepareActionValues() {
        if (isDepotUser) {
            this.actions = [...depotUserActions];
        } else if (isPickingUser) {
            this.actions = [...pickingUserActions];
        }

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
        const replacingValues = {0: this.selectedRows.length};
        return replaceStringValues(selectedNumberOfOrderRowsLabel, regex, replacingValues);
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

    /** Method to return true when there are no data selected
     * controls if the action selection is enabled or not
     *
     * @returns {boolean} - true when there is no rows selected
     *
     * @author Svata Sejkora
     * @date 2022-10-07
     */
    get disableActionSelection() {
        return Boolean(this.selectedRows.length === 0);
    }

    /** Method to return true when the action button should be disabled
     *
     * @returns {boolean} - true when action should be disabled or when there is no selected action
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    get actionButtonDisabled() {
        return Boolean(this.actionConfirmDisabled || this.selectedAction.length === 0);
    }
}