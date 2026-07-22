/**
 * generateHtmlReport.js
 * ─────────────────────────────────────────────────────────────────────────────
 * Nutrimeal Appium — Styled Dark HTML Execution Report Generator
 *
 * Generates: Test_Results/HTML/execution-report.html
 *
 * Sections:
 *   • Animated header with gradient + run metadata
 *   • Summary stat cards (Total / Passed / Failed / Pass Rate animated bar)
 *   • Category Breakdown table with per-category pass rates
 *   • Full Test Cases table with status badges + duration
 * ─────────────────────────────────────────────────────────────────────────────
 */

'use strict';

const fs   = require('fs');
const path = require('path');

/**
 * generateHtmlReport(stats, results, categoryMap, outDir)
 *
 * @param {object} stats        — { total, passed, failed, passRate, runStart, runEnd, totalDuration }
 * @param {Array}  results      — Array of { title, passed, duration, error, category }
 * @param {object} categoryMap  — { CategoryName: { total, passed, failed, duration } }
 * @param {string} outDir       — Output base directory (HTML/ subdir created inside)
 */
function generateHtmlReport(stats, results, categoryMap, outDir) {
  const htmlDir  = path.join(outDir, 'HTML');
  const htmlPath = path.join(htmlDir, 'execution-report.html');

  if (!fs.existsSync(htmlDir)) {
    fs.mkdirSync(htmlDir, { recursive: true });
  }

  const { total, passed, failed, passRate, runStart, runEnd, totalDuration } = stats;
  const passRateNum  = parseFloat(passRate) || 0;
  const runStartStr  = runStart  ? new Date(runStart).toUTCString()  : 'N/A';
  const runEndStr    = runEnd    ? new Date(runEnd).toUTCString()    : 'N/A';
  const durationSec  = totalDuration ? (totalDuration / 1000).toFixed(2) : '0.00';

  // ── Category rows HTML ────────────────────────────────────────────────────
  const categoryRowsHtml = Object.entries(categoryMap || {})
    .map(([cat, s], i) => {
      const rate    = s.total > 0 ? ((s.passed / s.total) * 100).toFixed(1) : '0.0';
      const rateNum = parseFloat(rate);
      const rateClr = rateNum >= 95 ? '#4caf50' : rateNum >= 80 ? '#ffc107' : '#f44336';
      const avgDur  = s.total > 0 ? Math.round(s.duration / s.total) : 0;
      return `
      <tr class="${i % 2 === 0 ? 'row-alt' : ''}">
        <td><span class="category-pill">${cat}</span></td>
        <td class="num">${s.total}</td>
        <td class="num passed-text">${s.passed}</td>
        <td class="num ${s.failed > 0 ? 'failed-text' : ''}">${s.failed}</td>
        <td class="num">
          <span style="color:${rateClr};font-weight:700">${rate}%</span>
        </td>
        <td class="num">${s.duration}ms</td>
        <td class="num">${avgDur}ms</td>
      </tr>`;
    })
    .join('\n');

  // ── Test case rows HTML ───────────────────────────────────────────────────
  const testRowsHtml = (results || [])
    .map((r, i) => {
      const statusClass = r.passed ? 'badge-passed' : 'badge-failed';
      const statusText  = r.passed ? 'PASSED' : 'FAILED';
      const errorCell   = r.error
        ? `<span class="error-text" title="${escapeHtml(r.error)}">${escapeHtml(r.error.slice(0, 80))}${r.error.length > 80 ? '…' : ''}</span>`
        : '—';
      return `
      <tr class="${i % 2 === 0 ? 'row-alt' : ''}">
        <td class="num dim">${i + 1}</td>
        <td><span class="category-pill-sm">${escapeHtml(r.category || 'Unknown')}</span></td>
        <td class="test-title">${escapeHtml(r.title || '')}</td>
        <td><span class="badge ${statusClass}">${statusText}</span></td>
        <td class="num">${r.duration}ms</td>
        <td>${errorCell}</td>
      </tr>`;
    })
    .join('\n');

  // ── Full HTML ─────────────────────────────────────────────────────────────
  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Nutrimeal — Android E2E Execution Report</title>
  <meta name="description" content="Nutrimeal Android Appium E2E test execution report — ${total} tests across 11 categories." />
  <style>
    /* ── Reset & Base ─────────────────────────────────────────────────── */
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
      background: #0d0d17;
      color: #e0e0f0;
      line-height: 1.5;
      padding: 0 0 60px;
    }
    a { color: #2d9cdb; }

    /* ── Header ───────────────────────────────────────────────────────── */
    .hero {
      background: linear-gradient(135deg, #1a1a3e 0%, #0f2044 50%, #0d1a2e 100%);
      padding: 48px 32px 40px;
      text-align: center;
      border-bottom: 2px solid #2d9cdb44;
      position: relative;
      overflow: hidden;
    }
    .hero::before {
      content: '';
      position: absolute;
      top: -80px; left: -80px;
      width: 400px; height: 400px;
      background: radial-gradient(circle, #2d9cdb22 0%, transparent 70%);
      animation: pulse 6s ease-in-out infinite;
    }
    @keyframes pulse { 0%,100%{transform:scale(1);opacity:.6} 50%{transform:scale(1.15);opacity:1} }
    .hero h1 {
      font-size: clamp(1.6rem, 4vw, 2.4rem);
      font-weight: 800;
      background: linear-gradient(90deg, #2d9cdb, #a78bfa, #2d9cdb);
      background-size: 200% auto;
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      animation: shine 4s linear infinite;
      margin-bottom: 8px;
    }
    @keyframes shine { to { background-position: 200% center; } }
    .hero p { color: #8899bb; font-size: 0.95rem; }
    .meta-row {
      display: flex;
      flex-wrap: wrap;
      justify-content: center;
      gap: 12px;
      margin-top: 16px;
    }
    .meta-chip {
      background: #1e2a45;
      border: 1px solid #2d9cdb44;
      border-radius: 20px;
      padding: 4px 14px;
      font-size: 0.8rem;
      color: #a0b4cc;
    }

    /* ── Layout ───────────────────────────────────────────────────────── */
    .container { max-width: 1320px; margin: 0 auto; padding: 0 24px; }

    /* ── Stat Cards ───────────────────────────────────────────────────── */
    .stat-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 20px;
      margin: 36px 0;
    }
    .card {
      background: #13131f;
      border-radius: 14px;
      padding: 24px 20px;
      text-align: center;
      border: 1px solid #2a2a44;
      transition: transform .2s, box-shadow .2s;
    }
    .card:hover { transform: translateY(-4px); box-shadow: 0 12px 32px #00000055; }
    .card .num  { font-size: 2.6rem; font-weight: 800; line-height: 1; }
    .card .lbl  { font-size: 0.8rem; color: #7788aa; margin-top: 6px; letter-spacing: .05em; text-transform: uppercase; }
    .card.total  { border-top: 3px solid #2d9cdb; }
    .card.passed { border-top: 3px solid #4caf50; }
    .card.failed { border-top: 3px solid #f44336; }
    .card.rate   { border-top: 3px solid #a78bfa; }
    .color-blue   { color: #2d9cdb; }
    .color-green  { color: #4caf50; }
    .color-red    { color: #f44336; }
    .color-purple { color: #a78bfa; }

    /* ── Pass Rate Bar ────────────────────────────────────────────────── */
    .progress-wrap {
      background: #1a1a2e;
      border-radius: 12px;
      padding: 24px 28px;
      margin-bottom: 32px;
      border: 1px solid #2a2a44;
    }
    .progress-label {
      display: flex;
      justify-content: space-between;
      font-size: 0.88rem;
      color: #8899bb;
      margin-bottom: 10px;
    }
    .progress-track {
      height: 14px;
      background: #2a2a44;
      border-radius: 7px;
      overflow: hidden;
    }
    .progress-fill {
      height: 100%;
      border-radius: 7px;
      background: linear-gradient(90deg, #4caf50, #81d4a0);
      width: 0%;
      transition: width 1.4s cubic-bezier(.4,0,.2,1);
    }

    /* ── Section titles ───────────────────────────────────────────────── */
    .section-title {
      font-size: 1.15rem;
      font-weight: 700;
      color: #c8d8f0;
      margin: 36px 0 16px;
      padding-left: 12px;
      border-left: 3px solid #2d9cdb;
    }

    /* ── Tables ───────────────────────────────────────────────────────── */
    .tbl-wrap { overflow-x: auto; border-radius: 10px; border: 1px solid #2a2a44; margin-bottom: 28px; }
    table { width: 100%; border-collapse: collapse; background: #13131f; font-size: 0.85rem; }
    thead tr { background: #1e1e2e; }
    th {
      padding: 12px 14px;
      text-align: left;
      font-size: 0.78rem;
      color: #8899bb;
      letter-spacing: .06em;
      text-transform: uppercase;
      border-bottom: 1px solid #2a2a44;
      white-space: nowrap;
    }
    td {
      padding: 10px 14px;
      border-bottom: 1px solid #1e1e2e;
      vertical-align: middle;
    }
    tr:last-child td { border-bottom: none; }
    tr.row-alt { background: #0f0f1a; }
    tr:hover { background: #1a1a2e !important; }

    /* ── Cell helpers ─────────────────────────────────────────────────── */
    .num        { text-align: right; font-variant-numeric: tabular-nums; }
    .dim        { color: #445566; }
    .passed-text{ color: #4caf50; font-weight: 600; }
    .failed-text{ color: #f44336; font-weight: 600; }
    .error-text { color: #f44336; font-size: 0.8rem; font-style: italic; }
    .test-title { font-size: 0.82rem; color: #c0d0e8; max-width: 520px; }

    /* ── Badges ───────────────────────────────────────────────────────── */
    .badge {
      display: inline-block;
      padding: 3px 10px;
      border-radius: 4px;
      font-size: 0.75rem;
      font-weight: 700;
      letter-spacing: .04em;
    }
    .badge-passed { background: #4caf5022; color: #4caf50; border: 1px solid #4caf5044; }
    .badge-failed { background: #f4433622; color: #f44336; border: 1px solid #f4433644; }

    /* ── Category pills ───────────────────────────────────────────────── */
    .category-pill {
      background: #1e2a45;
      border: 1px solid #2d9cdb44;
      border-radius: 12px;
      padding: 3px 10px;
      font-size: 0.8rem;
      color: #a0c4dd;
      white-space: nowrap;
    }
    .category-pill-sm {
      background: #1a2030;
      border-radius: 10px;
      padding: 2px 8px;
      font-size: 0.72rem;
      color: #7799bb;
      white-space: nowrap;
    }

    /* ── Footer ───────────────────────────────────────────────────────── */
    .footer {
      text-align: center;
      margin-top: 48px;
      font-size: 0.78rem;
      color: #445566;
    }
  </style>
</head>
<body>

<!-- ── Hero Header ──────────────────────────────────────────────────────── -->
<div class="hero">
  <h1>📱 Nutrimeal Android E2E Execution Report</h1>
  <p>1,111 Tests · 11 Categories · Appium UiAutomator2 · WebDriverIO 8</p>
  <div class="meta-row">
    <span class="meta-chip">▶ Started: ${runStartStr}</span>
    <span class="meta-chip">■ Ended: ${runEndStr}</span>
    <span class="meta-chip">⏱ Duration: ${durationSec}s</span>
    <span class="meta-chip">📦 API 29 · Nexus 6</span>
  </div>
</div>

<div class="container">

  <!-- ── Stat Cards ──────────────────────────────────────────────────────── -->
  <div class="stat-grid">
    <div class="card total">
      <div class="num color-blue" id="cnt-total">0</div>
      <div class="lbl">Total Tests</div>
    </div>
    <div class="card passed">
      <div class="num color-green" id="cnt-passed">0</div>
      <div class="lbl">Passed</div>
    </div>
    <div class="card failed">
      <div class="num color-red" id="cnt-failed">0</div>
      <div class="lbl">Failed</div>
    </div>
    <div class="card rate">
      <div class="num color-purple" id="cnt-rate">0%</div>
      <div class="lbl">Pass Rate</div>
    </div>
    <div class="card total">
      <div class="num color-blue" style="font-size:1.8rem">${durationSec}s</div>
      <div class="lbl">Total Duration</div>
    </div>
  </div>

  <!-- ── Pass Rate Bar ────────────────────────────────────────────────────── -->
  <div class="progress-wrap">
    <div class="progress-label">
      <span>Pass Rate</span>
      <span>${passRateNum.toFixed(2)}%</span>
    </div>
    <div class="progress-track">
      <div class="progress-fill" id="prog-bar"></div>
    </div>
  </div>

  <!-- ── Category Breakdown ───────────────────────────────────────────────── -->
  <h2 class="section-title">Category Breakdown</h2>
  <div class="tbl-wrap">
    <table id="cat-table">
      <thead>
        <tr>
          <th>Category</th>
          <th class="num">Total</th>
          <th class="num">Passed</th>
          <th class="num">Failed</th>
          <th class="num">Pass Rate</th>
          <th class="num">Duration</th>
          <th class="num">Avg Duration</th>
        </tr>
      </thead>
      <tbody>
        ${categoryRowsHtml}
      </tbody>
    </table>
  </div>

  <!-- ── Test Cases Table ─────────────────────────────────────────────────── -->
  <h2 class="section-title">Test Cases (${total} results)</h2>
  <div class="tbl-wrap">
    <table id="results-table">
      <thead>
        <tr>
          <th class="num">#</th>
          <th>Category</th>
          <th>Test Case</th>
          <th>Status</th>
          <th class="num">Duration</th>
          <th>Error</th>
        </tr>
      </thead>
      <tbody>
        ${testRowsHtml}
      </tbody>
    </table>
  </div>

  <div class="footer">
    Generated by NutrimealAppium &mdash; WebDriverIO 8 + Mocha + ExcelJS &mdash; ${new Date().toUTCString()}
  </div>

</div>

<!-- ── Animated Counter Script ──────────────────────────────────────────── -->
<script>
  function animateCount(id, target, suffix, duration) {
    const el = document.getElementById(id);
    if (!el) return;
    let start = 0;
    const step = target / (duration / 16);
    const timer = setInterval(() => {
      start = Math.min(start + step, target);
      el.textContent = Math.round(start) + (suffix || '');
      if (start >= target) clearInterval(timer);
    }, 16);
  }

  window.addEventListener('DOMContentLoaded', () => {
    animateCount('cnt-total',  ${total},  '',  800);
    animateCount('cnt-passed', ${passed}, '',  900);
    animateCount('cnt-failed', ${failed}, '',  900);

    // Pass rate counter
    let rate = 0;
    const rateEl = document.getElementById('cnt-rate');
    const rateStep = ${passRateNum} / (900 / 16);
    const rateTimer = setInterval(() => {
      rate = Math.min(rate + rateStep, ${passRateNum});
      if (rateEl) rateEl.textContent = rate.toFixed(1) + '%';
      if (rate >= ${passRateNum}) clearInterval(rateTimer);
    }, 16);

    // Progress bar
    setTimeout(() => {
      const bar = document.getElementById('prog-bar');
      if (bar) bar.style.width = '${Math.min(passRateNum, 100).toFixed(2)}%';
    }, 100);
  });
</script>

</body>
</html>`;

  fs.writeFileSync(htmlPath, html, 'utf8');
  console.log(`[generateHtmlReport] HTML report → ${htmlPath}`);
  return htmlPath;
}

// ── Escape HTML entities ──────────────────────────────────────────────────────
function escapeHtml(str) {
  return String(str)
    .replace(/&/g,  '&amp;')
    .replace(/</g,  '&lt;')
    .replace(/>/g,  '&gt;')
    .replace(/"/g,  '&quot;')
    .replace(/'/g,  '&#39;');
}

module.exports = { generateHtmlReport };
