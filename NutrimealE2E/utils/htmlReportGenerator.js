const fs = require('fs');
const path = require('path');

function generateHtmlReport(stats, categories, results, outDir) {
    const htmlPath = path.join(outDir, 'HTML', 'execution-report.html');
    if (!fs.existsSync(path.dirname(htmlPath))) {
        fs.mkdirSync(path.dirname(htmlPath), { recursive: true });
    }

    const htmlContent = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mega Web E2E Execution Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #121212; color: #e0e0e0; margin: 0; padding: 20px; }
        .container { max-width: 1200px; margin: auto; }
        .header { text-align: center; margin-bottom: 30px; }
        h1 { color: #ffffff; }
        .summary-cards { display: flex; justify-content: space-between; margin-bottom: 30px; }
        .card { background: #1e1e1e; padding: 20px; border-radius: 8px; text-align: center; flex: 1; margin: 0 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.3); }
        .card.passed { border-bottom: 4px solid #4caf50; }
        .card.failed { border-bottom: 4px solid #f44336; }
        .card.total { border-bottom: 4px solid #2196f3; }
        .card h2 { margin: 0 0 10px 0; font-size: 2em; }
        table { width: 100%; border-collapse: collapse; background: #1e1e1e; border-radius: 8px; overflow: hidden; }
        th, td { padding: 12px 15px; text-align: left; border-bottom: 1px solid #333; }
        th { background: #2c2c2c; color: #fff; }
        tr:hover { background: #2a2a2a; }
        .badge { padding: 5px 10px; border-radius: 4px; font-weight: bold; font-size: 0.9em; }
        .badge.passed { background: rgba(76, 175, 80, 0.2); color: #4caf50; }
        .badge.failed { background: rgba(244, 67, 54, 0.2); color: #f44336; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Mega Web E2E Execution Report</h1>
            <p>1,100 Tests Suite - Nutritional App Frontend</p>
        </div>
        
        <div class="summary-cards">
            <div class="card total">
                <h2 id="total">${stats.total}</h2>
                <p>Total Tests</p>
            </div>
            <div class="card passed">
                <h2 id="passed" style="color: #4caf50;">${stats.passed}</h2>
                <p>Passed</p>
            </div>
            <div class="card failed">
                <h2 id="failed" style="color: #f44336;">${stats.failed}</h2>
                <p>Failed</p>
            </div>
        </div>

        <h3>Test Results Details</h3>
        <table>
            <thead>
                <tr>
                    <th>Category</th>
                    <th>Test Case</th>
                    <th>Status</th>
                    <th>Duration (ms)</th>
                </tr>
            </thead>
            <tbody>
                ${results.map(r => `
                <tr>
                    <td>${r.category}</td>
                    <td>${r.title}</td>
                    <td><span class="badge ${r.status.toLowerCase()}">${r.status}</span></td>
                    <td>${r.duration}</td>
                </tr>
                `).join('')}
            </tbody>
        </table>
    </div>
</body>
</html>`;

    fs.writeFileSync(htmlPath, htmlContent);
    console.log(`HTML report generated at ${htmlPath}`);
}

module.exports = { generateHtmlReport };
