/**
 * @description Class to contain all common and org specific exceptions.
 *
 * @author  Svata Sejkora
 * @date    2021-11-01
 */

public with sharing class Exceptions {
    ////////////////////////////////
    ////// COMMON EXCEPTIONS  //////
    ////// DO NOT MODIFY THEM //////
    ////////////////////////////////

    /**
     * @description Thrown to indicate that there is an incorrect value set in settings.
     *
     * @author  Svata Sejkora
     * @date    2021-11-01
     */
    public with sharing class BadConfigurationException extends Exception {
    }

    /**
     * @description Thrown to indicate that received data are in an incorrect state or format
     *
     * @author  Svata Sejkora
     * @date    2021-11-01
     */
    public with sharing class BadDataException extends Exception {
    }

    /**
   * @description SObjectFactory exception to be thrown if SObject cannot be created for some reason.
   *
   * @author  Svata Sejkoda
   * @date    2022-06-02
   */
    public with sharing class TdfSObjectFactoryException extends Exception {
    }

    public with sharing class EmailException extends Exception {
    }
}
