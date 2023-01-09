@IsTest
private class DatatableServiceTest {
    @IsTest
    private static void callGetColumns() {
        List<DatatableService.Column> columns = DatatableService.callGetColumns();
        System.assertNotEquals(0, columns.size());
    }
}