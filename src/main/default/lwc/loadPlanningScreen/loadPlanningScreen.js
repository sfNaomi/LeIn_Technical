/**
 * Created by svatopluk.sejkora on 12.10.2022.
 */

import {LightningElement, track} from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import fetchNeededPicklistValues from '@salesforce/apex/LogisticUpdateScreenController.fetchNeededPicklistValues';
import fetchOrdersForLoad from '@salesforce/apex/LoadPlanningScreenController.fetchOrdersForLoad';
import fetchLoadData from '@salesforce/apex/LoadPlanningScreenController.fetchLoadData';
import fetchVehicle from '@salesforce/apex/LoadPlanningScreenController.fetchVehicle';
import {processError} from 'c/errorHandlingService';
import {setTabNameAndIcon} from 'c/workspaceApiService';
import {FlattenDataService} from 'c/flattenDataService'

import loadId from '@salesforce/label/c.LoadId';
import depot from '@salesforce/label/c.Depot';
import deliveryDate from '@salesforce/label/c.DeliveryDate';
import primaryGrid from '@salesforce/label/c.PrimaryGrid';
import status from '@salesforce/label/c.Status';
import orderId from '@salesforce/label/c.OrderId';
import createLoad from '@salesforce/label/c.CreateLoad';
import updateLoad from '@salesforce/label/c.UpdateLoad';
import createLoadTitle from '@salesforce/label/c.CreateLoadTitle';
import updateLoadTitle from '@salesforce/label/c.UpdateLoadTitle';
import loadDeliveryDate from '@salesforce/label/c.LoadDeliveryDate';
import quantity from '@salesforce/label/c.Quantity';
import palletSequence from '@salesforce/label/c.PickSheetPalletSequence';
import description from '@salesforce/label/c.PickSheetDescription';
import postCode from '@salesforce/label/c.PostCode';
import deliveryPointReference from '@salesforce/label/c.DeliveryPointReference';
import deliveryPointName from '@salesforce/label/c.DeliveryPointName';
import shippingAddress from '@salesforce/label/c.ShippingAddress';
import weight from '@salesforce/label/c.Weight';
import openingTimes from '@salesforce/label/c.OpeningTimes';
import fixedDeliveryInstructions from '@salesforce/label/c.FixedDeliveryInstructions';
import orderNotes from '@salesforce/label/c.OrderNotes';
import tamName from '@salesforce/label/c.TamName';

const columns = [
    {
        label: deliveryDate, fieldName: 'DeliveryDate__c', type: 'date', typeAttributes: {
            day: 'numeric',
            month: 'numeric',
            year: 'numeric',
            hour12: false
        },
        sortable: "true"
    },
    {label: loadId, fieldName: 'Load__rName', sortable: "true"},
    {label: primaryGrid, fieldName: 'Grid__c', sortable: "true"},
    {label: status, fieldName: 'Status', sortable: "true"},
    {label: quantity, fieldName: 'TotalQuantity__c', sortable: "true"},
    {label: palletSequence, fieldName: 'PalletSequence__c', sortable: "true"},
    {label: description, fieldName: 'ShortDescription__c'},
    {label: postCode, fieldName: 'ShippingPostalCode', sortable: "true"},
    {label: deliveryPointReference, fieldName: 'AccountDeliveryPointReference__c'},
    {label: deliveryPointName, fieldName: 'AccountName__c'},
    {label: shippingAddress, fieldName: 'ShippingStreet'},
    {label: weight, fieldName: 'TotalOrderWeight__c'},
    {
        label: openingTimes, fieldName: 'AccountOpeningTime__c', type: 'date', typeAttributes: {
            hour: '2-digit',
            minute: '2-digit',
            hour12: false
        }
    },
    {
        label: fixedDeliveryInstructions,
        fieldName: 'AccountFixedDeliveryInstructions__c'
    },
    {label: orderNotes, fieldName: 'Description'},
    {
        label: orderId,
        fieldName: 'orderUrl',
        type: 'url',
        typeAttributes: {label: {fieldName: 'OrderNumber'}},
        target: '_blank',
        sortable: "true"
    },
    {label: tamName, fieldName: 'CreatedByName', sortable: "true"},
];

export default class LoadPlanningScreen extends LightningElement {

    @track filterFields = [];
    @track originalTableData = [];
    @track tableData = [];
    @track selectedRows = [];
    @track loadOrdersTableData = [];
    @track loadOrderIds = [];
    @track loadOrdersTableDataDeselected = [];
    columns = columns;
    @track sortBy;
    @track sortDirection;
    toFlatten = true;
    limitOfRowsReturned = 900;
    isLoading = false;
    filterSize = 3;
    sObjectApiName = 'Order';
    @track depotPicklist = [];
    @track statusPicklist = [];

    @track selectedOrdersWeight = 0;
    @track selectedOrdersQuantity = 0;
    @track selectedOrdersDeliveryPoints = 0;

    loadId;
    @track deliveryDate;
    @track depot;

    // items for assignment component, when load is loaded
    @track loadDeliveryDate;
    @track loadDriver;
    @track loadVehicle;
    @track route;


    @track initialScreen = true;
    @track showSummary = false;
    @track showAssignment = false;
    @track showLoadLoader = false;
    @track targetStatus;
    @track selectedScenario;

    labels = {
        createLoad,
        updateLoad,
        createLoadTitle,
        updateLoadTitle,
        loadDeliveryDate
    }

    queryFields = 'Id,DeliveryDate__c,Load__r.Name,Grid__c,Status,TotalQuantity__c,Description,PalletSequence__c,ShortDescription__c,' +
        'ShippingPostalCode,Account.DeliveryPointReference__c,AccountName__c,ShippingStreet,TotalOrderWeight__c,Account.OpeningTime__c,' +
        'Account.FixedDeliveryInstructions__c,OrderNumber,CreatedBy.Name,AccountId,Depot__c,Account.DriverName__c,Route__c';

    connectedCallback() {
        Promise.all([this.fetchPicklistValues()]).then(() => {
            this.prepareFilterDefinition();
            //this.prepareActionValues();
            setTabNameAndIcon('Load Planning', 'utility:truck', 'Load Planning', this);
        });
    }

    /** Method to prepare filter fields definition for filter component. Sets class attribute.
     *
     * @author Svata Sejkora
     * @date 2022-10-11
     */
    prepareFilterDefinition() {
        try {
            this.filterFields.push(this.createInputFieldDefinitionJson('Date', 'DeliveryDate__c',
                'Delivery Date', null, null, null, 'equals', false));

            this.filterFields.push(this.createInputFieldDefinitionJson('Text', 'Grid__c',
                'Grid', null, null, null, 'contains', false));

            this.filterFields.push(this.createInputFieldDefinitionJson('Lookup', 'Driver__c',
                'Driver', null, null, 'Load__r.Driver__c', 'equals', false, 'Load__c',
                'standard:user', ['DriverFullName__c', 'Driver__c'], ['DriverFullName__c'],
                'DriverFullName__c', 'Driver__c'));

            this.filterFields.push(this.createInputFieldDefinitionJson('Picklist', 'Depot__c',
                depot, null, this.depotPicklist, null, 'equals', false));

            this.filterFields.push(this.createInputFieldDefinitionJson('Picklist', 'Status',
                'Status', null, this.statusPicklist, null, 'equals', false));

            this.filterFields.push(this.createInputFieldDefinitionJson('Lookup', 'Load__c',
                'Load Id', null, null, null, 'equals', false, 'Load__c',
                'standard:webcart', ['Name'], ['Name'], 'Name'));
        } catch (error) {
            processError(this, error);
        } finally {
            this.isLoading = false;
        }
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
     * @param disabled - true for disabled false for enabled
     * @param lookupObject - if the field is of type Lookup this is api name of the object Lookup is pointing to
     * @param iconName - name of the icon to show in lookup component, valid only for lookup type
     * @param returnFields - list of fields to be returned from query, valid only for lookup type
     * @param queryFields - filtering fields needs to be delimited with OR, valid only for lookup type
     * @param mainField - main field - visible within the Lookup itself, valid only for lookup type
     * @param returnDifferentObjectId - name of the field that should be returned as Id instead of object Id, valid only for lookup type
     *
     * @returns {Object} - object with filter field definition
     *
     * @author Svata Sejkora
     * @date 2022-10-11
     */
    createInputFieldDefinitionJson(dataType, apiName, label, value, options, soqlName, operand, disabled, lookupObject, iconName, returnFields, queryFields, mainField, returnDifferentObjectId) {
        // noinspection DuplicatedCode
        let inputFieldDefinition = {};
        inputFieldDefinition.type = dataType;
        inputFieldDefinition.name = apiName;
        inputFieldDefinition.label = label;
        inputFieldDefinition.value = value;
        inputFieldDefinition.options = [] = options;
        inputFieldDefinition.soqlName = soqlName === null ? apiName : soqlName;
        inputFieldDefinition.disabled = disabled;
        inputFieldDefinition.operand = operand;
        inputFieldDefinition.lookupObject = lookupObject;
        inputFieldDefinition.lookupIcon = iconName;
        inputFieldDefinition.index = this.filterFields.length
        inputFieldDefinition.returnFields = returnFields;
        inputFieldDefinition.queryFields = queryFields;
        inputFieldDefinition.mainField = mainField;
        inputFieldDefinition.returnDifferentObjectId = returnDifferentObjectId;
        return inputFieldDefinition;
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

    /** Method to process returned data from filter. Will empty the data table first.
     *
     * @param event event from filter component with data
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    processReturnedData(event) {
        try {
            this.tableData = [];
            this.originalTableData = [];
            // add clickable URL to the Order Number
            if (event.detail.returnedData.length > 0) {
                this.originalTableData = this.processOrderData(event.detail.returnedData);
                this.tableData = this.originalTableData;
                // load selected load orders if load is selected
                this.processLoadIdChange(this.loadId);
            } else {
                const toastSuccess = new ShowToastEvent({
                    title: 'Filter Message',
                    message: `There are no data selected based on your filters. Please change filter values combination.`,
                    variant: 'warning'
                });
                this.dispatchEvent(toastSuccess);
            }
        } catch (error) {
            processError(this, error);
        } finally {
            this.isLoading = false;
        }
    }

    /** Method to add clickable link to the order number
     *
     * @param ordersFromApex event from filter component with data
     *
     * @author Svata Sejkora
     * @date 2022-11-23
     */
    processOrderData(ordersFromApex) {
        let processedOrders = [];
        let orderUrl;
        processedOrders = ordersFromApex.map(row => {
            orderUrl = `/${row.Id}`;
            return {...row, orderUrl}
        });
        return processedOrders;
    }

    /** Method to handle selection of the scenario
     *
     * @param event event from markup with selected scenario
     *
     * @author Svata Sejkora
     * @date 2022-11-23
     */
    handleSelection(event) {
        try {
            const pickedScenario = event.target.value;
            switch (pickedScenario) {
                case 'createLoad':
                    this.prepareSettingsForScenario(false, true, true, false, 'Ready to Pick', 'createLoad');
                    this.disableAndSetValue('Unplanned', 'Status', true);
                    this.disableAndSetValue('', 'Load__c', false);
                    this.disableAndSetValue('', 'Driver__c', false);
                    break;
                case 'updateLoad':
                    this.prepareSettingsForScenario(false, true, true, true, 'Ready to Pick', 'updateLoad');
                    this.disableAndSetValue('Unplanned', 'Status', true);
                    this.disableAndSetValue('', 'Load__c', false);
                    this.disableAndSetValue('', 'Driver__c', false);
                    break;
                default:
                    console.log(pickedScenario);
            }
        } catch (error) {
            processError(this, error);
        } finally {
            this.isLoading = false;
        }
    }

    /** Method to prepare settings for scenarios, this is to populate values in class attributes
     *
     * @param initialScreen - if to show initial screen with selection
     * @param summary - if to show summaries of orders both filtered and selected are together
     * @param assignment - if to show assignment component (creating and updating load parameters)
     * @param showLoadLoader - if to show a component to load a load
     * @param targetStatus - status of order to be set when added to load
     * @param scenario - name of the scenario so the system knows where we are
     *
     * @author Svata Sejkora
     * @date 2022-11-23
     */
    prepareSettingsForScenario(initialScreen, summary, assignment, showLoadLoader, targetStatus, scenario) {
        this.initialScreen = initialScreen;
        this.showSummary = summary;
        this.showAssignment = assignment;
        this.targetStatus = targetStatus;
        this.selectedScenario = scenario;
        this.showLoadLoader = showLoadLoader;
    }

    /** Method to set attributes for the filters
     *
     * @param newValue - predefined value for the filter
     * @param filterName - name of the filter
     * @param setValue - boolean if the value should be assigned
     *
     * @author Svata Sejkora
     * @date 2022-11-23
     */
    disableAndSetValue(newValue, filterName, setValue) {
        const foundDefinition = this.filterFields.find((fieldDefinition) => {
            return fieldDefinition.name === filterName;
        });
        if (foundDefinition) {
            foundDefinition.disabled = true;
            if (setValue) {
                foundDefinition.value = newValue;
            }
        }
    }

    /** Method to handle event when summary for selected orders is recalculated = passing the values to other components
     *
     * @param event custom vent with values from child component
     *
     * @author Svata Sejkora
     * @date 2022-11-23
     */
    handleValuesCalculatedEvent(event) {
        this.selectedOrdersWeight = event.detail.totalWeight;
        this.selectedOrdersQuantity = event.detail.totalQuantity;
        this.selectedOrdersDeliveryPoints = event.detail.deliveryPoints;
    }

    /** When filter button is hit in filter component, this empties all data in this component
     *
     *
     * @author Svata Sejkora
     * @date 2022-11-23
     */
    async handleFilterResetEvent() {
        this.clearAllAttributes();
        const dynamicFilter = this.template.querySelector('c-dynamic-filter');
        await dynamicFilter.handleFilterClick();
    }

    /** Method to let user go back to selection screen
     *
     *
     * @author Svata Sejkora
     * @date 2022-11-23
     */
    handleBackButton() {
        this.clearAllAttributes();
        this.prepareSettingsForScenario(true, false, false, '', '');
    }

    /** Method that clears all attributes, so that user can start over
     *
     * @author Svata Sejkora
     * @date 2022-11-23
     */
    clearAllAttributes() {
        this.loadOrderIds = [];
        // empty date field input field
        const inputElement = this.template.querySelector('lightning-input');
        if (inputElement) {
            inputElement.value = '';
        }
        this.deliveryDate = '';
        this.loadId = null;
        this.tableData = [];
        this.originalTableData = [];
        this.selectedRows = [];
        this.loadOrdersTableData = [];
        this.loadOrdersTableDataDeselected = [];
        this.selectedOrdersWeight = 0;
        this.clearPreselectedAttributes();
    }

    /** Method to clear only attributes related to load. As there is many logic around loads, we might want to
     * clear its values but not the others.
     *
     *
     * @author Svata Sejkora
     * @date 2022-11-23
     */
    clearPreselectedAttributes() {
        this.loadDeliveryDate = '';
        this.loadDriver = null;
        this.loadVehicle = null;
        this.depot = null;
        this.route = null;
    }

    /** Method to handle selection of rows. Currently, all current selection is removed and new fields are added
     *
     * @param event - event that fires when rows are selected
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    handleSelectRowsEvent(event) {
        try {
            const selectedRows = event.detail.selectedRows;
            // properly populate unselected rows in load related orders
            this.processSelectionChanges(selectedRows);
            this.selectedRows = [];
            this.selectedRows = [...selectedRows];
            if (this.selectedScenario === 'createLoad') {
                if (this.selectedRows.length > 0) {
                    this.preCalculateValues();
                } else {
                    this.clearPreselectedAttributes();
                }
            }
        } catch (error) {
            processError(this, error);
            console.error(error);
        } finally {
            this.isLoading = false;
        }
    }

    /** Method to precalculate values based on predominant value from selected lines - active only when creating load
     *  this is the place where a values to evaluate are defined. If adding new fields, you need to add them to the
     *  query as well and then add what should happen with the outcome. Logic itself will work for any number of attributes
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    preCalculateValues() {
        let calculationStorage = {
            DeliveryDate__c: {},
            AccountDriverName__c: {},
            Route__c: {},
            Depot__c: {}
        };
        this.loadDataFromOrders(calculationStorage);
        this.determineIfValuesCanBeUsedForPreselection(calculationStorage);
        this.preSelectValues(calculationStorage)
    }

    /** Method to iterate selected orders and count each evaluated attribute values
     *
     * @param calculationStorage object where the evaluated attribute's values are stored
     *
     * @author Svata Sejkora
     * @date 2022-11-23
     */
    loadDataFromOrders(calculationStorage) {
        this.selectedRows.forEach((row) => {
            for (const property in row) {
                if (calculationStorage.hasOwnProperty(property)) {
                    let specificField = calculationStorage[property];
                    if (specificField.hasOwnProperty(row[property])) {
                        specificField[row[property]] += 1;
                    } else {
                        specificField[row[property]] = 1;
                    }
                }
            }
        });
    }

    /** Method to check distribution of evaluated values. allows to be preselected only for predominant values.
     *
     * @param calculationStorage object where the evaluated attribute's values are stored
     *
     * @author Svata Sejkora
     * @date 2022-11-23
     */
    determineIfValuesCanBeUsedForPreselection(calculationStorage) {
        for (const property in calculationStorage) {
            let sortable = [];

            for (let key of Object.keys(calculationStorage[property])) {
                sortable.push([key, calculationStorage[property][key]]);
            }

            sortable.sort(function (a, b) {
                return b[1] - a[1];
            });
            if (sortable.length > 1 && sortable[0][1] > sortable[1][1]) {
                this.populateAllowToUse(calculationStorage[property], sortable[0][0], true);
            } else if (sortable.length === 1) {
                this.populateAllowToUse(calculationStorage[property], sortable[0][0], true);
            } else {
                this.populateAllowToUse(calculationStorage[property], null, false)
            }
        }
    }

    /** Method to set attributes of tracking object
     *
     * @param propertyToUpdate property object to add attribute to
     * @param value - predominant value, or null
     * @param allowed - if the usage of pre-fill is allowed
     *
     * @author Svata Sejkora
     * @date 2022-11-23
     */
    populateAllowToUse(propertyToUpdate, value, allowed) {
        propertyToUpdate['canBeUsed'] = allowed;
        propertyToUpdate['valueToUse'] = value;
    }

    /** Method that takes evaluation object and based on the data in it, it will set values for properties that are considered
     * for prefill. If prefill is not allowed any values will be removed to assure data validity
     *
     * @param calculationStorage object where the evaluated attribute's values are stored
     *
     * @author Svata Sejkora
     * @date 2022-11-23
     */
    async preSelectValues(calculationStorage) {
        for (const property in calculationStorage) {
            switch (property) {
                case 'DeliveryDate__c' :
                    calculationStorage[property].hasOwnProperty('canBeUsed') && calculationStorage[property]['canBeUsed'] === true ?
                        this.loadDeliveryDate = calculationStorage[property]['valueToUse'] : this.loadDeliveryDate = '';
                    break;
                case 'AccountDriverName__c':
                    if (calculationStorage[property].hasOwnProperty('canBeUsed') && calculationStorage[property]['canBeUsed'] === true) {
                        const vehicle = await fetchVehicle({driverName: calculationStorage[property]['valueToUse']});
                        if (vehicle) {
                            this.loadDriver = vehicle.Driver__c;
                            this.loadVehicle = vehicle.Id;
                        }
                    } else {
                        this.loadDriver = null;
                        this.loadVehicle = null;
                    }
                    break;
                case 'Route__c':
                    calculationStorage[property].hasOwnProperty('canBeUsed') && calculationStorage[property]['canBeUsed'] === true ?
                        this.route = calculationStorage[property]['valueToUse'] : this.route = null;
                    break;
                case 'Depot__c':
                    calculationStorage[property].hasOwnProperty('canBeUsed') && calculationStorage[property]['canBeUsed'] === true ?
                        this.depot = calculationStorage[property]['valueToUse'] : this.depot = null;
                    break;
            }
        }
    }

    handleSpinnerChange(event) {
        this.isLoading = event.detail;
    }

    processSelectionChanges(selectedRows) {
        const selectedRowIdsSet = new Set(selectedRows.map(order => order.Id));
        const deselectedRowsSet = new Set(this.loadOrdersTableDataDeselected.map(order => order.Id));
        let deselectedOrders = [];

        this.loadOrdersTableData.forEach((order) => {
            if (selectedRowIdsSet.has(order.Id) && deselectedRowsSet.has(order.Id)) {
                // deselected order selected again
                this.loadOrdersTableDataDeselected.splice(this.loadOrdersTableDataDeselected.findIndex(orderDes => orderDes.Id === order.Id, 1));
            } else if (!selectedRowIdsSet.has(order.Id) && !deselectedRowsSet.has(order.Id)) {
                // deselected order, only adding it once to the list
                deselectedOrders.push(order);
            }
        });
        this.loadOrdersTableDataDeselected = [...this.loadOrdersTableDataDeselected, ...deselectedOrders];
    }

    /** Method to return true when the filter values are laoded, as we are loading some data from apex we need to show only when filters are loaded
     *
     * @returns {boolean} - true when there is at least 1 filtered value definition
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    get filterDataReady() {
        return Boolean(this.filterFields.length > 0);
    }

    /** Method to return true when there are data to show
     *
     * @returns {boolean} - true when there is at least 1 returned data
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    get showTable() {
        return Boolean(this.tableData.length > 0 || this.loadOrdersTableData.length > 0);
    }

    /** Method to obtain Ids of orders from the list of order objects
     *
     * @author Svata Sejkora
     * @date 2022-10-07
     */
    get selectedOrdersIds() {
        let selectedIds = [];
        this.selectedRows.forEach((order) => {
            selectedIds.push(order.Id);
        });
        return selectedIds;
    }


    /** table with orders related to load functions */

    handleLookupSelection(event) {
        try {
            const loadId = event.detail.id;
            if (loadId && loadId !== this.loadId) {
                this.processLoadIdChange(loadId);
            } else if (!loadId) {
                this.processLoadIdChange(null);
            }
        } catch (error) {
            processError(this, error);
            console.error(error);
        } finally {
            this.isLoading = false;
        }
    }

    handleDeliveryDateSelection(event) {
        this.deliveryDate = event.target.value;
    }

    async loadOrdersForSelectedLoad(loadId) {
        const orders = await fetchOrdersForLoad({fieldsToGet: this.queryFields, loadId: loadId});
        if (orders) {
            const flattener = new FlattenDataService();
            let flattenedOrders = flattener.flattenData(orders);
            flattenedOrders = this.processOrderData(flattenedOrders);
            return flattenedOrders;
        } else {
            return null;
        }
    }

    async processLoadIdChange(loadId) {
        this.loadId = loadId;
        // remove all loadOrders from everywhere no matter the change
        this.tableData = this.removeOrdersFromList(this.tableData, this.loadOrdersTableData);
        this.selectedRows = [];
        this.loadOrdersTableData = [];
        this.loadOrderIds = [];
        // check if the operation has loadId, if so do more steps, otherwise we are done.
        if (loadId) {
            // load new Load Id
            const newLoadOrders = await this.loadOrdersForSelectedLoad(loadId);
            await this.getLoadDataAndPopulate(loadId);
            if (newLoadOrders) {
                // add data where needed
                this.loadOrdersTableData = [...newLoadOrders];
                this.tableData = [...this.tableData, ...newLoadOrders];
                this.selectedRows = [...newLoadOrders];
                // using time out to make sure we try to set selected rows after the table is rendered
                setTimeout(() => this.loadOrderIds = newLoadOrders.map(record => record.Id));
            } else {
                const toastSuccess = new ShowToastEvent({
                    title: 'Load Orders',
                    message: `There are no orders linked to selected Load.`,
                    variant: 'warning'
                });
                this.dispatchEvent(toastSuccess);
            }
        } else {
            this.loadDriver = null;
            this.loadDeliveryDate = null;
            this.loadVehicle = null;
        }
    }

    async getLoadDataAndPopulate(loadId) {
        const loadData = await fetchLoadData({loadId: loadId});
        this.loadDriver = loadData.Driver__c;
        this.loadDeliveryDate = loadData.DeliveryDate__c;
        this.loadVehicle = loadData.Vehicle__c;
        this.route = loadData.RouteIdentification__c;
    }

    removeOrdersFromList(listToRemoveOrdersFrom, ordersToRemove) {
        const orderIdsToRemoveSet = new Set(ordersToRemove.map(order => order.Id));

        return listToRemoveOrdersFrom.filter((order) => {
            return !orderIdsToRemoveSet.has((order.Id));
        });
    }

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(fieldName, direction) {
        let parseData = JSON.parse(JSON.stringify(this.tableData));
        // Return the value stored in the field
        let keyValue = (order) => {
            return order[fieldName];
        };
        // checking reverse direction
        let isReverse = direction === 'asc' ? 1 : -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.tableData = parseData;
    }

    get showLoadLookup() {
        return Boolean(this.deliveryDate && this.deliveryDate.length > 0);
    }

    get addOrdersToLoad() {
        return Boolean(this.selectedScenario === 'updateLoad');
    }

    get loadSelectionFilter() {
        return `(DeliveryDate__c = ${this.deliveryDate})`;
    }

    get assignmentOperationLabel() {
        return this.selectedScenario === 'createLoad' ? 'Create Load' : 'Update Load';
    }

    get ordersDefaultFilter() {
        return ` AND (RecordType.DeveloperName = 'TelesalesOrder' OR RecordType.DeveloperName = 'FieldDirectOrder' OR
          RecordType.DeveloperName = 'EDIOrder' OR RecordType.DeveloperName = 'ECommerceOrder' 
          OR RecordType.DeveloperName = 'ReturnOrder')`
    }
}
