import { LightningElement, api } from 'lwc';
// import getRelatedFilesByRecordId from '@salesforce/apex/AuditApprovedController.getRelatedFilesByRecordId'
import {NavigationMixin} from 'lightning/navigation'
export default class DocumentZoom extends NavigationMixin(LightningElement) {
    @api recordId;

    rotator = 'overflow';
    zoomed = 'zoom';
    click = 0;
    anticlick = 0;
    zoomClick = 0;
    height = '450px';
    width = '640px';
    imageUrl;
    showModal = false;
    isZoomin = false;
    isZoomOut = true;
    showPdf = false;
    url;

    filesList;

    connectedCallback() {
        this.getImageData(this.recordId);
    }

    getImageData(recordId) {
        this.url = '/sfc/servlet.shepherd/document/download/' + recordId;
        this.previewHandler(recordId, this.url, '');
        // getRelatedFilesByRecordId({recordId : recordId})
        //     .then(result => {
        //         this.url = `/sfc/servlet.shepherd/document/download/${result.fileId}`;
        //         this.previewHandler(result.fileId, this.url, result.fileEx);
        //     })
        //     .catch(error => {
        //         this.showInfoToast('Error', 'error',  error.body.message);
        //         console.log(error);
        //     });
    }

    previewHandler(recordId, url, fileEx) {
        if (fileEx === 'pdf') {
            this.showPdf = true;
        } else {
            this.imageUrl = url;
            console.log(this.imageUrl);
            this.showModal = true;
        }
    }

    handleModalClose() {
        //this.showModal = false;
        this.rotator = 'overflow';
        this.zoomed = 'zoom';
        this.click = 0;
        this.anticlick = 0;
        this.zoomClick = 0;
        this.height = '400px';
        this.width = '500px';
        this.isZoomin = false;
        this.isZoomOut = true;
        
        this.dispatchEvent(new CustomEvent('closemodal', { detail: this.showModal }));
    }

    handleSkipforward() {
        if (this.anticlick === 1) {
            this.rotator = 'roateAntiImage0 overflow';
            this.anticlick = 0;
        } else if (this.anticlick === 2) {
            this.rotator = 'roateAntiImage90 overflow';
            this.anticlick = 1;
        }else {
            ++this.click;
            console.log('clockwise---',this.click);
            if (this.click === 1) {
                this.rotator = 'roateImage90 overflow';
            }
            
            if (this.click === 2) {
                this.rotator = 'roateImage180 overflow';
            }
            
            if (this.click === 3) {
                this.rotator = 'roateImage360 overflow';
                this.click = 0;
            }
        }
        
        
    }

    handleSkipback() {
        if (this.click === 1) {
            this.rotator = 'roateAntiImage0 overflow';
            this.click = 0;
        }else if (this.click === 2) {
            this.rotator = 'roateImage90 overflow';
            this.click = 1;
        } else {
            ++this.anticlick;
            console.log('anti-clockwise---',this.anticlick);
            if (this.anticlick === 1) {
                this.rotator = 'roateAntiImage90 overflow';
            }
            
            if (this.anticlick === 2) {
                this.rotator = 'roateAntiImage180 overflow';
            }
            
            if (this.anticlick === 3) {
                this.rotator = 'roateAntiImage360 overflow';
                this.anticlick = 0;
            }
        }
    }

    handlezoomin() {
        ++this.zoomClick;
        console.log(this.zoomClick);
        if (this.zoomClick === 1) {
            this.width = '850px';
            this.height = '600px';
            this.isZoomOut = false;
        }
        
        if (this.zoomClick === 2) {
            this.width = '1000px';
            this.height = '850px';
            this.isZoomOut = false;
        }
        
        if (this.zoomClick === 3) {
            this.width = '1200px';
            this.height = '1000px';
            this.isZoomin = true;
            this.isZoomOut = false;
        }
        
    }

    handlezoomout() {
        if (this.zoomClick === 1) {
            this.width = '640px';
            this.height = '450px';
            this.zoomClick = 0;
            this.isZoomOut = true;
            this.isZoomin = false;
        }
        
        if (this.zoomClick === 2) {
            this.width = '850px';
            this.height = '600px';
            this.zoomClick = 1;
            this.isZoomin = false;
        }
        
        if (this.zoomClick === 3) {
            this.width = '1000px';
            this.height = '850px';
            this.zoomClick = 2;
            this.isZoomin = false;
        }
    }

    handlePrint() {
        window.print();
    }
}