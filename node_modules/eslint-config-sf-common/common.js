module.exports = {
    env: {
        'browser': true,
        'es6': true
    },
    extends: [
        // https://github.com/eslint/eslint/blob/master/conf/eslint-recommended.js
        'eslint:recommended'
    ],
    parserOptions: {
        // https://developer.salesforce.com/docs/component-library/documentation/en/lwc/get_started_supported_javascript
        'ecmaVersion': 9,
        'ecmaFeatures': {
            'impliedStrict': true
        }
    },
    plugins: [
        // https://github.com/gajus/eslint-plugin-jsdoc
        'jsdoc'
    ]
};