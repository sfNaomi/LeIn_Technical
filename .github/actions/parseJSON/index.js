const core = require("@actions/core");
const fs = require('fs');

try {
    const branch = core.getInput("branch");
    let rawData = fs.readFileSync('.github/settings/repositoryConfig.json');
    let data = JSON.parse(rawData);

    const branchData = data[branch];

    core.setOutput("userName", branchData.userName);
    core.setOutput("clientId", branchData.clientId);
    core.setOutput("instanceUrl", branchData.instanceUrl);

} catch (e) {
    core.setFailed(e.message);
}



