/**
 * Created by svatopluk.sejkora on 13.10.2022.
 */

import {LightningElement, api, track} from 'lwc';

export default class LoadPlanningCalculation extends LightningElement {
    @api sectionName;
    @track totalQuantity = 0;
    @track totalWeight = 0;
    @track numberOfDeliveryPoints = 0;
    _orders;

    @api
    get orders() {
        return this._orders;
    }

    set orders(value) {
        this._orders = value;
        this.calculateValues();
        this.fireSendCalculatedValuesEvent();
    }

    calculateValues() {
        let deliveryPointsIds = new Set();
        this.totalWeight = 0;
        this.totalQuantity = 0;
        this.orders.forEach((order) => {
            deliveryPointsIds.add(order.AccountId);
            this.totalQuantity += order.TotalQuantity__c;
            this.totalWeight += order.TotalOrderWeight__c;
        });
        this.numberOfDeliveryPoints = deliveryPointsIds.size;
    }

    fireSendCalculatedValuesEvent() {
        if (this.sectionName === 'Selected Orders') {
            const selectedEvent = new CustomEvent('valuescalculated', {
                detail: {
                    totalWeight: this.totalWeight,
                    totalQuantity: this.totalQuantity,
                    deliveryPoints: this.numberOfDeliveryPoints
                }
            });
            this.dispatchEvent(selectedEvent);
        }
    }
}