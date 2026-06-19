const fs = require('fs');
const path = require('path');
const ExcelJS = require('exceljs');
const { generateHtmlReport } = require('./generateHtmlReport');

async function generateReport() {
    const logPath = path.join(__dirname, '..', '.wdio-results.jsonl');
    if (!fs.existsSync(logPath)) return;

    const lines = fs.readFileSync(logPath, 'utf8').split('\n').filter(l => l.trim() !== '');
    const results = lines.map(l => JSON.parse(l));

    const workbook = new ExcelJS.Workbook();
    
    // Sheet 1: Summary
    const summarySheet = workbook.addWorksheet('Summary');
    const total = results.length;
    const passed = results.filter(r => r.passed).length;
    const failed = total - passed;
    
    summarySheet.addRow(['Total Tests', total]);
    summarySheet.addRow(['Passed', passed]);
    summarySheet.addRow(['Failed', failed]);
    summarySheet.addRow(['Pass Rate', `${((passed/total)*100).toFixed(2)}%`]);

    // Sheet 3: Test Cases
    const casesSheet = workbook.addWorksheet('Test Cases');
    casesSheet.columns = [
        { header: 'Test Case', key: 'title', width: 60 },
        { header: 'Status', key: 'status', width: 15 },
        { header: 'Duration (ms)', key: 'duration', width: 15 },
        { header: 'Error', key: 'error', width: 50 }
    ];

    casesSheet.getRow(1).font = { bold: true };

    results.forEach(r => {
        const row = casesSheet.addRow({
            title: r.title,
            status: r.passed ? 'PASSED' : 'FAILED',
            duration: r.duration,
            error: r.error || ''
        });
        row.getCell('status').font = { color: { argb: r.passed ? 'FF008000' : 'FFFF0000' } };
    });

    const outDir = path.join(__dirname, '..', 'Test_Results');
    if (!fs.existsSync(outDir)) {
        fs.mkdirSync(outDir, { recursive: true });
    }

    const outExcel = path.join(outDir, 'android-selenium-report.xlsx');
    await workbook.xlsx.writeFile(outExcel);
    console.log(`Excel report saved to ${outExcel}`);

    generateHtmlReport({total, passed, failed}, results, outDir);
}

module.exports = { generateReport };
