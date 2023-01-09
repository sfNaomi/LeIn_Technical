import {ShowToastEvent} from "lightning/platformShowToastEvent";

/**
 * Created by svatopluk.sejkora on 26.09.2022.
 */

export function processError(thisArg, errorToBeParsed) {
    /**
     * @type {errorDto}
     */
    const errorDto = {
        title: '',
        message: '',
        exceptionDetail: ''
    };
    populateErrorDtosAttributes(errorDto, errorToBeParsed);
    fireToast(thisArg, errorDto);
}

function populateErrorDtosAttributes(errorDto, errorToBeParsed) {
    if (errorToBeParsed instanceof Error) {
        errorDto.title = 'Error in JavaScript code occurred.';
        errorDto.exceptionDetails = errorToBeParsed.message;
        errorDto.message = errorToBeParsed.name;
    } else if (typeof errorToBeParsed === 'string') {
        errorDto.title = 'Error in JavaScript code occurred.';
        errorDto.exceptionDetails = errorToBeParsed;
    } else if (errorToBeParsed.body !== undefined) {
        errorDto.title = errorToBeParsed.body.message;
        errorDto.exceptionDetails = 'response elem: \n' + JSON.stringify(errorToBeParsed, null, 2);
    } else {
        console.error('Error can\'t be displayed: unsupported type.', JSON.stringify(errorToBeParsed));
    }
}

function fireToast(thisArg, errorDto) {
    const toastError = new ShowToastEvent({
        title: errorDto.title,
        message: errorDto.message + '\n' + errorDto.exceptionDetails,
        variant: 'error'
    });
    thisArg.dispatchEvent(toastError);
}