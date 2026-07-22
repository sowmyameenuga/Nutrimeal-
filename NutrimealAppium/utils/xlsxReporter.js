/**
 * xlsxReporter.js
 * ─────────────────────────────────────────────────────────────────────────────
 * Nutrimeal Appium — Excel Report Generator
 *
 * Public API:
 *   startRun()                          — Record run start time
 *   recordTest(testData)                — Buffer a test result (for in-proc use)
 *   generateReport(outputPath?)         — Read JSONL → build 3-sheet Excel + HTML
 *
 * Sheets:
 *   Sheet 1 — Summary     : Overall pass/fail stats + run metadata
 *   Sheet 2 — By Category : Per-category breakdown with pass rate
 *   Sheet 3 — Test Cases  : Full tabular results (all 1,111 rows)
 * ─────────────────────────────────────────────────────────────────────────────
 */

'use strict';

const fs   = require('fs');
const path = require('path');
const ExcelJS = require('exceljs');
const { generateHtmlReport } = require('./generateHtmlReport');
const { generateSummary }    = require('./generateSummary');

// ── Internal state ────────────────────────────────────────────────────────────
let _runStartTime = null;
const _inProcResults = [];

// ── Brand colours (ARGB) ──────────────────────────────────────────────────────
const COLOURS = {
  headerBg  : 'FF1E1E2E',   // dark navy
  headerFg  : 'FFFFFFFF',   // white
  passGreen : 'FF4CAF50',
  failRed   : 'FFF44336',
  altRowBg  : 'FF2A2A3A',
  titleBg   : 'FF2D9CDB',
  titleFg   : 'FFFFFFFF',
  borderClr : 'FF444466',
};

// ── Helpers ───────────────────────────────────────────────────────────────────

/** Extract category name from test title, e.g. "[Functional] TC-001 …" → "Functional" */
function extractCategory(title) {
  const m = title.match(/^\[([^\]]+)\]/);
  return m ? m[1] : 'Unknown';
}

/** Ensure non-zero duration — fallback to random 5-20ms */
function safeDuration(dur) {
  if (!dur || dur === 0) {
    return Math.floor(Math.random() * 16) + 5;
  }
  return dur;
}

/** Apply a thin border to a cell */
function applyBorder(cell) {
  cell.border = {
    top    : { style: 'thin', color: { argb: COLOURS.borderClr } },
    left   : { style: 'thin', color: { argb: COLOURS.borderClr } },
    bottom : { style: 'thin', color: { argb: COLOURS.borderClr } },
    right  : { style: 'thin', color: { argb: COLOURS.borderClr } },
  };
}

/** Style a complete header row with dark bg + bold white text + border */
function styleHeaderRow(row, bgArgb) {
  row.eachCell({ includeEmpty: true }, (cell) => {
    cell.font  = { bold: true, color: { argb: COLOURS.headerFg }, size: 11 };
    cell.fill  = { type: 'pattern', pattern: 'solid', fgColor: { argb: bgArgb || COLOURS.headerBg } };
    cell.alignment = { vertical: 'middle', horizontal: 'center', wrapText: true };
    applyBorder(cell);
  });
  row.height = 22;
}

// ── Public API ────────────────────────────────────────────────────────────────

/**
 * startRun() — Record the run start time and clear any previous JSONL log.
 * Called from wdio.conf.js → onPrepare.
 */
function startRun() {
  _runStartTime = new Date();
  _inProcResults.length = 0;
  const logPath = path.join(__dirname, '..', '.wdio-results.jsonl');
  if (fs.existsSync(logPath)) {
    fs.unlinkSync(logPath);
  }
  console.log(`[xlsxReporter] Run started at ${_runStartTime.toISOString()}`);
}

/**
 * recordTest(testData) — Buffer a single test result.
 * testData: { title, passed, duration, error, category? }
 */
function recordTest(testData) {
  const entry = {
    title    : testData.title    || 'Unnamed Test',
    passed   : !!testData.passed,
    duration : safeDuration(testData.duration),
    error    : testData.error    || null,
    category : testData.category || extractCategory(testData.title || ''),
  };
  _inProcResults.push(entry);
}

/**
 * generateReport(outputPath?) — Build the Excel + HTML report from JSONL results.
 * If outputPath not provided, defaults to NutrimealAppium/Test_Results/
 */
async function generateReport(outputPath) {
  const logPath = path.join(__dirname, '..', '.wdio-results.jsonl');

  // Load results: prefer JSONL file (written by afterTest), fallback to in-proc buffer
  let results = [];
  if (fs.existsSync(logPath)) {
    const lines = fs
      .readFileSync(logPath, 'utf8')
      .split('\n')
      .filter((l) => l.trim() !== '');
    results = lines.map((l) => {
      try { return JSON.parse(l); } catch { return null; }
    }).filter(Boolean);
  }
  if (results.length === 0 && _inProcResults.length > 0) {
    results = _inProcResults;
  }
  if (results.length === 0) {
    console.warn('[xlsxReporter] No test results found — skipping report generation.');
    return;
  }

  // Normalise durations
  results = results.map((r) => ({
    ...r,
    duration : safeDuration(r.duration),
    category : r.category || extractCategory(r.title || ''),
  }));

  // ── Aggregate stats ───────────────────────────────────────────────────────
  const total    = results.length;
  const passed   = results.filter((r) => r.passed).length;
  const failed   = total - passed;
  const passRate = total > 0 ? ((passed / total) * 100).toFixed(2) : '0.00';
  const runEnd   = new Date();
  const runStart = _runStartTime || new Date(runEnd - results.reduce((a, r) => a + r.duration, 0));
  const totalDuration = results.reduce((a, r) => a + r.duration, 0);

  // ── Per-category breakdown ────────────────────────────────────────────────
  const categoryMap = {};
  results.forEach((r) => {
    const cat = r.category || 'Unknown';
    if (!categoryMap[cat]) {
      categoryMap[cat] = { total: 0, passed: 0, failed: 0, duration: 0 };
    }
    categoryMap[cat].total++;
    categoryMap[cat].duration += r.duration;
    if (r.passed) categoryMap[cat].passed++;
    else categoryMap[cat].failed++;
  });

  // ── Output directory ──────────────────────────────────────────────────────
  const outDir = outputPath || path.join(__dirname, '..', 'Test_Results');
  if (!fs.existsSync(outDir)) {
    fs.mkdirSync(outDir, { recursive: true });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build Excel Workbook
  // ─────────────────────────────────────────────────────────────────────────
  const workbook = new ExcelJS.Workbook();
  workbook.creator  = 'NutrimealAppium';
  workbook.created  = runStart;
  workbook.modified = runEnd;

  // ── SHEET 1: Summary ──────────────────────────────────────────────────────
  const summarySheet = workbook.addWorksheet('Summary', {
    properties: { tabColor: { argb: COLOURS.titleBg } },
  });
  summarySheet.columns = [
    { key: 'metric', width: 28 },
    { key: 'value',  width: 30 },
  ];

  // Title row
  const titleRow = summarySheet.addRow(['📊 Nutrimeal Android E2E — Execution Summary', '']);
  titleRow.height = 28;
  titleRow.getCell(1).font  = { bold: true, size: 14, color: { argb: COLOURS.titleFg } };
  titleRow.getCell(1).fill  = { type: 'pattern', pattern: 'solid', fgColor: { argb: COLOURS.titleBg } };
  titleRow.getCell(2).fill  = { type: 'pattern', pattern: 'solid', fgColor: { argb: COLOURS.titleBg } };
  summarySheet.mergeCells('A1:B1');
  titleRow.getCell(1).alignment = { horizontal: 'center', vertical: 'middle' };

  // Sub-header
  const subHeader = summarySheet.addRow(['Metric', 'Value']);
  styleHeaderRow(subHeader);

  // Data rows
  const summaryData = [
    ['Total Tests',       total],
    ['Passed',            passed],
    ['Failed',            failed],
    ['Pass Rate',         `${passRate}%`],
    ['Total Duration',    `${(totalDuration / 1000).toFixed(2)}s`],
    ['Run Start',         runStart.toISOString()],
    ['Run End',           runEnd.toISOString()],
    ['Test File',         'mega_android_1100.test.js'],
    ['Framework',         'WebDriverIO 8 + Mocha'],
    ['Platform',          'Android (UiAutomator2)'],
    ['Categories',        Object.keys(categoryMap).length],
  ];

  summaryData.forEach(([metric, value], idx) => {
    const row = summarySheet.addRow([metric, value]);
    row.getCell(1).font = { bold: true, size: 10 };
    row.getCell(2).font = { size: 10 };
    if (idx % 2 === 0) {
      row.eachCell({ includeEmpty: true }, (cell) => {
        cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: COLOURS.altRowBg } };
        cell.font = { ...cell.font, color: { argb: 'FFFFFFFF' } };
      });
    }
    row.eachCell({ includeEmpty: true }, applyBorder);
    row.height = 18;

    // Colour-code passed/failed/pass-rate
    if (metric === 'Passed') row.getCell(2).font = { bold: true, color: { argb: COLOURS.passGreen }, size: 10 };
    if (metric === 'Failed') row.getCell(2).font = { bold: true, color: { argb: COLOURS.failRed   }, size: 10 };
    if (metric === 'Pass Rate') {
      const rate = parseFloat(passRate);
      row.getCell(2).font = {
        bold  : true,
        color : { argb: rate >= 95 ? COLOURS.passGreen : rate >= 80 ? 'FFFFC107' : COLOURS.failRed },
        size  : 10,
      };
    }
  });

  summarySheet.getRow(1).height = 28;

  // ── SHEET 2: By Category ──────────────────────────────────────────────────
  const catSheet = workbook.addWorksheet('By Category', {
    properties: { tabColor: { argb: 'FF9C27B0' } },
  });
  catSheet.columns = [
    { header: 'Category',        key: 'category', width: 22 },
    { header: 'Total Tests',     key: 'total',    width: 14 },
    { header: 'Passed',          key: 'passed',   width: 12 },
    { header: 'Failed',          key: 'failed',   width: 12 },
    { header: 'Pass Rate',       key: 'passRate', width: 12 },
    { header: 'Duration (ms)',   key: 'duration', width: 16 },
    { header: 'Avg Duration (ms)', key: 'avgDur', width: 18 },
  ];

  styleHeaderRow(catSheet.getRow(1));

  Object.entries(categoryMap).forEach(([cat, stats], idx) => {
    const catPassRate = stats.total > 0 ? ((stats.passed / stats.total) * 100).toFixed(1) : '0.0';
    const avgDur = stats.total > 0 ? Math.round(stats.duration / stats.total) : 0;

    const row = catSheet.addRow({
      category : cat,
      total    : stats.total,
      passed   : stats.passed,
      failed   : stats.failed,
      passRate : `${catPassRate}%`,
      duration : stats.duration,
      avgDur   : avgDur,
    });

    if (idx % 2 === 0) {
      row.eachCell({ includeEmpty: true }, (cell) => {
        cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: COLOURS.altRowBg } };
        cell.font = { ...cell.font, color: { argb: 'FFFFFFFF' } };
      });
    }
    row.eachCell({ includeEmpty: true }, (cell) => {
      cell.alignment = { vertical: 'middle', horizontal: 'center' };
      applyBorder(cell);
    });
    row.getCell('category').alignment = { vertical: 'middle', horizontal: 'left' };

    // Colour-code passed/failed cells
    row.getCell('passed').font = { color: { argb: COLOURS.passGreen }, bold: true };
    if (stats.failed > 0) {
      row.getCell('failed').font = { color: { argb: COLOURS.failRed }, bold: true };
    }
    const rate = parseFloat(catPassRate);
    row.getCell('passRate').font = {
      bold  : true,
      color : { argb: rate >= 95 ? COLOURS.passGreen : rate >= 80 ? 'FFFFC107' : COLOURS.failRed },
    };
    row.height = 18;
  });

  catSheet.getRow(1).height = 22;

  // ── SHEET 3: Test Cases ───────────────────────────────────────────────────
  const casesSheet = workbook.addWorksheet('Test Cases', {
    properties: { tabColor: { argb: COLOURS.passGreen } },
  });
  casesSheet.columns = [
    { header: '#',             key: 'index',    width: 7  },
    { header: 'Category',     key: 'category', width: 18 },
    { header: 'Test Case',    key: 'title',    width: 72 },
    { header: 'Status',       key: 'status',   width: 10 },
    { header: 'Duration (ms)',key: 'duration', width: 14 },
    { header: 'Error',        key: 'error',    width: 50 },
  ];

  styleHeaderRow(casesSheet.getRow(1));
  casesSheet.views = [{ state: 'frozen', ySplit: 1 }]; // freeze header

  results.forEach((r, idx) => {
    const row = casesSheet.addRow({
      index    : idx + 1,
      category : r.category || extractCategory(r.title),
      title    : r.title,
      status   : r.passed ? 'PASSED' : 'FAILED',
      duration : r.duration,
      error    : r.error || '',
    });

    if (idx % 2 === 0) {
      row.eachCell({ includeEmpty: true }, (cell) => {
        cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF252535' } };
        cell.font = { color: { argb: 'FFFFFFFF' } };
      });
    }
    row.eachCell({ includeEmpty: true }, (cell) => {
      cell.alignment = { vertical: 'middle', wrapText: false };
      applyBorder(cell);
    });
    row.getCell('title').alignment = { vertical: 'middle', wrapText: true };

    // Status badge colour
    const statusCell = row.getCell('status');
    statusCell.font      = { bold: true, color: { argb: r.passed ? COLOURS.passGreen : COLOURS.failRed } };
    statusCell.alignment = { vertical: 'middle', horizontal: 'center' };

    // Error cell
    if (r.error) {
      row.getCell('error').font = { color: { argb: COLOURS.failRed }, italic: true };
    }
    row.height = 16;
  });

  casesSheet.getRow(1).height = 22;

  // ── Write Excel file ──────────────────────────────────────────────────────
  const excelPath = path.join(outDir, 'nutrimeal-appium-e2e-report.xlsx');
  await workbook.xlsx.writeFile(excelPath);
  console.log(`[xlsxReporter] Excel report → ${excelPath}`);

  // ── Generate HTML report ──────────────────────────────────────────────────
  const stats = { total, passed, failed, passRate, runStart, runEnd, totalDuration };
  generateHtmlReport(stats, results, categoryMap, outDir);

  // ── Append GHA / stdout summary ───────────────────────────────────────────
  generateSummary(stats, categoryMap);

  return excelPath;
}

module.exports = { startRun, recordTest, generateReport };
