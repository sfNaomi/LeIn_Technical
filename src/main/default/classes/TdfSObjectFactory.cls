/**
 * @description SObject factory provides creation of a desired type of SObject.
 *
 * Class provides two types of methods:
 *       i) create methods, which creates a list of SObjects without insertion
 *      ii) insert methods, which creates and inserts a list of SObjects
 *
 * SObject is created from template class.
 * If no template class is available for current type TdfSObjectFactoryException is thrown.
 *
 * Moreover, you can define SObject fields that will override template values.
 *
 * @author  Svata Sejkoda
 * @date    2022-06-02
 */
@IsTest
public with sharing class TdfSObjectFactory {

    /**
     * @description This class is not supposed to be instantiated.
     *
     */
    private TdfSObjectFactory() {
    }

    /**
     * @description Factory method will create and insert an SObject of a desired type specified with a parameter.
     * SObject parameter can optionally have fields that will override template values.
     *
     * If you want to just create SObject without insertion use createSObject.
     *
     * @param userDefinedSObject the SObject instance of a desired type. Optionally with values that will override template ones.
     *
     * @return inserted SObject.
     *
     * @author  Svata Sejkoda
     * @date    2022-06-02
     */
    public static SObject insertSObject(SObject userDefinedSObject) {
        return insertSObjects(userDefinedSObject, 1)[0];
    }

    /**
     * @description Factory method will create and insert a list of SObjects of a desired type specified with a parameter.
     * SObject parameter can optionally have fields that will override template values.
     *
     * If you want to just create SObjects without insertion use createSObjects.
     *
     * @param userDefinedSObject the SObject instance of a desired type. Optionally with values that will override template ones.
     * @param count number of created and inserted SObjects.
     *
     * @return list of inserted SObjects.
     *
     * @author  Svata Sejkoda
     * @date    2022-06-02
     */
    public static List<SObject> insertSObjects(SObject userDefinedSObject, Integer count) {
        checkRecordTypePopulated(userDefinedSObject);
        // create default template for specific SObject type with userDefinedSObject
        TdfSObjectTemplate template = TdfSObjectTemplateFactory.createTemplate(userDefinedSObject);
        List<SObject> sObjects = createSObjectsFromTemplate(template, count);

        Database.DMLOptions dmlOptions = template.getDMLOptions();
        dmlOptions.optAllOrNone = true;

        try {
            Database.insert(sObjects, dmlOptions);
        } catch (Exception ex) {
            throw new Exceptions.TdfSObjectFactoryException('SObject ' + userDefinedSObject.getSObjectType() + ' cannot be inserted: ' + ex.getMessage(), ex);
        }

        return sObjects;
    }

    /**
     * @description Factory method will create an SObject of a desired type specified by a parameter.
     * SObject parameter can optionally have fields that will override template values.
     *
     * If you want to create and insert SObject in one call use insertSObject method instead.
     *
     * @param userDefinedSObject the SObject instance of a desired type. Optionally with values that will override template ones.
     *
     * @return created SObject.
     *
     * @author  Svata Sejkoda
     * @date    2022-06-02
     */
    public static SObject createSObject(SObject userDefinedSObject) {
        return createSObjects(userDefinedSObject, 1)[0];
    }

    /**
     * @description Factory method will create list of SObjects of a desired type specified with a parameter.
     * SObject parameter can optionally have fields that will override template values.
     *
     * If you want to create and insert SObjects in one call use insertSObjects method instead.
     *
     * @param userDefinedSObject the SObject instance of a desired type. Optionally with values that will override template ones.
     * @param count number of created SObjects.
     *
     * @return list of created SObjects.
     *
     * @author  Svata Sejkoda
     * @date    2022-06-02
     */
    public static List<SObject> createSObjects(SObject userDefinedSObject, Integer count) {
        checkRecordTypePopulated(userDefinedSObject);
        // Create default template for specific SObject type with userDefinedSObject
        TdfSObjectTemplate template = TdfSObjectTemplateFactory.createTemplate(userDefinedSObject);

        return createSObjectsFromTemplate(template, count);
    }

    /**
     * @description Create sobjects from a template using createMergedSObject method on the template.
     *
     * @param template the sobject template used for creating merged sobjects.
     * @param count the count of created sobjects.
     *
     * @return list of template SObjects.
     *
     * @author  Svata Sejkoda
     * @date    2022-06-02
     */
    private static List<SObject> createSObjectsFromTemplate(TdfSObjectTemplate template, Integer count) {
        List<SObject> sObjects = new List<SObject>();

        for (Integer i = 0; i < count; ++i) {
            // Add new merged SObject of template SObject and userDefinedSObject
            sObjects.add(template.createMergedSObject());
        }

        return sObjects;
    }

    /**
     * throws exception if sobject has multiple record types and in userDefinedSObject is not specified RecordTypeId
     *
     * @param userDefinedSObject - an object that is passed from user
     *
     * @author  Svata Sejkoda
     * @date    2022-06-02
     */
    private static void checkRecordTypePopulated(SObject userDefinedSObject) {
        Boolean hasMultipleRecordTypes = userDefinedSObject.getSObjectType().getDescribe().recordTypeInfos.size() > 1;
        if (hasMultipleRecordTypes && userDefinedSObject.get('RecordTypeId') == null) {
            String sObjectName = userDefinedSObject.getSObjectType().getDescribe().getName();
            throw new IllegalArgumentException('For sobject with multiple record types (' + sObjectName + ') must be specified RecordTypeId (use RecordTypes class)');
        }
    }
}