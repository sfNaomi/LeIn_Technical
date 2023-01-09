import { LightningElement, wire } from 'lwc';
import getImageFiles from '@salesforce/apex/ImageViewerController.getImageFiles';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import AUDIT_OBJECT from '@salesforce/schema/aforza__Audit__c';
import TYPE_FIELD from '@salesforce/schema/aforza__Audit__c.aforza__Type__c';
import STATUS_FIELD from '@salesforce/schema/aforza__Audit__c.aforza__Status__c';
import { NavigationMixin } from 'lightning/navigation';

export default class ImageViewer extends NavigationMixin(LightningElement) {

    allRecord;
    typeOptions;
    statusOptions;
    selectedType;
    selectedStatus;
    selectedObject;
    selectedAccount;
    selectedStart;
    selectedEnd;
    showNoRecord = false;
    updatedRecords = [];
    approvedIdSet = [];
    isLoaded = false;
    selectedFileId;
    showFileModal = false;
    objName = 'Asset';
    fieldName = 'AccountId';

    get objectOptions() {
        return [
            { label: '---None---', value: '' },
            { label: 'Audit', value: 'Audit' },
            { label: 'Audit Asset', value: 'Audit Asset' },
            { label: 'Visit', value:'Visit' }
        ];
    }
   
    @wire(getObjectInfo, { objectApiName: AUDIT_OBJECT })
    auditObjDefinition;
    @wire(getPicklistValues, {
        recordTypeId: '$auditObjDefinition.data.defaultRecordTypeId',
        fieldApiName: TYPE_FIELD
    }
    )
    typePicklistOptions({ error, data }) {
        if (data) {
            let picklistOption = [];
            let picklistObj = { label: '---None---', value: '' };
            picklistOption.push(picklistObj);
            data.values.forEach(element => {
                picklistOption.push(element);
            });
            this.typeOptions = picklistOption;
        } else if (error) {
            this.error = error;
        }
    };

    @wire(getPicklistValues, {
        recordTypeId: '$auditObjDefinition.data.defaultRecordTypeId',
        fieldApiName: STATUS_FIELD
    }
    )
    statusPicklistOptions({ error, data }) {
        if (data) {
            let picklistOption = [];
            let picklistObj = { label: '---None---', value: '' };
            picklistOption.push(picklistObj);
            data.values.forEach(element => {
                picklistOption.push(element);
            });
            this.statusOptions = picklistOption;
        } else if (error) {
            this.error = error;
        }
    };

    connectedCallback() {
        this.getTableData();
    }

    getTableData() {
        this.isLoaded = true;
        getImageFiles({
            selectType: this.selectedType,
            selectStatus: this.selectedStatus,
            selectObject: this.selectedObject,
            selectAccount: this.selectedAccount,
            selectStart: this.selectedStart,
            selectEnd: this.selectedEnd,
        })
            .then(result => {
                if (result) {
                    this.isLoaded = false;
                    this.showNoRecord = false;
                    this.allRecord = result;
                    this.updatedRecords = [...result.genericDto];
                    this.typeOption = this.allRecord.typepicklist;
                    if (this.allRecord.genericDto?.length == 0) {
                        this.showNoRecord = true;
                    }
                } else {
                    this.isLoaded = false;
                    this.showNoRecord = true;
                }
            })
            .catch(error => {
                this.isLoaded = false;
                this.showNoRecord = true;
                this.error = error;
            });
    }

    handleTypeChange(event) {
        this.selectedType = event.target.value;
    }

    handleStatusChange(event) {
        this.selectedStatus = event.target.value;
    }

    handleObjectChange(event) {
        this.selectedObject = event.target.value;
    }

    handleAccountChange(event) {
        this.selectedAccount = event.target.value;
    }

    handleStartDateChangeEvent(event) {
        this.selectedStart = event.target.value;
    }

    handleEndDateChangeEvent(event) {
        this.selectedEnd = event.target.value;
    }

    handleSearch() {
        this.getTableData();
    }

    handleEventName(event) {
        this.eventName = event.target.value;
    }

    handleRowSelection(event) {
        let recordId = event.target.dataset.id;
        let index;
        if (event.target.checked) {
            this.approvedIdSet.push(recordId);
        } else {
            if (this.approvedIdSet.indexOf(recordId) != -1) {
                index = this.approvedIdSet.indexOf(recordId);
                this.approvedIdSet.splice(index, 1);
            }
        }
    }

    handleSelectAll(event) {
        let i;
        let checkboxes = this.template.querySelectorAll('[data-check ="toogle"]');
        for (i = 0; i < checkboxes.length; i++) {
            checkboxes[i].checked = event.target.checked;
        }
        if (event.target.checked) {
            let allApprovals = [];
            this.allRecord.genericDto.forEach(element => {
                allApprovals.push(element.Id);
            });
            this.approvedIdSet = allApprovals;
        }

        else {
            this.approvedIdSet = [];
        }
    }

    selectFile(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: event.target.dataset.id
            }
        })

    }
 
    closeFileModal() {
        this.selectedFileId = '';
        this.showFileModal = false;
    }

    handleClear() {
        this.selectedType = null;
        this.selectedStatus = null;
        this.selectedObject = null;
        this.selectedAccount = null;
        this.selectedStart = null;
        this.selectedEnd = null;
        this.template.querySelectorAll('.filters').forEach(element => {
            element.value = '';
        });
        this.template.querySelector('c-multi-picklist').clear();
        this.getTableData();
    }

    showToast(title, message, variant) {
        const showSuccess = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(showSuccess);
    }

    handleDownloadImage(event) {
        let documentId = [];
        let baseUrl;
        if (this.allRecord && this.approvedIdSet) {
            this.allRecord?.genericDto.forEach(element => {
                if (this.approvedIdSet.includes(element.Id)) {
                    documentId.push(element.fileId);
                    baseUrl = element.url;
                }
            });
        }

        let imags = JSON.stringify(documentId);
        imags = imags.replace('[', '');
        imags = imags.replace(']', '');
        imags = imags.replaceAll('"', '');
        imags = imags.replaceAll(',', '/');
        if (imags) {
            let imageUrl = baseUrl + '/sfc/servlet.shepherd/document/download/' + imags + '?operationContext=S1';
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: imageUrl
                },
                state: {
                    selectedRecordId: event.target.dataset.id
                }
            })
        }
        else {
            this.showToast('Warning', 'Please Select Atleast one for download.', 'Warning')
        }
    }
     
    navigateToRecord(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.target.value,
                actionName: 'view',
            }
        });
    }
}