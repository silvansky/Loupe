#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DEVICE="${LOUPE_DEVICE:-booted}"
PORT="${LOUPE_PORT:-8765}"

cd "$ROOT_DIR"

if ! command -v axe >/dev/null 2>&1; then
  echo "error: runtime E2E requires axe on PATH" >&2
  echo "hint: brew install cameroncooke/axe/axe" >&2
  exit 2
fi

if ! xcrun simctl list devices booted | grep -q Booted; then
  FIRST_DEVICE="$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/ { print $2; exit }')"
  xcrun simctl boot "$FIRST_DEVICE"
  DEVICE="booted"
fi

swift build

xcodebuild \
  -scheme LoupeInjector \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  build >/tmp/loupe-injector-build.log

xcodebuild \
  -project Examples/LoupeExample/LoupeExample.xcodeproj \
  -scheme LoupeExample \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  build >/tmp/loupe-example-build.log

export LOUPE_INJECTOR_PATH="$(
  find "$HOME/Library/Developer/Xcode/DerivedData" \
    -path '*Debug-iphonesimulator/PackageFrameworks/LoupeInjector.framework/LoupeInjector' \
    -print0 | xargs -0 ls -t | head -1
)"

APP_PATH="$(
  find "$HOME/Library/Developer/Xcode/DerivedData" \
    -path '*Debug-iphonesimulator/LoupeExample.app' \
    -print0 | xargs -0 ls -td | head -1
)"

xcrun simctl install "$DEVICE" "$APP_PATH"
xcrun simctl terminate "$DEVICE" dev.loupe.example >/dev/null 2>&1 || true

.build/debug/loupe launch \
  --device "$DEVICE" \
  --bundle-id dev.loupe.example \
  --inject \
  --env LOUPE_PORT="$PORT" >/dev/null

sleep 2

HOST="http://127.0.0.1:$PORT"
SNAPSHOT_PATH="/tmp/loupe-runtime-snapshot.json"
RECORDING_PATH="/tmp/loupe-runtime-recording.json"
SCREENSHOT_PATH="/tmp/loupe-runtime-screen.png"
RUNTIME_PATH="/tmp/loupe-runtime-state.json"

fetch_snapshot() {
  .build/debug/loupe fetch "$HOST/snapshot" --timeout 10 --output "$SNAPSHOT_PATH"
}

curl -sS "$HOST/health" | grep -q LoupeKit
.build/debug/loupe runtime --host "$HOST" --udid "$DEVICE" > "$RUNTIME_PATH"
grep -q '"simulatorUDID"' "$RUNTIME_PATH"
fetch_snapshot
grep -q '"uiKit"' "$SNAPSHOT_PATH"
grep -q '"accessibility"' "$SNAPSHOT_PATH"
read -r WIDTH HEIGHT < <(ruby -rjson -e '
  snapshot = JSON.parse(File.read(ARGV.fetch(0)))
  size = snapshot.fetch("screen").fetch("size")
  puts [size.fetch("width"), size.fetch("height")].join(" ")
' "$SNAPSHOT_PATH")

.build/debug/loupe record start customer-list-scroll --host "$HOST" --udid "$DEVICE" >/tmp/loupe-record-start.json
grep -q '"alias" : "customer-list-scroll"' /tmp/loupe-record-start.json

.build/debug/loupe drag \
  --udid "$DEVICE" \
  --from "$(ruby -e 'puts (ARGV.fetch(0).to_f / 2).round' "$WIDTH"),$(ruby -e 'puts (ARGV.fetch(0).to_f * 0.80).round' "$HEIGHT")" \
  --to "$(ruby -e 'puts (ARGV.fetch(0).to_f / 2).round' "$WIDTH"),$(ruby -e 'puts (ARGV.fetch(0).to_f * 0.35).round' "$HEIGHT")" \
  --duration 0.4 \
  --timeout 8

sleep 1

fetch_snapshot
.build/debug/loupe query "$SNAPSHOT_PATH" --test-id example.customerList >/tmp/loupe-runtime-list-query.json

.build/debug/loupe screenshot \
  --udid "$DEVICE" \
  --output "$SCREENSHOT_PATH"

.build/debug/loupe record stop \
  --host "$HOST" \
  --udid "$DEVICE" >/tmp/loupe-record-stop-path.txt
SAVED_RECORDING_PATH="$(tail -1 /tmp/loupe-record-stop-path.txt)"
cp "$SAVED_RECORDING_PATH" "$RECORDING_PATH"
.build/debug/loupe recordings >/tmp/loupe-recordings-list.txt
grep -q 'customer-list-scroll' /tmp/loupe-recordings-list.txt

grep -q '"events"' "$RECORDING_PATH"
grep -q '"kind" : "touch"' "$RECORDING_PATH"
grep -q '"appIdentity"' "$RECORDING_PATH"
grep -q '"simulatorUDID"' "$RECORDING_PATH"
grep -q '"alias" : "customer-list-scroll"' "$RECORDING_PATH"
grep -q '"targetCandidates"' "$RECORDING_PATH"
grep -q '"selector"' "$RECORDING_PATH"

xcrun simctl terminate "$DEVICE" dev.loupe.example >/dev/null 2>&1 || true
.build/debug/loupe launch \
  --device "$DEVICE" \
  --bundle-id dev.loupe.example \
  --inject \
  --env LOUPE_PORT="$PORT" >/dev/null
sleep 2

.build/debug/loupe replay customer-list-scroll \
  --host "$HOST" \
  --udid "$DEVICE" \
  --width "$WIDTH" \
  --height "$HEIGHT"
.build/debug/loupe wait-for-visible --host "$HOST" --test-id example.customerList --timeout 5 >/tmp/loupe-runtime-replay-list.json

echo "runtime E2E smoke passed"
echo "runtime: $RUNTIME_PATH"
echo "snapshot: $SNAPSHOT_PATH"
echo "recording: $RECORDING_PATH"
echo "screenshot: $SCREENSHOT_PATH"
