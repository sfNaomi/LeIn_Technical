/**
 * Created by magdalena.stanciu on 16.10.2022.
 */

public with sharing class PickSheetPDFController {

    public List<PickSheetGenerationService.LoadPlan> loadPlans { get; set; }

    /**
    * @description controller for pick sheet VF page; passed orders ids from url query string to the services and
    * retrieves the generated load plans from the service
    *
    * @author Magdalena Stanciu
    * @date 2022-10-18
    */
    public PickSheetPDFController () {
        String urlParam = ApexPages.currentPage().getParameters().get('p');

        List<String> orderIds = new List<String>();
        if (!String.isEmpty(urlParam)) {
            orderIds = urlParam.split(',');
        }

        PickSheetGenerationService service = new PickSheetGenerationService(orderIds);
        this.loadPlans = service.getLoadPlans();
    }
}