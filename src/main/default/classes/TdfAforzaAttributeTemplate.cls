/**
 * Created by svatopluk.sejkora on 05.10.2022.
 */

@IsTest
public class TdfAforzaAttributeTemplate extends TdfSObjectTemplate {
    private static Integer counter = 0;
    private Id categoryId;
    /**
     * Instance is created dynamically. This method compensates a constructor.
     *
     * @author  Svata Sejkora
     * @date    2022-10-04
     *
     */
    public override void init() {
        aforza__Attribute__c userDefinedAttribute = (aforza__Attribute__c) userDefinedSObject;

        if (userDefinedAttribute.aforza__Attribute_Category__c == null) {
            categoryId = TdfSObjectFactory.insertSObject(new aforza__Attribute_Category__c()).Id;
        }
    }

    /**
     * Creates a template SObject. Every call returns a new instance.
     *
     * Because this method can be called multiple times, all operations as DML or SOQL has to be done in init().
     *
     * @return attribute template with default values
     *
     * @author  Svata Sejkora
     * @date    2022-10-04
     *
     */
    protected override SObject createTemplateSObject() {
        aforza__Attribute__c template = new aforza__Attribute__c(
                aforza__Active__c = true,
                aforza__Attribute_Category__c = categoryId,
                Name = 'Attribute Name',
                aforza__Code__c = 'UniqueTest' + ++counter,
                aforza__Type__c = 'Toggle'
        );
        return template;
    }
}