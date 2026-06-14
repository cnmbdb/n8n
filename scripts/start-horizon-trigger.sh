#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PLIST_SRC="$ROOT_DIR/launchd/com.a2333.horizon-trigger.plist"
PLIST_DST="$HOME/Library/LaunchAgents/com.a2333.horizon-trigger.plist"
LABEL="com.a2333.horizon-trigger"

mkdir -p "$ROOT_DIR/logs"
mkdir -p "$HOME/Library/LaunchAgents"

cp "$PLIST_SRC" "$PLIST_DST"
launchctl bootout "gui/$(id -u)" "$PLIST_DST" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DST"
launchctl kickstart -k "gui/$(id -u)/$LABEL"

echo "Started Horizon trigger watcher."
echo "The HTTP trigger is available only while the Horizon container is running."
echo "Health, when Horizon is running: http://127.0.0.1:8765/health"
