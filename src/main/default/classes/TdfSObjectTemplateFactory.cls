/**
 * @description Factory class for SObject templates.
 *
 * @see TdfSObjectTemplate for abstract template
 * @see TdfSObjectFactory for usage of this class
 *
 * @author  Svata Sejkoda
 * @date    2022-06-02
 */
@IsTest
public with sharing class TdfSObjectTemplateFactory {
    // this class is not supposed to be initialized
    private TdfSObjectTemplateFactory() {
    }

    /**
     * @description gets all ApexClasses that matches TDF_%Template regex. Uses lazy loading.
     */
    private static final List<ApexClass> classesMatchingTdfTemplateRegex {
        get {
            if (classesMatchingTdfTemplateRegex == null) {
                classesMatchingTdfTemplateRegex = [
                        SELECT Id, Name, Body
                        FROM ApexClass
                        WHERE Name LIKE 'Tdf%Template'
                ];
            }
            return classesMatchingTdfTemplateRegex;
        }
        set;
    }

    /**
     * @description Creates SObject template for a userDefinedSObject.
     * The userDefinedSObject's values are also used for overriding template values.
     *
     * @param userDefinedSObject the SObject for which the template will be initialized
     * @return the created TDF_SObjectTemplate
     *
     * @author  Svata Sejkoda
     * @date    2022-06-02
     */
    public static TdfSObjectTemplate createTemplate(SObject userDefinedSObject) {
        // get SObject type name
        String sObjTypeName = userDefinedSObject.getSObjectType()
                .getDescribe()
                .getName();

        // get template class name
        String templateClassName = 'Tdf' + sObjTypeName.replaceAll('__c|_', '') + 'Template';

        Type templateType = Type.forName(templateClassName);

        // try to find template class, if there is no matching default structure
        if (templateType == null) {
            templateType = findTemplateClassForSObject(
                    userDefinedSObject.getSObjectType()
            );
        }

        if (templateType != null) {
            // create template dynamically
            TdfSObjectTemplate template = (TdfSObjectTemplate) templateType.newInstance();

            // Type.newInstance() doesn't support parametrized constructor
            // so set userDefinedSObject
            template.setUserDefinedSObject(userDefinedSObject);

            // and call pseudo constructor
            template.init();

            return template;
        }

        throw new Exceptions.TdfSObjectFactoryException('Can\'t create template. SObject of type ' + sObjTypeName + ' is not supported. TemplateClassName is ' + templateClassName);
    }

    /**
     * @description all TDF template classes and tries to create instance of it and if its getSObjectType() method's result is same as passed sobject type,
     * then returns its name
     *
     * @param sObjectType sobject type for which will be template found for
     *
     * @return template class name, or null if not found
     *
     * @author  Svata Sejkoda
     * @date    2022-06-02
     */
    private static Type findTemplateClassForSObject(SObjectType sObjectType) {
        for (ApexClass klass : classesMatchingTdfTemplateRegex) {
            if (!klass.Body.contains('TdfSObjectTemplate')) {
                continue;
            }
            try {
                Object t = Type.forName(klass.Name).newInstance();
                if (t instanceof TdfSObjectTemplate && ((TdfSObjectTemplate) t).getSObjectType() == sObjectType) {
                    return Type.forName(klass.Name);
                }
            } catch (TypeException e) {
                // NOPMD
                //ignored
            }
        }
        return null;
    }
}
