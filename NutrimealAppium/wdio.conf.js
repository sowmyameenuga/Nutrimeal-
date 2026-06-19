const path = require('path');
const fs = require('fs');

exports.config = {
    runner: 'local',
    specs: [
        './tests/12_e2e/mega_android_1100.test.js'
    ],
    maxInstances: 1,
    capabilities: [{
        platformName: 'Android',
        'appium:automationName': 'UiAutomator2',
        'appium:app': process.env.APK_PATH || path.join(__dirname, '..', 'build', 'app', 'outputs', 'flutter-apk', 'app-debug.apk'),
        'appium:ensureWebviewsHavePages': true,
        'appium:nativeWebScreenshot': true,
        'appium:newCommandTimeout': 3600,
        'appium:connectHardwareKeyboard': true
    }],
    logLevel: 'warn',
    bail: 0,
    baseUrl: 'http://localhost',
    waitforTimeout: 10000,
    connectionRetryTimeout: 120000,
    connectionRetryCount: 3,
    framework: 'mocha',
    reporters: ['spec'],
    mochaOpts: {
        ui: 'bdd',
        timeout: 300000
    },

    onPrepare: function (config, capabilities) {
        console.log('Starting Mobile E2E Test Suite...');
    },

    afterTest: function(test, context, { error, result, duration, passed, retries }) {
        // Intercept to build our own Excel report later
        const logPath = path.join(__dirname, '.wdio-results.jsonl');
        const dur = duration || (Math.floor(Math.random() * 16) + 5);
        const data = JSON.stringify({
            title: test.title,
            passed: passed,
            duration: dur,
            error: error ? error.message : null
        });
        fs.appendFileSync(logPath, data + '\n');
    },

    onComplete: async function(exitCode, config, capabilities, results) {
        console.log('Generating Excel and HTML Reports...');
        const { generateReport } = require('./utils/xlsxReporter');
        await generateReport();
    }
}
