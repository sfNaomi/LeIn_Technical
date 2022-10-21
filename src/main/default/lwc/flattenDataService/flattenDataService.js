/**
 * Created by svatopluk.sejkora on 15.10.2022.
 */

export class FlattenDataService {

    /**
     * method to iterate over items returned from apex. For each record it will call flattening method. Will update
     * class level list of flattened data nad empties flattened record.
     *
     * @param returnedData set of all data to be flattened
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    flattenData(returnedData) {
        let flattenedRecords = [];
        let flattenedRecord = {};
        if (returnedData) {
            for (let i = 0; i < returnedData.length; i++) {
                let record = returnedData[i];
                this.flattenRecord([{'record': record, 'levelPath': ''}], flattenedRecord);
                flattenedRecords.push(flattenedRecord);
                flattenedRecord = {};
            }
            return flattenedRecords;
        } else {
            return null;
        }
    }

    /**
     * Recursive method to flatten the data.
     *
     * @author Svata Sejkora
     * @date 2022-09-20
     */
    flattenRecord(objectArray, flattenedRecord) {
        let objectHolder = [];
        objectArray.forEach(object => {
            const activeRecord = object.record;
            let levelPath = object.levelPath;
            for (let i = 0; i < Object.keys(activeRecord).length; i++) {
                const property = Object.keys(activeRecord)[i];
                if (typeof activeRecord[property] === 'object') {
                    objectHolder.push({'record': activeRecord[property], 'levelPath': levelPath + property});
                } else {
                    flattenedRecord[levelPath + property] = activeRecord[property];
                }
            }
        });
        if (objectHolder.length > 0) {
            this.flattenRecord(objectHolder, flattenedRecord);
        }
    }
}