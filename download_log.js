const fs = require('fs');

async function downloadLog() {
  try {
    const res = await fetch('https://api.github.com/repos/sowmyameenuga/Nutrimeal-/actions/jobs/82876891653/logs');
    if (!res.ok) {
      console.log(`Failed to fetch logs: ${res.statusText}`);
      const text = await res.text();
      console.log(text);
      return;
    }
    const text = await res.text();
    fs.writeFileSync('job_log.txt', text);
    console.log('Saved to job_log.txt');
  } catch (err) {
    console.error(err);
  }
}

downloadLog();
