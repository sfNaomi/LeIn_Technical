
## Dev Tools

* [SFDX Data Move Utility](https://help.sfdmu.com/) - powerful data migration tool.
    * After installation, see example configuration in `data/export.json`.
    * The idea for DX projects is to keep `data/export.json` configuration present in its repository so that everyone can import sample data into his scratch org easily.
    * Import can be run at any time, nevertheless, it is usually part of scratch org init task.
    * Import data from `data/<sobject>.csv` files using preconfigured npm script:
        ```sh
        $ npm run data:import --target=orgAlias
        ```
    * To export new data, you may need to update the configuration, see plugin's documentation.
    * Export data to csv files using preconfigured npm script:
        ```sh
        $ npm run data:export --source=orgAlias
        ``` 
    * Before committing a new configuration or data, ensure that import works just fine to prevent others having issues.

* [SFDX-Git-Delta](https://github.com/scolladon/sfdx-git-delta) - prepare `package.xml` within seconds.
    * Handy tool for not only deployment-responsible people.
    * Git is a prerequisite. No remote repository is needed though.
    ```sh
    $ sfdx sgd:source:delta --to "HEAD" --from "HEAD^" --output .
    $ sfdx force:source:deploy -x package/package.xml -u targetOrg
    $ sfdx force:mdapi:deploy -d destructiveChanges --ignorewarnings -u targetOrg
    ```
  

* [CI-SFDX-Plugin](https://www.npmjs.com/package/ci-sfdx-plugin) - set of commands making CI and dev's life easier when using scratch orgs.
  * Install the plugin, update configuration in `ciconfig.json` and npm scripts in `package.json` for your new project following steps on the plugin's homepage.
