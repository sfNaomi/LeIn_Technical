/**
 * @description Abstract class that provides functionality for creating a merged SObject of a template SObject and a userDefinedSObject.
 *
 * This class has to be extended by classes with naming convention as Tdf{SObjectName}Template,
 * the SObjectName has no '_' and '__c'.
 * Examples of class names: TdfAccountTemplate, TdfContactTemplate etc.
 *
 * @author  Svata Sejkoda
 * @date    2022-06-02
 */
public abstract with sharing class TdfSObjectTemplate {
    protected SObject userDefinedSObject;

    private static Long counter = 0;

    /**
     * @description Setter of the userDefinedSObject
     *
     * @param userDefinedSObject to be set
     *
     * @author  Svata Sejkoda
     * @date    2022-06-02
     */
    public void setUserDefinedSObject(SObject userDefinedSObject) {
        this.userDefinedSObject = userDefinedSObject;
    }

    /**
     * @description Getter for dml options.
     * Default values:
     *  - userDefaultRule to true,
     *  - allowSave to true
     *
     * @return DMLOptions to be used
     *
     * @author  Svata Sejkoda
     * @date    2022-06-02
     */
    public Database.DMLOptions getDMLOptions() {
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        dmo.duplicateRuleHeader.allowSave = true;
        return dmo;
    }

    /**
     * @description Instance is created dynamically. This method compensate a constructor.
     * All operations as DML or SOQL has to be in this method.
     *
     * Example body of overriding method:
     *     Account userDefinedAccount = (Account) userDefinedSObject;
     *
     * @author  Svata Sejkoda
     * @date    2022-06-02
     */
    public abstract void init();

    /**
     * @description Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return the template SObject
     *
     * @author  Svata Sejkoda
     * @date    2022-06-02
     */
    protected abstract SObject createTemplateSObject();

    /**
     * @description Returns unique value.
     *
     * @return Long the unique value
     *
     * @author  Svata Sejkoda
     * @date    2022-06-02
     */
    protected Long getUniqueValue() {
        return ++counter;
    }

    /**
     * @description Merges a template SObject and the userDefinedSObject. Every call returns a new instance.
     *
     * @return the merged SObject
     *
     * @author  Svata Sejkoda
     * @date    2022-06-02
     */
    public SObject createMergedSObject() {
        // create SObject template
        SObject templateSObject = createTemplateSObject();

        // merge userDefinedSObject into templateSObject
        mergeSObjects(templateSObject, userDefinedSObject);

        // return merged SObject
        return templateSObject;
    }

    /**
     * @description Merges two SObjects. Copy all values from source to target.
     *
     * @param target SObject where values from source will be added
     * @param source SObject of values to be added into target
     *
     * @author  Svata Sejkoda
     * @date    2022-06-02
     */
    private void mergeSObjects(SObject target, SObject source) {
        Map<String, Object> sourceFields = source.getPopulatedFieldsAsMap();

        if (sourceFields.isEmpty()) {
            return;
        }

        for (String sourceFieldName : sourceFields.keySet()) {
            target.put(sourceFieldName, sourceFields.get(sourceFieldName));
        }
    }

    /**
     * @description returns template's sobject type, default implementation returns null and can be overriden in child implementation.
     * Used for dynamically finding template instance.
     *
     * @return null by default
     *
     * @author  Svata Sejkoda
     * @date    2022-06-02
     */
    public virtual SObjectType getSObjectType() {
        return null;
    }
}
