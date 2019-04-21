'use strict';
var mock = require('protractor-http-mock');

describe('The main view', function () {
    var page;

    beforeEach(function () {
        page = require('./main.po');
    });

    afterEach(function () {
        mock.teardown();
        browser.manage().logs().get('browser').then(function (browserLog) {
            for (var i = 0; i < browserLog.length; i++) {
                var log = browserLog[i];
                if (log.level.name == 'SEVERE'
                    && typeof log.message === 'string'
                    && log.message.indexOf("ERR_CONNECTION_REFUSED") === -1) {
                    console.log(log);
                    expect(log.level.name).not.toEqual('SEVERE');
                }
            }
        });
    });

    it('should navigate to login', function () {
        browser.get('/');
        expect(browser.getCurrentUrl()).toContain("#/login");
    });

});
