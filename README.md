
## Dev Tools

* [CI-SFDX-Plugin](https://www.npmjs.com/package/ci-sfdx-plugin) - set of commands making CI and dev's life easier when using scratch orgs.
  * Install the plugin, update configuration in `ciconfig.json` and npm scripts in `package.json` for your new project following steps on the plugin's homepage.
  * See plugin's page for help.
    ```sh
    # install our custom sfdx plugin
    $ sfdx plugins:install ci-sfdx-plugin
    
    # update the plugin
    $ sfdx plugins:install ci-sfdx-plugin@latest
    
    # run scratch org init script for your OS
    $ npm run sfci:init --alias=orgAlias
    $ npm run sfci:init:win --alias=orgAlias
    ```

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