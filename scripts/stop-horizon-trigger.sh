#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PLIST_DST="$HOME/Library/LaunchAgents/com.a2333.horizon-trigger.plist"

if [ -f "$PLIST_DST" ]; then
  launchctl bootout "gui/$(id -u)" "$PLIST_DST" 2>/dev/null || true
  echo "Stopped Horizon trigger watcher."
else
  echo "Horizon trigger watcher is not installed."
fi
