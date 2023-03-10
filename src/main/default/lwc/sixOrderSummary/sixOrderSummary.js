import { LightningElement, track, api, wire } from "lwc";
import getLastOrderDates from "@salesforce/apex/sixOrderSummaryController.getOrdersDates";
import getOrdersList from "@salesforce/apex/SixOrderSummaryController.getOrdersList";
import createOrder from "@salesforce/apex/SixOrderSummaryController.createOrder";
import { NavigationMixin } from "lightning/navigation";
import { processError } from "c/errorHandlingService";
import { openRecordInSubTab } from "c/workspaceApiService";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class LastSixOrdersSummary extends NavigationMixin(LightningElement) {
  @api recordId;

  @track columns = [
    {
      label: "SKU Code",
      fieldName: "StockKeepingUnit",
      wrapText: true,
      hideDefaultActions: true,
      cellAttributes: {
        class: {
          fieldName: "format",
        },
      },
    },
    {
      label: "Description",
      fieldName: "Description",
      wrapText: true,
      hideDefaultActions: true,
      cellAttributes: {
        class: {
          fieldName: "format",
        },
      },
    },
  ];

  @track isLoading = true;
  @track columnsP;
  @track skuList;
  @track orderItemList;
  @track showOrderItems;
  @track showOrders;
  @track prodData;
  @track dataF = [];
  @track sumOrderData = [];
  connectedCallback() {
    this.init();
  }

  async handleClick() {
    try {
      this.sumOrderData = this.sumOrderData.filter(function (item) {
        return item.Stock > 0 && item.isActive == true && item.offSale == false;
      });

      let createdOrderId = await createOrder({
        orderJSON: this.sumOrderData,
        accountId: this.recordId,
      });

      if (createdOrderId) {
        const toastSuccess = new ShowToastEvent({
          title: "Success",
          message: "Order has been created",
          variant: "success",
        });
        this.dispatchEvent(toastSuccess);
        let crOrdId = JSON.parse(JSON.stringify(createdOrderId));
        openRecordInSubTab(crOrdId, window);
      }
    } catch (error) {
      this.isLoading = false;
      processError(this, error);
    }
  }

  async init() {
    try {
      this.showOrdersHeaders = await getLastOrderDates({
        accountId: this.recordId,
      });
      if (this.showOrdersHeaders) {
        const headerResult = JSON.parse(JSON.stringify(this.showOrdersHeaders));
        this.columnsP = headerResult.map((dataRec) => {
          return {
            label: dataRec.EffectiveDate,
            fieldName: dataRec.effectiveDateFieldName,
            wrapText: true,
            hideDefaultActions: true,
          };
        });
        this.columnsP = [
          ...this.columns,
          ...this.columnsP,
          {
            label: "Suggested Order",
            fieldName: "Average",
            wrapText: true,
            hideDefaultActions: true,
            cellAttributes: {
              class: {
                fieldName: "format",
              },
            },
          },
          /* {
          label: "Stock Remaining",
          fieldName: "Stock",
          wrapText: true,
          hideDefaultActions: true,
          cellAttributes: {
            class: {
              fieldName: "format",
            },
          },
        },*/
        ];
        this.loadData();
      }
    } catch (error) {
      this.isLoading = false;
      processError(this, error);
    }
  }

  async loadData() {
    try {
      this.showOrderItems = await getOrdersList({
        accountId: this.recordId,
      });

      if (this.showOrderItems) {
        this.prodData = this.MapData(this.showOrderItems);

        this.prodData = this.splitPerProdId(this.prodData);
        this.prodData = this.convertToObjAndColourCode(this.prodData);
        this.isLoading = false;
        return this.prodData;
      }
    } catch (error) {
      this.isLoading = false;
      processError(this, error);
    }
  }

  MapData() {
    this.orderItemList = JSON.parse(JSON.stringify(this.showOrderItems));

    this.skuList = this.orderItemList.map((dataRec) => {
      return {
        StockKeepingUnit: dataRec?.sku,
        Description: dataRec?.description,
        [dataRec?.effectiveDate]: dataRec?.quantity,
        [dataRec?.effectiveDateFieldName]: dataRec?.quantity,
        Average: dataRec?.average,
        isActive: dataRec?.isActive,
        Id: dataRec?.id,
        productId: dataRec?.productId,
        pricebookentryid: dataRec?.pricebookentryid,
        unitPrice: dataRec?.unitPrice,
        Stock: dataRec?.stockRemaining,
        offSale: dataRec?.offSale
      };
    });
    const prodData = JSON.parse(JSON.stringify(this.skuList));

    return prodData;
  }

  splitPerProdId(prodData) {
    const prodSplitResult = prodData.reduce(
      (p, v) => (
        (p[v.productId] = {
          ...(p[v.productId] || {}),
          ...v,
        }),
        p
      ),
      {}
    );

    return prodSplitResult;
  }

  convertToObjAndColourCode(colourCodeResult) {
    const res = Object.entries(colourCodeResult).map(([name, obj]) => ({
      name,
      ...obj,
    }));
    res.forEach((ele) => {
      ele.format =
        ele.Stock <= 0 || ele.offSale ? "slds-text-color_error" : "slds-text-color_default";
    });
    this.sumOrderData = res;
    this.dataF = JSON.parse(JSON.stringify(res));
  }
}
