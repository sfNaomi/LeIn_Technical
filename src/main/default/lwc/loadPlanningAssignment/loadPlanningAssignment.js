/**
 * Created by svatopluk.sejkora on 13.10.2022.
 */

import {LightningElement, api, track} from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {processError} from 'c/errorHandlingService';
import fetchVehicleLoadWeight from '@salesforce/apex/LoadPlanningAssignmentController.fetchVehicleLoadWeight'
import updateOrdersWithLoadIdAndNewStatus from '@salesforce/apex/LoadPlanningAssignmentController.updateOrdersWithLoadIdAndNewStatus'
import upsertLoad from '@salesforce/apex/LoadPlanningAssignmentController.upsertLoad'
import processDeselectedOrders from '@salesforce/apex/LoadPlanningAssignmentController.processDeselectedOrders'

export default class LoadPlanningAssignment extends LightningElement {
    @api selectedOrdersWeight;
    @api selectedOrdersIds = [];
    @api newOrderStatus;
    @api ordersDeselectedFromLoad = [];
    @api ordersAssignedToLoad = [];
    @api loadId;
    @api operation;
    @api operationLabel;
    @api loadOrderIds;
    @api selectedOrdersQuantity;
    @api selectedOrdersDeliveryPoints;
    @track vehicleLoadWeight = 0;
    _plannedDeliveryDate;
    _driverId;
    _vehicleId;
    _route;
    _depot;
    _createRoute;

    @api get plannedDeliveryDate() {
        return this._plannedDeliveryDate;
    }

    set plannedDeliveryDate(value) {
        this._plannedDeliveryDate = value;
    }

    @api get driverId() {
        return this._driverId;
    }

    set driverId(value) {
        this._driverId = value;
    }

    @api get vehicleId() {
        return this._vehicleId;
    }

    set vehicleId(value) {
        this.vehicleLoadWeight = 0;
        this._vehicleId = value;
    }

    @api get route() {
        return this._route;
    }

    set route(value) {
        this._route = value;
    }

    @api get depot() {
        return this._depot;
    }

    set depot(value) {
        this._depot = value;
    }

    @api get createRoute() {
        return this._createRoute;
    }

    set createRoute(value) {
        this._createRoute = value;
    }


    handleLookupSelection(event) {
        try {
            this.fireSpinnerChangeEvent(true);
            const lookupInput = event.target.dataset.id;
            if (lookupInput === 'vehicle') {
                this.vehicleId = event.detail.id;
                this.getVehicleLoadWeight();
            } else {
                this.driverId = event.detail.id;
            }
        } catch (error) {
            processError(this, error);
        } finally {
            this.fireSpinnerChangeEvent(false);
        }
    }

    async getVehicleLoadWeight() {
        if (this.vehicleId) {
            const vehicleLoadWeight = await fetchVehicleLoadWeight({vehicleId: this.vehicleId});
            if (vehicleLoadWeight !== 0) {
                this.vehicleLoadWeight = vehicleLoadWeight;
            } else {
                const toastWarning = new ShowToastEvent({
                    title: 'Selected Truck',
                    message: `Truck selected has no Load Weight, please select another truck`,
                    variant: 'warning'
                });
                this.dispatchEvent(toastWarning);
            }
        } else {
            this.vehicleLoadWeight = 0;
        }
    }

    handleDeliveryDateChange(event) {
        try {
            this.plannedDeliveryDate = event.target.value;
        } catch (error) {
            processError(this, error);
        }
    }

    handleRouteChange(event) {
        try {
            this.route = event.target.value;
        } catch (error) {
            processError(this, error);
        }
    }

    async handleCreateLoad() {
        try {
            this.fireSpinnerChangeEvent(true);
            const load = await this.upsertLoad();
            // compare selected orders to original load orders and process only newly selected
            const newlySelectedOrdersIds = this.filterOnlyNewlyAddedOrdersToLoad();
            if (newlySelectedOrdersIds.length > 0) {
                await this.assignNewOrdersToLoad(load);
            }
            if (this.ordersDeselectedFromLoad.length > 0) {
                await this.removeUnselectedLoadOrders(load);
            }
            this.clearSelection();
        } catch (error) {
            processError(this, error);
        } finally {
            this.fireSpinnerChangeEvent(false);
        }
    }

    filterOnlyNewlyAddedOrdersToLoad() {
        const orderIdsToRemoveSet = new Set(this.ordersAssignedToLoad.map(order => order.Id));

        return this.selectedOrdersIds.filter((id) => {
            return !orderIdsToRemoveSet.has((id));
        });
    }

    async upsertLoad() {
        const loadJson = {
            'DeliveryDate__c': this.plannedDeliveryDate,
            'Driver__c': this.driverId,
            'Vehicle__c': this.vehicleId,
            'Id': this.loadId,
            'Depot__c': this.depot,
            'TotalWeight__c': this.selectedOrdersWeight,
            'NumberOfDeliveryPoints__c': this.selectedOrdersDeliveryPoints,
            'TotalQuantity__c': this.selectedOrdersQuantity,
            'RouteIdentification__c': this.route
        };
        const load = await upsertLoad({load: loadJson});
        const toastLoadCreated = new ShowToastEvent({
            title: this.operationLabel,
            message: `The ${this.operationLabel} operation was successful on load ${load.Name}.`,
            variant: 'success'
        });
        this.dispatchEvent(toastLoadCreated);
        return load;
    }

    async assignNewOrdersToLoad(load) {
        const ordersToUpdate = this.removeOrdersPartOfLoad();
        await updateOrdersWithLoadIdAndNewStatus({
            orderIds: ordersToUpdate,
            newStatus: this.newOrderStatus,
            loadId: load.Id
        });
        const toastOrdersUpdated = new ShowToastEvent({
            title: 'Orders Updated',
            message: `The selected Orders have been updated with status ${this.newOrderStatus} and connected with Load ${load.Name}.`,
            variant: 'success'
        });
        this.dispatchEvent(toastOrdersUpdated);
    }

    removeOrdersPartOfLoad() {
        const orderIdsToRemoveSet = new Set(this.loadOrderIds);
        return this.selectedOrdersIds.filter((orderId) => {
            return !orderIdsToRemoveSet.has((orderId));
        });
    }

    async removeUnselectedLoadOrders(load) {
        await processDeselectedOrders({
           deselectedOrderIds: this.ordersDeselectedFromLoad
        });

        const toastOrdersUpdated = new ShowToastEvent({
            title: 'Orders Updated',
            message: `Deselected Orders have been updated with mapped statuses and disconnected from Load ${load.Name}.`,
            variant: 'success'
        });
        this.dispatchEvent(toastOrdersUpdated);
        this.fireToastWhenPickingInProgressOrderRemoved();
    }

    fireToastWhenPickingInProgressOrderRemoved() {
        const pickingInProgress = this.ordersDeselectedFromLoad.findIndex((order) => {
            return order.Status === 'Picking in Progress';
        });
        if (pickingInProgress !== -1) {
            const pickingProgressOrder = new ShowToastEvent({
                title: 'Picking In Progress',
                message: `There is at least one Order in "Picking in Progress" status. Please inform the pickers of the change.`,
                variant: 'warning'
            });
            this.dispatchEvent(pickingProgressOrder);
        }
    }

    fireSpinnerChangeEvent(spinning) {
        const spinnerChange = new CustomEvent('spinnerchange', {
            detail: spinning
        });
        this.dispatchEvent(spinnerChange);
    }

    clearSelection() {
        this.driverId = '';
        this.vehicleId = '';
        this.template.querySelector('lightning-input').value = '';
        this.vehicleLoadWeight = 0;
        this.fireResetEvent();
    }

    fireResetEvent() {
        const filterResetEvent = new CustomEvent('filterresetevent', {
            detail: true
        });
        this.dispatchEvent(filterResetEvent);
    }


    get driverLookupFilter() {
        return `(IsActive = TRUE AND UserRole.DeveloperName = 'Driver')`;
    }

    get vehicleReturnFields() {
        return ['VehicleRegistration__c', 'LoadCapacityWeight__c', 'LoadLimitCases__c', 'Operational__c'];
    }

    get createLoadButtonDisabled() {
        return Boolean(!this.plannedDeliveryDate || !this.driverId || !this.vehicleId || !this.route
            || this.remainingLoadWeight < 0 || !this.depot
            || (this.selectedOrdersIds.length === 0 && this.operation === 'createLoad')
            || (this.operation === 'updateLoad' && this.createRoute === true));
    }

    get vehicleQueryFields() {
        return [];
    }

    get remainingLoadWeight() {
        return this.vehicleLoadWeight - this.selectedOrdersWeight;
    }

    get overLoadWeight() {
        const normalClasses = 'slds-m-right_medium slds-float_left slds-m-top_large slds-m-left_large';
        return this.remainingLoadWeight < 0 ? `${normalClasses} slds-text-color_error` : normalClasses;
    }
}
