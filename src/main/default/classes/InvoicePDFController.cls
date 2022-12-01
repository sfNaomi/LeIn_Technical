/**
 * @description       :
 * @author            : Ciuca Bianca BearingPoint GmbH
 * @group             :
 * @last modified on  : 10-06-2022
 * @last modified by  : Ciuca Bianca, BearingPoint GmbH
 **/

public with sharing class InvoicePDFController {
	public List<InvoiceGenerationService.Invoice> invoices { get; set; }

	/**
    * @description controller for invoice VF page; passed invoice ids from url query string to the services and
    * retrieves the generated invoices from the service
    *
    * @author Magdalena Stanciu
    * @date 2022-11-08
    */
	public InvoicePDFController() {
		String urlParam = ApexPages.currentPage().getParameters().get('p');

		List<String> invoiceIds = new List<String>();
		if (!String.isEmpty(urlParam)) {
			invoiceIds = urlParam.split(',');
		}

		this.invoices = new InvoiceGenerationService(invoiceIds).generateData();
	}
}