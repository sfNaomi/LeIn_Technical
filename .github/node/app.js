console.log('is this really gonna work?');

const core = require("@actions/core");
//const github = require("@actions/github");
const fs = require('fs');

try {
    const branch = core.getInput("branch");
    let file;
    fs.readFile('.github/settings/repositoryConfig.json', 'utf8', (err, data) => {
        if (err) {
            console.error(err);
        }
        console.log(data);
        file = data;
    });

    //const object = JSON.parse(file);
    //console.log(object);

    //core.setOutput("username", lastSuccessCommitHash);
    //core.setOutput("clientId", lastSuccessCommitHash);
    //core.setOutput("instanceUrl", lastSuccessCommitHash);

} catch (e) {
    core.setFailed(e.message);
}



