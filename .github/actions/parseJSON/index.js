const core = require("@actions/core");
const fs = require('fs');

try {
    const branch = core.getInput('branch');
    let rawData = fs.readFileSync('.github/settings/repositoryConfig.json');
    let data = JSON.parse(rawData);

    const branchData = data[branch];

    let certificatePath;
    switch (branch) {
        case 'develop':
            certificatePath = '${HOME}/qa.key';
            break;
        case 'staging':
            certificatePath = '${HOME}/staging.key';
            break;
        case 'main':
            certificatePath = '${HOME}/prod.key';
            break;
        case 'interfaces':
            certificatePath = '${HOME}/interfaces.key';
            break;
        default:
            certificatePath = '${HOME}/qa.key';
    }


    core.setOutput('userName', branchData.userName);
    core.setOutput('clientId', branchData.clientId);
    core.setOutput('instanceUrl', branchData.instanceUrl);
    core.setOutput('certificatePath', certificatePath);
    core.setOutput('runDestructive', branchData.runDestructive);

} catch (e) {
    core.setFailed(e.message);
}



