/**
 * Created by svatopluk.sejkora on 25.09.2022.
 */

/**
 * @description method to replace items based on passed regex in a string with values from list
 * @param template - string to replace values in
 * @param regexDefinition - regex to search for
 * @param replacingValues - values to replace items with - an object with correct naming
 *
 * @author Svata Sejkora
 */
export function replaceStringValues(template, regexDefinition, replacingValues) {
    return template.replace(regexDefinition, (match, key) => {
        return replacingValues[key] !== undefined ? replacingValues[key] : '';
    });
}