/**
 * Test class for TDF_SObjectTemplate.
 *
 * @author  Svata Sejkoda
 * @date    2022-06-02
 *
 */
@IsTest
private class TdfSObjectTemplateTest {
    /**
     * @description Test implementation allows TDF functionality to be distributed separately as one piece.
     */
    private with sharing class TdfTestTemplate extends TdfSObjectTemplate {
        public override void init() {
        }

        public override SObject createTemplateSObject() {
            return new Account(
                    Name = 'Default Name',
                    NumberOfEmployees = 0,
                    AnnualRevenue = Integer.valueOf(getUniqueValue()),
                    Website = 'www.defaultwebsite.com'
            );
        }
    }

    @IsTest
    private static void testCreateMergedSObject() {
        // Never initialize TDF_SObjectTemplate directly, use TDF_SObjectTemplateFactory.createTemplate() method.
        // This is for TDF_SObjectTemplate test and coverage purpose only.
        TdfSObjectTemplate template = new TdfTestTemplate();
        template.setUserDefinedSObject(
                new Account(
                        NumberOfEmployees = null,
                        Website = 'www.overriddenwebsite.com'
                )
        );
        // check default DML options, for coverage purpose here
        Database.DMLOptions dmlOptions = template.getDMLOptions();
        System.assert(dmlOptions.assignmentRuleHeader.useDefaultRule);
        System.assert(dmlOptions.duplicateRuleHeader.allowSave);

        template.init();

        Account created = (Account) template.createMergedSObject();
        System.assertEquals('Default Name', created.Name);
        System.assertEquals(null, created.NumberOfEmployees);
        System.assertEquals('www.overriddenwebsite.com', created.Website);
    }
}
