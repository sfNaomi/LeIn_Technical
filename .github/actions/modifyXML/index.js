const core = require('@actions/core');
const fs = require('fs');
const parser = require('xml2js');

try {
    const nodeToFind = core.getInput('nodeToDelete');
    console.log(nodeToFind);
    let indexOfNode = [];
    let rawData = fs.readFileSync('src/main/default/permissionsets/SystemAdminFeatures.permissionset-meta.xml');
    parser.parseString(rawData, (err, result) => {
        result.PermissionSet.userPermissions.forEach((item, index) => {
            if (nodeToFind.includes(item.name[0])) {
                indexOfNode.push(index);
            }
        });
        for (let i = indexOfNode.length -1; i >= 0; i--) {
            result.PermissionSet.userPermissions.splice(indexOfNode[i], 1);
        }

        const builder = new parser.Builder();
        const xml = builder.buildObject(result);
        fs.writeFileSync('src/main/default/permissionsets/SystemAdminFeatures.permissionset-meta.xml', xml);
    });



} catch (e) {
    core.setFailed(e.message);
}



