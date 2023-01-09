import {LightningElement, track, wire, api} from 'lwc';
import {getRecord} from 'lightning/uiRecordApi';
import {refreshApex} from "@salesforce/apex";
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import displayAccounts from '@salesforce/apex/SegmentEvaluator.displayAccounts';
import callGetColumns from '@salesforce/apex/DatatableService.callGetColumns';

export default class SegmentViewer extends LightningElement {
    @api recordId;
    @api searchTerm = '';

    //Fields for Accounts
    @track segments
    @track error = false;
    @track loading = true;
    @track data;
    @track columns;

    //Fields for Pagination    
    @track page = 1;
    @track items = [];
    @track data = [];
    @track startingRecord = 1;
    @track endingRecord = 0;
    @track pageSize = 25;
    @track totalRecountCount = 0;
    @track totalPage = 0;

    @track sortBy;
    @track sortDirection;

    accounts;

    @wire(getRecord, {recordId: '$recordId', fields: ['aforza__Segment__c.Id']})
    wiredRecord({error, data}) {
        if (data) {
            this.loading = true;
            refreshApex(this.accounts);
            refreshApex(this.items);
            refreshApex(this.totalRecountCount);
            refreshApex(this.totalPage);
            refreshApex(this.data);
            refreshApex(this.endingRecord);
            refreshApex(this.page);
        }
    }

    handleRetry() {
        this.error = false;
        this.loading = true;
        refreshApex(this.accounts);
    }

    @wire(displayAccounts, {recordId: '$recordId', searchTerm: '$searchTerm'})
    getAccounts(result) {
        this.error = false;
        this.loading = false;
        this.accounts = result;
        console.log('Result ====> ' + JSON.stringify(result));
        if (result !== '{}' && result !== undefined) {

            this.items = result.data;
            if (this.items !== undefined) {
                this.flattenedAccounts = [];
                for (var i = 0; i < this.accounts.data.length; i++) {
                    this.flattenedAccounts.push(this.flattenJSON(this.accounts.data[i]));
                }
                console.log('flattened data ', JSON.stringify(this.flattenedAccounts));
                this.items = this.flattenedAccounts;

                this.totalRecountCount = this.items.length;
                this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
                if (this.totalPage === 0) {
                    this.totalPage = 1;
                }
                this.data = this.items.slice(0, this.pageSize);
                this.endingRecord = this.pageSize;
            } else if (result.error) {
                this.error = true;
                console.log('Error=====> ' + JSON.stringify(result.error));
                console.log('Error body ====> ' + result.error.body);
                if (typeof result.error.body.exceptionType === 'undefined') {
                    const errorEvent = new ShowToastEvent({
                        variant: 'error',
                        message: 'User does not have correct permissions to perform this operation',
                        title: 'Error'
                    });
                    this.dispatchEvent(errorEvent);
                } else {
                    const errorEvent = new ShowToastEvent({
                        variant: 'error',
                        message: 'Query may have taken too long or returned to much data. Segment Viewer does not support segments with > 10,000 accounts. If you expect results please click Retry',
                        title: 'Error'
                    });
                    this.dispatchEvent(errorEvent);
                }
            }
        }
    }

    flattenedAccounts = [];

    flattenJSON(data) {
        var result = {};

        function recurse(cur, prop) {
            if (Object(cur) !== cur) {
                result[prop] = cur;
            } else if (Array.isArray(cur)) {
                for (var i = 0, l = cur.length; i < l; i++)
                    recurse(cur[i], "");
                if (l === 0)
                    result[prop] = [""];
            } else {
                var isEmpty = true;
                for (var p in cur) {
                    isEmpty = false;
                    recurse(cur[p], prop ? prop + "." + p : p);
                }
            }
        }

        recurse(data, "");
        return result;
    }

    @wire(callGetColumns)
    colResult(result) {
        console.log('columns ', JSON.stringify(result.data));
        this.columns = result.data;
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        this.page = 1;
        return refreshApex(this.flattenedAccounts);
    }

    handleSort(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(event.detail.fieldName, event.detail.sortDirection);
    }

    constructor() {
        super();
        this.getAccounts();
    }


    sortData(fieldname, direction) {

        let sortedList = this.items;

        let keyValue = (a) => {
            return a[fieldname];
        };


        let isReverse = direction === 'asc' ? 1 : -1;

        sortedList.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';

            return isReverse * ((x > y) - (y > x));
        });

        this.items = sortedList;
        this.data = this.items.slice(0, this.pageSize);
        this.page = 1;
    }

    downloadCSVFile() {
        let rowEnd = '\n';
        let csvString = '\ufeff'; //UTF-8 BOM to force Excel to render CSV as UTF-8
        let rowData = new Set();

        // getting keys from data
        this.flattenedAccounts.forEach(function (record) {
            Object.keys(record).forEach(function (key) {
                rowData.add(key);
            });
        });

        // Array.from() method returns an Array object from any object with a length property or an iterable object.
        rowData = Array.from(rowData);

        csvString += rowData.join(',');
        csvString += rowEnd;

        // main for loop to get the data based on key value
        for (let i = 0; i < this.flattenedAccounts.length; i++) {
            let colValue = 0;

            for (let key in rowData) {
                if (rowData.hasOwnProperty(key)) {

                    let rowKey = rowData[key];

                    if (colValue > 0) {
                        csvString += ',';
                    }

                    let value = this.flattenedAccounts[i][rowKey] === undefined ? '' : this.flattenedAccounts[i][rowKey];

                    csvString += '"' + value + '"';
                    colValue++;
                }
            }
            csvString += rowEnd;
        }

        let downloadElement = document.createElement('a');

        // This  encodeURI encodes special characters, except: , / ? : @ & = + $ # (Use encodeURIComponent() to encode these characters).
        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvString);
        downloadElement.target = '_self';
        downloadElement.download = new Date().toISOString() + ' Segment Account Data.csv';
        document.body.appendChild(downloadElement);
        downloadElement.click();
    }

    previousHandler() {
        if (this.page > 1) {
            this.page = this.page - 1;
            this.displayRecordPerPage(this.page);
        }
    }

    nextHandler() {
        if ((this.page < this.totalPage) && this.page !== this.totalPage) {
            this.page = this.page + 1;
            this.displayRecordPerPage(this.page);
        }
    }

    displayRecordPerPage(page) {
        this.startingRecord = ((page - 1) * this.pageSize);
        this.endingRecord = (this.pageSize * page);

        this.endingRecord = (this.endingRecord > this.totalRecountCount)
            ? this.totalRecountCount : this.endingRecord;

        this.data = this.items.slice(this.startingRecord, this.endingRecord);

        this.startingRecord = this.startingRecord + 1;

    }

    value = '25';

    get options() {
        return [
            {label: '25', value: '25'},
            {label: '50', value: '50'},
            {label: '100', value: '100'},
            {label: 'All', value: '50000'}
        ];
    }

    handlePageSizeChange(event) {
        this.pageSize = parseInt(event.detail.value);
        this.value = event.detail.value;
        this.page = 1;
        this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
        return this.displayRecordPerPage(this.page);
    }
}