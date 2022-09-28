/**
 * Created by svatopluk.sejkora on 27.09.2022.
 *
 * @description Class to populate AuraHandledException with passed message. Putting it in only when created
 * will result in not expected conditions
 *
 */

public with sharing class PopulateAuraHandledException extends Exception {
    public static AuraHandledException newMessageException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
}