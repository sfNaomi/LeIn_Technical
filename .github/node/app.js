console.log('is this really gonna work?');

const core = require("@actions/core");
//const github = require("@actions/github");
const fs = require('fs');

try {
    const branch = core.getInput("branch");
    let rawData = fs.readFileSync('.github/settings/repositoryConfig.json');
    let data = JSON.parse(rawData);
    console.log(data);

    core.setOutput("userName", data[branch].userName);
    //core.setOutput("clientId", lastSuccessCommitHash);
    //core.setOutput("instanceUrl", lastSuccessCommitHash);

} catch (e) {
    core.setFailed(e.message);
}



