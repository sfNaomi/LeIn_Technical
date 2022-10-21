/**
 * Created by magdalena.stanciu on 05.09.2022.
 */

import { LightningElement, api } from 'lwc';

export default class RecordPageWarningMessage extends LightningElement {
    @api message;
    @api variant;

    get iconName() {
        return 'utility:' + this.variant.toLowerCase();
    }

    get theme() {
        return 'slds-theme_' + this.variant.toLowerCase();
    }
}