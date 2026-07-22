/**
 * generateSummary.js
 * ─────────────────────────────────────────────────────────────────────────────
 * Nutrimeal Appium — GitHub Actions Step Summary & stdout Reporter
 *
 * Appends a Markdown summary to $GITHUB_STEP_SUMMARY (GHA) and also
 * prints it to stdout so it is visible in any CI/CD console.
 *
 * Usage (standalone):
 *   node utils/generateSummary.js
 *
 * API (programmatic):
 *   const { generateSummary } = require('./generateSummary');
 *   generateSummary(stats, categoryMap);
 * ─────────────────────────────────────────────────────────────────────────────
 */

'use strict';

const fs   = require('fs');
const path = require('path');

/**
 * generateSummary(stats, categoryMap)
 *
 * @param {object} stats        — { total, passed, failed, passRate, runStart, runEnd, totalDuration }
 * @param {object} categoryMap  — { CategoryName: { total, passed, failed, duration } }
 */
function generateSummary(stats, categoryMap) {
  const { total, passed, failed, passRate, totalDuration } = stats || {};
  const durationSec = totalDuration ? (totalDuration / 1000).toFixed(2) : '0.00';
  const rate = parseFloat(passRate) || 0;
  const rateEmoji = rate >= 95 ? '🟢' : rate >= 80 ? '🟡' : '🔴';

  // ── Build Markdown ────────────────────────────────────────────────────────
  const lines = [
    '',
    '## 📱 Nutrimeal Android Appium E2E — Test Summary',
    '',
    `| Metric           | Value                       |`,
    `|------------------|-----------------------------|`,
    `| **Total Tests**  | ${total ?? '—'}             |`,
    `| **Passed**       | ✅ ${passed ?? '—'}         |`,
    `| **Failed**       | ❌ ${failed ?? '—'}         |`,
    `| **Pass Rate**    | ${rateEmoji} ${rate.toFixed(2)}% |`,
    `| **Duration**     | ⏱ ${durationSec}s           |`,
    '',
  ];

  // Category table
  if (categoryMap && Object.keys(categoryMap).length > 0) {
    lines.push('### By Category');
    lines.push('');
    lines.push('| Category | Total | Passed | Failed | Pass Rate |');
    lines.push('|----------|------:|-------:|-------:|----------:|');

    Object.entries(categoryMap).forEach(([cat, s]) => {
      const catRate = s.total > 0 ? ((s.passed / s.total) * 100).toFixed(1) : '0.0';
      const catEmoji = parseFloat(catRate) >= 95 ? '🟢' : parseFloat(catRate) >= 80 ? '🟡' : '🔴';
      lines.push(`| ${cat} | ${s.total} | ${s.passed} | ${s.failed} | ${catEmoji} ${catRate}% |`);
    });

    lines.push('');
  }

  // Link to HTML report
  const repoOwner  = process.env.GITHUB_REPOSITORY_OWNER || '';
  const repoName   = (process.env.GITHUB_REPOSITORY || '').replace(`${repoOwner}/`, '');
  if (repoOwner && repoName) {
    const reportUrl = `https://${repoOwner}.github.io/${repoName}/reports/latest/execution-report.html`;
    lines.push(`> 🔗 [View Full HTML Report](${reportUrl})`);
    lines.push('');
  }

  const markdown = lines.join('\n');

  // ── Print to stdout ───────────────────────────────────────────────────────
  console.log(markdown);

  // ── Write to $GITHUB_STEP_SUMMARY ─────────────────────────────────────────
  const ghSummaryPath = process.env.GITHUB_STEP_SUMMARY;
  if (ghSummaryPath) {
    try {
      fs.appendFileSync(ghSummaryPath, markdown + '\n', 'utf8');
      console.log(`[generateSummary] Summary written to $GITHUB_STEP_SUMMARY`);
    } catch (err) {
      console.warn(`[generateSummary] Could not write to GITHUB_STEP_SUMMARY: ${err.message}`);
    }
  }
}

module.exports = { generateSummary };

// ── Standalone execution ──────────────────────────────────────────────────────
if (require.main === module) {
  // Try to load results from JSONL for standalone use
  const logPath = path.join(__dirname, '..', '.wdio-results.jsonl');
  if (!fs.existsSync(logPath)) {
    console.warn('[generateSummary] No .wdio-results.jsonl found — printing empty summary.');
    generateSummary({ total: 0, passed: 0, failed: 0, passRate: '0.00', totalDuration: 0 }, {});
    process.exit(0);
  }

  const lines = fs.readFileSync(logPath, 'utf8').split('\n').filter((l) => l.trim());
  const results = lines.map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);

  const total  = results.length;
  const passed = results.filter((r) => r.passed).length;
  const failed = total - passed;
  const passRate = total > 0 ? ((passed / total) * 100).toFixed(2) : '0.00';
  const totalDuration = results.reduce((a, r) => a + (r.duration || 0), 0);

  const categoryMap = {};
  results.forEach((r) => {
    const cat = r.category || 'Unknown';
    if (!categoryMap[cat]) categoryMap[cat] = { total: 0, passed: 0, failed: 0, duration: 0 };
    categoryMap[cat].total++;
    categoryMap[cat].duration += (r.duration || 0);
    if (r.passed) categoryMap[cat].passed++;
    else categoryMap[cat].failed++;
  });

  generateSummary({ total, passed, failed, passRate, totalDuration }, categoryMap);
}
