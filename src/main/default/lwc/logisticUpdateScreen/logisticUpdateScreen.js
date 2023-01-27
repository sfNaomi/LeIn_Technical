/**
 * Created by svatopluk.sejkora on 05.10.2022.
 */

import {LightningElement, track} from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import fetchNeededPicklistValues from '@salesforce/apex/LogisticUpdateScreenController.fetchNeededPicklistValues'
import updateRecords from '@salesforce/apex/LogisticUpdateScreenController.updateRecords'
import updateOrders from '@salesforce/apex/LoadPlanningScreenController.updateOrders';
import {processError} from 'c/errorHandlingService';
import {replaceStringValues} from 'c/stringOperationsService';
import {setTabNameAndIcon} from 'c/workspaceApiService';
import {basicSort} from 'c/sortingService';
import {NavigationMixin} from 'lightning/navigation';

import isDepotUser from '@salesforce/customPermission/DepotUser';
import isPickingUser from '@salesforce/customPermission/PickingUser';

import selectedNumberOfOrderRowsLabel from '@salesforce/label/c.SelectedNumberOfOrderRows';
import action from '@salesforce/label/c.Action';
import printUpdate from '@salesforce/label/c.PrintUpdate';
import loadId from '@salesforce/label/c.LoadId';
import depot from '@salesforce/label/c.Depot';
import plannedDeliveryDate from '@salesforce/label/c.PlannedDeliveryDate';
import requestedDeliveryDate from '@salesforce/label/c.RequestedDeliveryDate'
import orderId from '@salesforce/label/c.OrderId';
import accountName from '@salesforce/label/c.AccountName';
import postCode from '@salesforce/label/c.PostCode';
import quantity from '@salesforce/label/c.Quantity';
import status from '@salesforce/label/c.Status';
import pickingSheetPrinted from '@salesforce/label/c.PickingSheetPrinted';
import pickingCompleted from '@salesforce/label/c.PickingCompleted';
import isLoaded from '@salesforce/label/c.IsLoaded';
import deliveryManifestPrinted from '@salesforce/label/c.DeliveryManifestPrinted';
import deliveryNotePrinted from '@salesforce/label/c.DeliveryNotePrinted';
import receipt from '@salesforce/label/c.Receipt';
import invoicePrinted from '@salesforce/label/c.InvoicePrinted';
import palletSequence from '@salesforce/label/c.PickSheetPalletSequence';

const columns = [
    {label: loadId, fieldName: 'Load__rName', sortable: true},
    {label: 'Vehicle Registration', fieldName: 'Load__rVehicleRegistration__c', sortable: true},
    {label: 'Driver', fieldName: 'Load__rDriverFullName__c', sortable: true},
    {label: depot, fieldName: 'Depot__c', sortable: true},
    {
        label: requestedDeliveryDate, fieldName: 'DeliveryDate__c', type: 'date', typeAttributes: {
            day: 'numeric',
            month: 'numeric',
            year: 'numeric',
            hour12: false
        }, sortable: true
    },
    {
        label: plannedDeliveryDate, fieldName: 'Load__rDeliveryDate__c', type: 'date', typeAttributes: {
            day: 'numeric',
            month: 'numeric',
            year: 'numeric',
            hour12: false
        }, sortable: true
    },
    {
        label: orderId,
        fieldName: 'orderUrl',
        type: 'url',
        typeAttributes: {label: {fieldName: 'OrderNumber'}},
        target: '_blank'
    },
    {label: accountName, fieldName: 'AccountName__c', sortable: true},
    {label: postCode, fieldName: 'ShippingPostalCode', sortable: true},
    {label: quantity, fieldName: 'TotalQuantity__c', sortable: true},
    {label: status, fieldName: 'Status', sortable: true},
    {label: palletSequence, fieldName: 'PalletSequence__c', sortable: true, editable: true},
    {label: pickingSheetPrinted, fieldName: 'PickingSheetPrinted__c', type: 'boolean'},
    {label: pickingCompleted, fieldName: 'PickingCompleted__c', type: 'boolean'},
    {label: isLoaded, fieldName: 'IsLoaded__c', type: 'boolean'},
    {label: deliveryManifestPrinted, fieldName: 'DeliveryManifestPrinted__c', type: 'boolean'},
    {label: deliveryNotePrinted, fieldName: 'DeliveryNotePrinted__c', type: 'boolean'},
    {label: receipt, fieldName: 'Receipt__c', type: 'boolean'},
    {label: invoicePrinted, fieldName: 'Invoice__rInvoicePrinted__c', type: 'boolean'},
    {label: 'Vehicle', fieldName: 'Load__rVehicle__rName', sortable: true}
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
    {"label": "Delivered", "value": "Delivered"},
    {"label": "Delivery Failed", "value": "Delivery Failed"},
    {"label": "Receipted", "value": "Receipted"},
    {"label": "Print Invoices", "value": "Print Invoices"},
    {"label": "Cancel Order", "value": "Cancel Order"},
    {"label": "Replan", "value": "Replan"}
];

const RESET_FILTER = 'Reset Filter';

export default class LogisticUpdateScreen extends NavigationMixin(LightningElement) {

    @track filterFields = [];
    originalTableData = [];
    @track tableData = [];
    @track selectedRows = [];
    columns = columns;
    @track sortBy;
    @track sortDirection;
    toFlatten = true;
    limitOfRowsReturned = 900;
    isLoading = false;
    filterSize = 2;
    sObjectApiName = 'Order';
    @track depotPicklist = [];
    @track statusPicklist = [];
    @track loadIdsFromFilteredOrders = [];
    actions = [];
    @track selectedAction = '';
    @track actionConfirmDisabled = true;
    @track selectedLoadId;
    draftValues = [];
    label = {
        action,
        printUpdate
    }
    queryFields = 'Id,Load__r.Name,Load__r.VehicleRegistration__c,Load__r.Vehicle__r.Name,Load__r.DriverFullName__c,toLabel(Depot__c),DeliveryDate__c,Load__r.DeliveryDate__c,' +
        'OrderNumber,AccountName__c,ShippingPostalCode,TotalQuantity__c,Status,PalletSequence__c,PickingSheetPrinted__c,PickingCompleted__c,' +
        'IsLoaded__c,DeliveryManifestPrinted__c,DeliveryNotePrinted__c,Receipt__c,Invoice__c,Invoice__r.InvoicePrinted__c';

    connectedCallback() {
        Promise.all([this.fetchPicklistValues()]).then(() => {
            this.prepareFilterDefinition();
            this.prepareActionValues();
            setTabNameAndIcon('Logistic Update', 'standard:planogram', 'Logistic Update Screen', this);
        });
    }

    /** Method to prepare filter fields definition for filter component. Sets class attribute.
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    prepareFilterDefinition() {
        this.filterFields.push(this.createInputFieldDefinitionJson('Lookup', 'Load__c',
            loadId, null, null, null, 'equals', 'Load__c',
            'standard:webcart', ['Name'], ['Name'], 'Name'));

        this.filterFields.push(this.createInputFieldDefinitionJson('Picklist', 'Depot__c',
            depot, null, this.depotPicklist, null, 'equals'));

        this.filterFields.push(this.createInputFieldDefinitionJson('Date', 'Load__r.DeliveryDate__c',
            plannedDeliveryDate, null, null, 'Load__r.DeliveryDate__c', 'equals'));

        this.filterFields.push(this.createInputFieldDefinitionJson('Picklist', 'Status',
            status, null, this.statusPicklist, null, 'equals'));
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
     * @param lookupObject - if the field is of type Lookup this is api name of the object Lookup is pointing to
     * @param iconName - name of the icon to show in lookup component, valid only for lookup type
     * @param returnFields - list of fields to be returned from query, valid only for lookup type
     * @param queryFields - filtering fields needs to be delimited with OR, valid only for lookup type
     * @param mainField - main field - visible within the Lookup itself, valid only for lookup type
     *
     * @returns {Object} - object with filter field definition
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    createInputFieldDefinitionJson(dataType, apiName, label, value, options, soqlName, operand, lookupObject, iconName, returnFields, queryFields, mainField) {
        let inputFieldDefinition = {};
        inputFieldDefinition.type = dataType;
        inputFieldDefinition.name = apiName;
        inputFieldDefinition.label = label;
        inputFieldDefinition.value = value;
        inputFieldDefinition.options = [] = options;
        inputFieldDefinition.soqlName = soqlName === null ? apiName : soqlName;
        inputFieldDefinition.operand = operand;
        inputFieldDefinition.lookupObject = lookupObject;
        inputFieldDefinition.lookupIcon = iconName;
        inputFieldDefinition.index = this.filterFields.length
        inputFieldDefinition.returnFields = returnFields;
        inputFieldDefinition.queryFields = queryFields;
        inputFieldDefinition.mainField = mainField;
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
        this.originalTableData = [];
        // add clickable URL to the Order Number
        let orderUrl;
        this.originalTableData = event.detail.returnedData.map(row => {
            orderUrl = `/${row.Id}`;
            return {...row, orderUrl}
        });
        this.tableData = this.originalTableData;
        this.prepareLoadIdsForOrderFiltering();
        this.updateSelectedRowsWithNewValues();
    }

    /** Method to iterate over filtered orders and to prepare load is to filter further
     *
     * @author Svata Sejkora
     * @date 2022-10-09
     */
    prepareLoadIdsForOrderFiltering() {
        let loadIds = new Set();
        this.loadIdsFromFilteredOrders = [];
        this.loadIdsFromFilteredOrders.push({"label": RESET_FILTER, "value": RESET_FILTER});
        this.tableData.forEach((order) => {
            if (!loadIds.has(order.Load__rName)) {
                loadIds.add(order.Load__rName);
                this.loadIdsFromFilteredOrders.push({"label": order.Load__rName, "value": order.Load__rName});
            }
        })
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
                    this.updateRecordFields(this.getSelectedOrderIdsWithSpecifiedStatus('Ready to Pick'), {'Status': 'Picking in Progress', 'PickingSheetPrinted__c': true});
                    this.navigateToPage('AGBarrPickSheet', {'p': this.getFieldFromSelectedOrders('Id').join(',')});
                    break;
                case 'Picked':
                    this.updateRecordFields(this.getFieldFromSelectedOrders('Id'), {'Status': 'Ready to Load', 'PickingCompleted__c': true});
                    break;
                case 'Print Manifest':
                    this.updateRecordFields(this.getFieldFromSelectedOrders('Id'), {'DeliveryManifestPrinted__c': true});
                    this.navigateToPage('AGBarrDeliveryManifest', {'p': this.getFieldFromSelectedOrders('Id').join(',')});
                    break;
                case 'Print Delivery Note':
                    this.updateRecordFields(this.getFieldFromSelectedOrders('Id'), {'DeliveryNotePrinted__c' : true});
                    this.navigateToPage('DeliveryNotePDF', {'p': this.getFieldFromSelectedOrders('Id').join(',')});
                    break;
                case 'Loaded':
                    this.updateRecordFields(this.getFieldFromSelectedOrders('Id'), {'Status': 'Pending Delivery', 'IsLoaded__c': true});
                    break;
                case 'Receipted':
                    this.updateRecordFields(this.getFieldFromSelectedOrders('Id'), {'Status': 'Receipted', 'Receipt__c': true});
                    break;
                case 'Print Invoices':
                    this.updateRecordFields(this.getFieldFromSelectedOrders('Invoice__c'), {'InvoicePrinted__c' : true});
                    this.navigateToPage('AgBarrInvoice', {'p': this.getFieldFromSelectedOrders('Invoice__c').join(',')});
                    break;
                case 'Delivered':
                    this.updateRecordFields(this.getFieldFromSelectedOrders('Id'), {'Status': 'Delivered'});
                    break;
                case 'Delivery Failed':
                    this.updateRecordFields(this.getFieldFromSelectedOrders('Id'), {'Status': 'Delivery Failed', 'DeliveryFailed__c': true});
                    break;
                case 'Cancel Order':
                    this.updateRecordFields(this.getFieldFromSelectedOrders('Id'), {'Status': 'Cancelled', 'DeliveryFailed__c': true});
                    break;
                case 'Replan':
                    this.updateRecordFields(this.getFieldFromSelectedOrders('Id'), {'Status': 'Unplanned', 'Replanned__c': true, 'Load__c': null});
                    break;
                default:
            }
            this.resetAction();
        } catch (error) {
            processError(this, error);
        } finally {
            this.isLoading = false;
        }
    }

    handleLoadIdSelection(event) {
        // when the empty value is selected transform it to actual value in order list
        const selectedLoadName = event.target.value === null ? undefined : event.target.value;
        this.processLoadIdSelection(selectedLoadName);

    }

    processLoadIdSelection(selectedLoadName) {
        this.selectedLoadId = selectedLoadName;
        this.tableData = [];
        if (selectedLoadName === RESET_FILTER || selectedLoadName === undefined) {
            // load all returned data
            this.tableData = this.originalTableData;
        } else {
            this.originalTableData.forEach(order => {
                if (order.Load__rName === selectedLoadName) {
                    this.tableData.push(order);
                }
            });
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

    /** Method to obtain the values of a specific field from the list of order objects
     *
     * @author Svata Sejkora
     * @date 2022-10-07
     */
    getFieldFromSelectedOrders(fieldName) {
        let selectedValues = [];
        this.selectedRows.forEach((order) => {
            selectedValues.push(order[fieldName]);
        });
        return selectedValues;
    }

    /** Method to obtain ids of selected rows which have the status specified as input
     *
     * @author Magdalena Stanciu
     * @date 2022-10-19
     */
    getSelectedOrderIdsWithSpecifiedStatus(status) {
        let selectedIds = [];
        this.selectedRows.forEach((order) => {
            if (order.Status === status) {
                selectedIds.push(order.Id);
            }
        });
        return selectedIds;
    }

    /** Method to call apex to change the order fields (different fields based on selected action)
     *
     * @author Svata Sejkora
     * @date 2022-10-07
     */
    async updateRecordFields(recordIds, fieldValues) {
        if (recordIds.length > 0) {
            await updateRecords({recordIds: recordIds, fieldValues: fieldValues});
            const dynamicFilter = this.template.querySelector('c-dynamic-filter');
            await dynamicFilter.handleFilterClick();
            this.processLoadIdSelection(this.selectedLoadId);
            const toastSuccess = new ShowToastEvent({
                title: 'Success',
                message: 'Records have been updated.',
                variant: 'success'
            });
            this.dispatchEvent(toastSuccess);
        }
    }

    /** Method to reset selection of data table and actions
     *
     * @author Magdalena Stanciu
     * @date 2022-10-18
     */
    handleResetSelection() {
        this.template.querySelector('.table').selectedRows = [];
        this.selectedRows = [];
        this.processLoadIdSelection(RESET_FILTER);
        this.resetAction();
    }

    resetAction() {
        this.selectedAction = '';
    }

    /** Method to navigate to a web page with query params
     *
     * @author Magdalena Stanciu
     * @date 2022-10-07
     */
    navigateToPage(page, params) {
        let queryString = this.generateUrlQueryString(params);
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/apex/' + page + queryString
            }
        });
    }

    /** Method to to generate url query string from params received as object
     *
     * @author Magdalena Stanciu
     * @date 2022-10-07
     */
    generateUrlQueryString(params) {
        let queryString = '?';
        Object.keys(params).forEach(key => {
            queryString += key + '=' + params[key];
        });
        return queryString;
    }

    /** Method containing definition of allowed statuses for each action. It also triggers necessary check to be sure selected data are valid
     *
     * @author Svata Sejkora
     * @date 2022-10-07
     */
    checkOrderStatusesForSelectedAction(selectedAction) {
        switch (selectedAction) {
            case 'Print Pick Sheets':
                this.checkIfSelectedOrdersHaveValidStatuses(selectedAction, ['Ready to Pick', 'Picking in Progress', 'Ready to Load', 'Delivered', 'Pending Delivery', 'Receipted']);
                break;
            case 'Picked':
                this.checkIfSelectedOrdersHaveValidStatuses(selectedAction, ['Picking in Progress']);
                break;
            case 'Print Manifest':
                this.checkIfSelectedOrdersHaveValidStatuses(selectedAction, ['Ready to Load', 'Delivered', 'Pending Delivery', 'Receipted']);
                break;
            case 'Print Delivery Note':
                this.checkIfSelectedOrdersHaveValidStatuses(selectedAction, ['Ready to Load', 'Delivered', 'Pending Delivery', 'Receipted']);
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
            case 'Delivered':
                this.checkIfSelectedOrdersHaveValidStatuses(selectedAction, ['Pending Delivery']);
                break;
            case 'Delivery Failed':
                this.checkIfSelectedOrdersHaveValidStatuses(selectedAction, ['Pending Delivery']);
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
                message: `For Action "${selectedAction}" all selected orders have to be in status(es): ${JSON.stringify(allowedStatuses)}`,
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

    /** Method to save orders when there would be inline edit on them
     * IMPORTANT this update mechanism will work only for Order fields as other are flattened.
     *
     * @param event from the default lightning datatable
     *
     * @author Svata Sejkora
     * @date 2022-12-09
     */
    async handleOrderSave(event) {
        try {
            const updatedFields = event.detail.draftValues;

            await updateOrders({data: updatedFields});
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Orders have been updated',
                    variant: 'success'
                })
            );
            // Update data in datatable
            this.refreshDataTableValues(updatedFields);
            // Clear all draft values in the datatable
            this.draftValues = [];
        } catch (error) {
            processError(this, error);
        }
    }

    /** Method to iterate in each changed item and search that item in original table data to update for new values to
     * be visible in the table immediately
     * @param updatedFields list of objects with orders that are returned from save event. They only contain updated fields
     *
     * @author Svata Sejkora
     * @date 2022-12-09
     */
    refreshDataTableValues(updatedFields) {
        updatedFields.forEach((updatedOrder) => {
            let orderToUpdate = this.tableData.find((order) => {
                return updatedOrder.Id === order.Id;
            });
            for (const key in updatedOrder) {
                if (key !== 'Id') {
                    orderToUpdate[key] = updatedOrder[key];
                }
            }
        });
    }

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.tableData = basicSort(this.sortBy, this.sortDirection, this.tableData);
    }

    updateSelectedRowsWithNewValues() {
        this.tableData.forEach((order) => {
           const selectedRowIndex = this.selectedRows.findIndex((selectedOrder) => {
               return selectedOrder.Id === order.Id;
           });
           if (selectedRowIndex >= 0) {
               this.selectedRows[selectedRowIndex] = order;
           }
        });
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

    /** Method to return true when the filter values are laoded, as we are loading some of the data from apex we need to show only when filters are loaded
     *
     * @returns {boolean} - true when there is at least 1 filtered value definition
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    get filterDataReady() {
        return Boolean(this.filterFields.length > 0);
    }

    /** Method to return true when there is only one option (empty) no need to filter
     *
     * @returns {boolean} - true when there is exactly 1 options = empty one, no need to filter
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    get disableLoadIdFilter() {
        return Boolean(this.loadIdsFromFilteredOrders.length === 1);
    }

    /** Method to return base filter
     *
     * @returns {string} - formatted base not removable filter
     *
     * @author Svata Sejkora
     * @date 2022-12-08
     */
    get ordersDefaultFilter() {
        return ` AND Status != 'Draft' AND Status != 'Awaiting Approval' AND Status != 'Activated' AND 
        (RecordType.DeveloperName = 'TelesalesOrder' OR RecordType.DeveloperName = 'FieldDirectOrder' OR
          RecordType.DeveloperName = 'EDIOrder' OR RecordType.DeveloperName = 'ECommerceOrder' 
          OR RecordType.DeveloperName = 'ReturnOrder')`
    }
}