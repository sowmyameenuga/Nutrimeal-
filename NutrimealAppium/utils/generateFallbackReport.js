/**
 * generateFallbackReport.js
 * ─────────────────────────────────────────────────────────────────────────────
 * Nutrimeal Appium — Crash / Setup-Failure Fallback Report Generator
 *
 * Called by ci_run_tests.sh when WDIO exits with a non-zero code before any
 * test results are written. Produces a minimal Excel + HTML failure report
 * so that GHA artifact upload steps never fail due to missing output files.
 *
 * Usage (CLI — called from ci_run_tests.sh):
 *   node utils/generateFallbackReport.js [errorMessage]
 * ─────────────────────────────────────────────────────────────────────────────
 */

'use strict';

const fs   = require('fs');
const path = require('path');

// ExcelJS — graceful fallback if not installed
let ExcelJS;
try {
  ExcelJS = require('exceljs');
} catch {
  ExcelJS = null;
}

const errorMessage = process.argv[2] || process.env.WDIO_FAILURE_REASON || 'WDIO/Appium fatal setup error — no tests executed.';
const runTime      = new Date().toISOString();
const outDir       = path.join(__dirname, '..', 'Test_Results');
const htmlDir      = path.join(outDir, 'HTML');

// Ensure output directories exist
[outDir, htmlDir].forEach((d) => {
  if (!fs.existsSync(d)) fs.mkdirSync(d, { recursive: true });
});

console.log(`[generateFallbackReport] Writing fallback reports. Reason: ${errorMessage}`);

// ── Excel Fallback ────────────────────────────────────────────────────────────
async function writeFallbackExcel() {
  if (!ExcelJS) {
    console.warn('[generateFallbackReport] exceljs not available — skipping Excel output.');
    return;
  }

  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'NutrimealAppium-Fallback';

  // Sheet 1: Summary
  const summarySheet = workbook.addWorksheet('Summary');
  summarySheet.columns = [
    { key: 'metric', width: 28 },
    { key: 'value',  width: 60 },
  ];
  const hdr = summarySheet.addRow(['Metric', 'Value']);
  hdr.font = { bold: true, color: { argb: 'FFFFFFFF' } };
  hdr.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF44336' } };

  summarySheet.addRow(['Status',       'FATAL ERROR — No tests executed']);
  summarySheet.addRow(['Reason',       errorMessage]);
  summarySheet.addRow(['Run Time',     runTime]);
  summarySheet.addRow(['Total Tests',  0]);
  summarySheet.addRow(['Passed',       0]);
  summarySheet.addRow(['Failed',       0]);
  summarySheet.addRow(['Pass Rate',    '0.00%']);

  // Sheet 2: By Category (empty placeholder)
  const catSheet = workbook.addWorksheet('By Category');
  catSheet.addRow(['Category', 'Total', 'Passed', 'Failed', 'Pass Rate']).font = { bold: true };
  catSheet.addRow(['N/A — setup failed', 0, 0, 0, '0%']);

  // Sheet 3: Test Cases (error row)
  const casesSheet = workbook.addWorksheet('Test Cases');
  casesSheet.columns = [
    { header: '#',          key: 'index',    width: 7  },
    { header: 'Category',  key: 'category', width: 18 },
    { header: 'Test Case', key: 'title',    width: 60 },
    { header: 'Status',    key: 'status',   width: 12 },
    { header: 'Duration',  key: 'duration', width: 14 },
    { header: 'Error',     key: 'error',    width: 60 },
  ];
  casesSheet.getRow(1).font = { bold: true };
  casesSheet.addRow({
    index    : 1,
    category : 'Setup',
    title    : 'WDIO / Appium Fatal Setup Failure',
    status   : 'FATAL',
    duration : 0,
    error    : errorMessage,
  });

  const excelPath = path.join(outDir, 'nutrimeal-appium-e2e-report.xlsx');
  await workbook.xlsx.writeFile(excelPath);
  console.log(`[generateFallbackReport] Excel → ${excelPath}`);
}

// ── HTML Fallback ─────────────────────────────────────────────────────────────
function writeFallbackHtml() {
  const htmlPath = path.join(htmlDir, 'execution-report.html');
  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Nutrimeal — Fallback Failure Report</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Segoe UI', system-ui, sans-serif;
      background: #0d0d17;
      color: #e0e0f0;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 40px 20px;
    }
    .card {
      background: #13131f;
      border: 1px solid #f4433644;
      border-top: 4px solid #f44336;
      border-radius: 16px;
      padding: 48px 40px;
      max-width: 680px;
      width: 100%;
      text-align: center;
    }
    .icon { font-size: 3.5rem; margin-bottom: 16px; }
    h1 { font-size: 1.6rem; color: #f44336; margin-bottom: 12px; }
    p  { color: #8899bb; margin-bottom: 8px; font-size: 0.95rem; }
    .error-box {
      background: #1a0a0a;
      border: 1px solid #f4433633;
      border-radius: 8px;
      padding: 16px;
      margin: 24px 0;
      text-align: left;
      font-family: monospace;
      font-size: 0.85rem;
      color: #f44336;
      word-break: break-all;
    }
    .meta { font-size: 0.78rem; color: #445566; margin-top: 24px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">🚨</div>
    <h1>Test Suite — Fatal Setup Failure</h1>
    <p>The Appium / WebDriverIO test runner encountered a fatal error before any tests could execute.</p>
    <p>This is an automatically generated fallback report.</p>
    <div class="error-box">${escapeHtml(errorMessage)}</div>
    <p><strong>Tests Executed:</strong> 0 / 1,111</p>
    <p><strong>Pass Rate:</strong> 0.00%</p>
    <div class="meta">Generated at ${runTime} by NutrimealAppium generateFallbackReport.js</div>
  </div>
</body>
</html>`;

  fs.writeFileSync(htmlPath, html, 'utf8');
  console.log(`[generateFallbackReport] HTML → ${htmlPath}`);
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g,  '&amp;')
    .replace(/</g,  '&lt;')
    .replace(/>/g,  '&gt;')
    .replace(/"/g,  '&quot;')
    .replace(/'/g,  '&#39;');
}

// ── Also write a stub JSONL so xlsxReporter does not crash ────────────────────
function writeStubJsonl() {
  const jsonlPath = path.join(__dirname, '..', '.wdio-results.jsonl');
  if (!fs.existsSync(jsonlPath)) {
    const stub = JSON.stringify({
      title    : 'WDIO / Appium Fatal Setup Failure',
      passed   : false,
      duration : 1,
      error    : errorMessage,
      category : 'Setup',
    });
    fs.writeFileSync(jsonlPath, stub + '\n', 'utf8');
    console.log(`[generateFallbackReport] Stub JSONL written → ${jsonlPath}`);
  }
}

// ── Run ───────────────────────────────────────────────────────────────────────
(async () => {
  writeStubJsonl();
  await writeFallbackExcel();
  writeFallbackHtml();
  console.log('[generateFallbackReport] Fallback reports complete.');
})();
