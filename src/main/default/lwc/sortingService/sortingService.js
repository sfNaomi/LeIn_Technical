/**
 * Created by svatopluk.sejkora on 16.12.2022.
 */

export function basicSort(fieldName, direction, data) {
    let parseData = JSON.parse(JSON.stringify(data));
    // Return the value stored in the field
    let keyValue = (order) => {
        return order[fieldName];
    };
    // checking reverse direction
    let isReverse = direction === 'asc' ? 1 : -1;
    // sorting data
    parseData.sort((x, y) => {
        x = keyValue(x) ? keyValue(x) : ''; // handling null values
        y = keyValue(y) ? keyValue(y) : '';
        // sorting values based on direction
        return isReverse * ((x > y) - (y > x));
    });
    return parseData;
}