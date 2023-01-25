import { LightningElement, api} from 'lwc';
import populateDDUrlBasedOnMappings from "@salesforce/apex/DdMandateLinkController.populateDDUrlBasedOnMappings";
import {processError} from 'c/errorHandlingService';
import { NavigationMixin } from "lightning/navigation";

export default class DdMandateLink extends NavigationMixin(
  LightningElement) {
    @api recordId;

    async handleClick() {
        try {
          let getUrl= await populateDDUrlBasedOnMappings({
            accountId: this.recordId
          });
          if (getUrl) {
            const config = {
              type: 'standard__webPage',
              attributes: {
                  url: getUrl
              }
        };
          this[NavigationMixin.Navigate](config);
        }
          
        } catch (error) {
          processError(this, error);
        }
      }
}
