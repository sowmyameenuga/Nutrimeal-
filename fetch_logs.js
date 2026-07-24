const fs = require('fs');

async function fetchLogs() {
  try {
    const runsRes = await fetch('https://api.github.com/repos/sowmyameenuga/Nutrimeal-/actions/runs?per_page=10');
    const runsData = await runsRes.json();
    const runs = runsData.workflow_runs;
    
    const latestRun = runs.find(r => r.name.includes('Android Appium E2E') || r.path.includes('android-e2e.yml'));
    if (!latestRun) { console.log("No runs found."); return; }
    console.log(`Found Run: ${latestRun.name} (ID: ${latestRun.id}) - Status: ${latestRun.status} - Conclusion: ${latestRun.conclusion}`);
    
    const jobsRes = await fetch(latestRun.jobs_url);
    const jobsData = await jobsRes.json();
    
    for (const job of jobsData.jobs) {
      console.log(`\nJob: ${job.name} (ID: ${job.id})`);
      for (const step of job.steps) {
        console.log(`  Step: ${step.name} - ${step.conclusion}`);
        if (step.conclusion === 'failure') console.log(`   *** FAILED STEP ***`);
      }
    }
  } catch (err) {
    console.error(err);
  }
}

fetchLogs();
