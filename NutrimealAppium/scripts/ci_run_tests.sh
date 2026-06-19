#!/bin/bash
set -e

echo "Installing APK to emulator..."
adb install -r "${APK_PATH}"

echo "Starting Appium server in background..."
npx appium --log-level warn > /tmp/appium.log 2>&1 &

echo "Waiting for Appium to start..."
until curl -s http://127.0.0.1:4723/status > /dev/null; do
    sleep 2
done
echo "Appium started."

echo "Injecting GITHUB_PATH into PATH for Node.js resolution..."
if [ -f "$GITHUB_PATH" ]; then
    export PATH="$(cat $GITHUB_PATH | tr '\n' ':')$PATH"
fi

echo "Running WDIO Appium Tests..."
cd NutrimealAppium
npx wdio run wdio.conf.js || {
    echo "WDIO tests finished with failures, but generating report..."
}
