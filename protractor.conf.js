'use strict';

var paths = require('./.yo-rc.json')['generator-gulp-angular'].props.paths;

// An example configuration file.
exports.config = {
    baseUrl: 'http://localhost:3000',
    specs: [paths.e2e + '/**/*.js'],
    // chromeOnly: true,
    // directConnect: true,
    capabilities: {
        'browserName': 'chrome'
    },
    jasmineNodeOpts: {
        showColors: true,
        defaultTimeoutInterval: 30000
    },
    getPageTimeout: 30000,
    mocks: {
        default: ['default'],
        dir: 'mocks'
    },
    onPrepare: function () {
        require('protractor-http-mock').config = {
            protractorConfig: 'protractor.conf.js'
        };
        require('protractor-uisref-locator')(protractor);
        require('protractor-linkuisref-locator')(protractor);
    }
};
