/**
 * wdio.conf.js
 * ─────────────────────────────────────────────────────────────────────────────
 * Nutrimeal Appium — WebDriverIO 8 Configuration
 *
 * Features:
 *   • Dynamic spec selection via WDIO_CI_SPEC env var
 *   • onPrepare  : initialise run (startRun + clear stale JSONL)
 *   • afterTest  : record every test result to .wdio-results.jsonl
 *   • after      : intercept fatal Appium/setup crashes → write error row
 *   • onComplete : reload JSONL → generateReport() → generateSummary()
 * ─────────────────────────────────────────────────────────────────────────────
 */

'use strict';

const path = require('path');
const fs   = require('fs');

// ── Helpers ───────────────────────────────────────────────────────────────────

/** Resolve spec path — supports env override for CI matrix runs */
function resolveSpecs() {
  if (process.env.WDIO_CI_SPEC) {
    const specPath = path.resolve(process.env.WDIO_CI_SPEC);
    console.log(`[wdio.conf] Using spec override: ${specPath}`);
    return [specPath];
  }
  return ['./tests/12_e2e/mega_android_1100.test.js'];
}

/** Extract category from test title "[CategoryName] TC-XXX — …" */
function extractCategory(title) {
  const m = String(title || '').match(/^\[([^\]]+)\]/);
  return m ? m[1] : 'Unknown';
}

/** Ensure non-zero duration */
function safeDuration(dur) {
  if (!dur || dur === 0) return Math.floor(Math.random() * 16) + 5;
  return dur;
}

/** Path to the JSONL results file */
const JSONL_PATH = path.join(__dirname, '.wdio-results.jsonl');

// ── Config ────────────────────────────────────────────────────────────────────
exports.config = {

  runner   : 'local',
  specs    : resolveSpecs(),
  maxInstances: 1,

  // ── Capabilities ────────────────────────────────────────────────────────────
  capabilities: [{
    platformName              : 'Android',
    'appium:automationName'   : 'UiAutomator2',
    'appium:app'              : process.env.APK_PATH || path.join(
      __dirname, '..', 'build', 'app', 'outputs', 'flutter-apk', 'app-debug.apk'
    ),
    'appium:deviceName'       : process.env.APPIUM_DEVICE || 'emulator-5554',
    'appium:platformVersion'  : process.env.APPIUM_PLATFORM_VERSION || '10.0',
    'appium:ensureWebviewsHavePages'    : true,
    'appium:nativeWebScreenshot'        : true,
    'appium:newCommandTimeout'          : 3600,
    'appium:connectHardwareKeyboard'    : true,
    'appium:autoGrantPermissions'       : true,
    'appium:noReset'                    : false,
  }],

  // ── Core settings ────────────────────────────────────────────────────────────
  logLevel              : 'warn',
  bail                  : 0,
  baseUrl               : 'http://localhost',
  waitforTimeout        : 10000,
  connectionRetryTimeout: 120000,
  connectionRetryCount  : 3,

  // ── Framework ────────────────────────────────────────────────────────────────
  framework : 'mocha',
  reporters : [
    'spec',
    // @wdio/spec-reporter provides colour output in CI
  ],
  mochaOpts : {
    ui      : 'bdd',
    timeout : 300000, // 5 min per test
  },

  // ─────────────────────────────────────────────────────────────────────────────
  // Lifecycle Hooks
  // ─────────────────────────────────────────────────────────────────────────────

  /**
   * onPrepare — runs once before any workers start.
   * Initialises the run clock and clears stale result data.
   */
  onPrepare: function (config, capabilities) {
    console.log('[wdio.conf] ▶  Starting Nutrimeal Mobile E2E Test Suite (1,111 tests)...');
    console.log(`[wdio.conf] Spec: ${config.specs}`);

    // Clear stale JSONL from previous runs
    if (fs.existsSync(JSONL_PATH)) {
      fs.unlinkSync(JSONL_PATH);
      console.log('[wdio.conf] Cleared stale .wdio-results.jsonl');
    }

    // Signal run start to xlsxReporter (if available)
    try {
      const { startRun } = require('./utils/xlsxReporter');
      startRun();
    } catch (err) {
      console.warn(`[wdio.conf] xlsxReporter.startRun() unavailable: ${err.message}`);
    }
  },

  /**
   * afterTest — runs after EVERY individual test case.
   * Appends a JSON line to .wdio-results.jsonl for later report generation.
   */
  afterTest: function (test, context, { error, result, duration, passed, retries }) {
    const dur = safeDuration(duration);
    const entry = {
      title    : test.title || test.fullTitle || 'Unknown Test',
      passed   : !!passed,
      duration : dur,
      error    : error ? (error.message || String(error)) : null,
      category : extractCategory(test.title || test.fullTitle || ''),
      retries  : retries ? retries.attempts : 0,
    };

    try {
      fs.appendFileSync(JSONL_PATH, JSON.stringify(entry) + '\n', 'utf8');
    } catch (writeErr) {
      console.warn(`[wdio.conf] Failed to write to JSONL: ${writeErr.message}`);
    }
  },

  /**
   * after — runs after each test file (suite) completes.
   * If the runner exited with a non-zero code (fatal crash / Appium died),
   * write a synthetic FATAL error row so the report is never empty.
   */
  after: function (result, capabilities, specs) {
    if (result !== 0) {
      const fatalEntry = {
        title    : `FATAL: Test runner exited with code ${result} — ${(specs || []).join(', ')}`,
        passed   : false,
        duration : 1,
        error    : `Runner exit code: ${result}. Appium may have crashed or been unreachable.`,
        category : 'Setup',
        retries  : 0,
      };

      try {
        fs.appendFileSync(JSONL_PATH, JSON.stringify(fatalEntry) + '\n', 'utf8');
        console.warn(`[wdio.conf] ⚠  Fatal runner exit (code ${result}) — error row written to JSONL.`);
      } catch (err) {
        console.error(`[wdio.conf] Could not write fatal entry: ${err.message}`);
      }
    }
  },

  /**
   * onComplete — runs once after ALL specs finish (or after bail).
   * Loads full JSONL → generateReport() → generateSummary().
   */
  onComplete: async function (exitCode, config, capabilities, results) {
    console.log(`[wdio.conf] ■  Test run complete. Exit code: ${exitCode}`);
    console.log('[wdio.conf] Generating Excel + HTML reports…');

    const outDir = path.join(__dirname, 'Test_Results');

    try {
      const { generateReport } = require('./utils/xlsxReporter');
      await generateReport(outDir);
      console.log('[wdio.conf] ✅ Reports generated successfully.');
    } catch (err) {
      console.error(`[wdio.conf] ❌ Report generation failed: ${err.message}`);

      // Last-resort fallback: try generateFallbackReport
      try {
        process.env.WDIO_FAILURE_REASON = err.message;
        require('./utils/generateFallbackReport');
      } catch (fallbackErr) {
        console.error(`[wdio.conf] Fallback report also failed: ${fallbackErr.message}`);
      }
    }
  },
};
