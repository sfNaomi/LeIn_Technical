console.log('is this really gonna work?');

const core = require("@actions/core");
//const github = require("@actions/github");
const fs = require('fs');

try {
    const branch = core.getInput("branch");
    let rawData = fs.readFileSync('.github/settings/repositoryConfig.json');
    let data = JSON.parse(rawData);


    //core.setOutput("username", lastSuccessCommitHash);
    //core.setOutput("clientId", lastSuccessCommitHash);
    //core.setOutput("instanceUrl", lastSuccessCommitHash);

} catch (e) {
    core.setFailed(e.message);
}



