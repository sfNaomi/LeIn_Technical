/**
 * Created by magdalena.stanciu on 21.10.2022.
 */

public with sharing class DeliveryManifestPDFController {
    public List<DeliveryManifestGenerationService.Load> loads { get; set; }

    /**
    * @description controller for pick sheet VF page; passed orders ids from url query string to the services and
    * retrieves the generated loads from the service
    *
    * @author Magdalena Stanciu
    * @date 2022-10-18
    */
    public DeliveryManifestPDFController () {
        String urlParam = ApexPages.currentPage().getParameters().get('p');

        List<String> orderIds = new List<String>();
        if (!String.isEmpty(urlParam)) {
            orderIds = urlParam.split(',');
        }

        DeliveryManifestGenerationService service = new DeliveryManifestGenerationService(orderIds);
        this.loads = service.getLoads();
    }
}