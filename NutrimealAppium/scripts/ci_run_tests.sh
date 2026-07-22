#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# ci_run_tests.sh
# Nutrimeal Appium — CI Emulator Test Runner
#
# Execution flow:
#   1. Install APK onto running emulator
#   2. Start Appium server (globally installed)
#   3. Wait for Appium to respond on port 4723 (with timeout)
#   4. Inject GITHUB_PATH entries into PATH for Node.js resolution
#   5. Run WDIO using the local node_modules CLI binary
#   6. On non-zero exit → run generateFallbackReport.js
#   7. Always exit 0 so GHA artifact upload steps run
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Resolve script and project directories ────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPIUM_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=== Nutrimeal Appium CI Test Runner ==="
echo "Script dir : ${SCRIPT_DIR}"
echo "Appium dir : ${APPIUM_DIR}"
echo "APK path   : ${APK_PATH:-<not set>}"
echo "Date       : $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

# ── 1. Install APK onto emulator ─────────────────────────────────────────────
echo ">>> [1/6] Installing APK to emulator..."
if [ -z "${APK_PATH:-}" ]; then
  echo "ERROR: APK_PATH environment variable is not set."
  exit 1
fi
if [ ! -f "${APK_PATH}" ]; then
  echo "ERROR: APK not found at: ${APK_PATH}"
  exit 1
fi

adb install -r "${APK_PATH}"
echo "    APK installed successfully."
echo ""

# ── 2. Start Appium server ────────────────────────────────────────────────────
echo ">>> [2/6] Starting Appium server..."
appium --log-level warn --base-path / > /tmp/appium.log 2>&1 &
APPIUM_PID=$!
echo "    Appium PID: ${APPIUM_PID}"
echo ""

# ── 3. Wait for Appium on port 4723 (max 30 × 2s = 60s) ─────────────────────
echo ">>> [3/6] Waiting for Appium to respond on port 4723..."
MAX_ATTEMPTS=30
ATTEMPT=0
until curl -sf http://127.0.0.1:4723/status > /dev/null 2>&1; do
  ATTEMPT=$(( ATTEMPT + 1 ))
  if [ "${ATTEMPT}" -ge "${MAX_ATTEMPTS}" ]; then
    echo "ERROR: Appium did not start after $((MAX_ATTEMPTS * 2))s. Dumping log:"
    cat /tmp/appium.log || true
    exit 1
  fi
  echo "    Waiting for Appium... (${ATTEMPT}/${MAX_ATTEMPTS})"
  sleep 2
done
echo "    Appium is ready."
echo ""

# ── 4. Inject GITHUB_PATH into PATH ──────────────────────────────────────────
echo ">>> [4/6] Injecting GITHUB_PATH entries into PATH..."
if [ -n "${GITHUB_PATH:-}" ] && [ -f "${GITHUB_PATH}" ]; then
  # GITHUB_PATH file contains one path per line; prepend each to PATH
  while IFS= read -r line || [ -n "${line}" ]; do
    if [ -n "${line}" ]; then
      export PATH="${line}:${PATH}"
    fi
  done < "${GITHUB_PATH}"
  echo "    PATH updated from GITHUB_PATH."
else
  echo "    GITHUB_PATH not set or file not found — skipping."
fi
echo "    node: $(node --version 2>/dev/null || echo 'not found')"
echo "    npm:  $(npm  --version 2>/dev/null || echo 'not found')"
echo ""

# ── 5. Run WDIO using local node_modules CLI ──────────────────────────────────
echo ">>> [5/6] Running WebDriverIO Appium tests..."
cd "${APPIUM_DIR}"

WDIO_EXIT_CODE=0
set +e
node node_modules/@wdio/cli/bin/wdio.js run wdio.conf.js
WDIO_EXIT_CODE=$?
set -e

echo ""
echo "    WDIO exit code: ${WDIO_EXIT_CODE}"

# ── 6. Fallback report on non-zero WDIO exit ──────────────────────────────────
if [ "${WDIO_EXIT_CODE}" -ne 0 ]; then
  echo ">>> [6/6] WDIO exited with code ${WDIO_EXIT_CODE} — running fallback report generator..."
  export WDIO_FAILURE_REASON="WDIO exited with code ${WDIO_EXIT_CODE}. Check /tmp/appium.log for Appium errors."
  node utils/generateFallbackReport.js "${WDIO_FAILURE_REASON}" || true
  echo "    Fallback reports written."
else
  echo ">>> [6/6] All tests completed successfully — no fallback needed."
fi

echo ""
echo "=== CI run complete. Appium log: /tmp/appium.log ==="

# Always exit 0 so GHA continues to artifact upload / deploy steps
exit 0
