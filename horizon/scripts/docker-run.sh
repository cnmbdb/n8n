#!/bin/sh
# Horizon daily runner. Keep final summaries only in:
#   summaries/archive/horizon-YYYY-MM-DD-{en,zh}.md

set -e

sleep_until_next_8am() {
  SECONDS_TO_WAIT=$(
    python - <<'PY'
from datetime import datetime, timedelta

now = datetime.now()
target = now.replace(hour=8, minute=0, second=0, microsecond=0)
if now >= target:
    target += timedelta(days=1)
print(max(0, int((target - now).total_seconds())))
PY
  )

  echo "[$(date)] Next Horizon run at local 08:00, sleeping ${SECONDS_TO_WAIT}s..."
  sleep "$SECONDS_TO_WAIT"
}

while true; do
  sleep_until_next_8am

  echo "[$(date)] Running Horizon..."
  uv run horizon --hours 24

  echo "[$(date)] Organizing summaries..."
  ARCHIVE=/app/data/summaries/archive
  mkdir -p "$ARCHIVE"

  # Move dated summaries into archive; n8n reads the dated archive file.
  mv /app/data/summaries/horizon-*-en.md "$ARCHIVE/" 2>/dev/null || true
  mv /app/data/summaries/horizon-*-zh.md "$ARCHIVE/" 2>/dev/null || true

  LATEST_EN=$(ls -t "$ARCHIVE"/horizon-*-en.md 2>/dev/null | head -1)
  LATEST_ZH=$(ls -t "$ARCHIVE"/horizon-*-zh.md 2>/dev/null | head -1)

  if [ -n "$LATEST_EN" ] && [ -s "$LATEST_EN" ]; then
    echo "[$(date)] -> $LATEST_EN ($(wc -c < "$LATEST_EN") bytes)"
  else
    echo "[$(date)] WARNING: no en summary in archive"
  fi

  if [ -n "$LATEST_ZH" ] && [ -s "$LATEST_ZH" ]; then
    echo "[$(date)] -> $LATEST_ZH ($(wc -c < "$LATEST_ZH") bytes)"
  else
    echo "[$(date)] WARNING: no zh summary in archive (languages.zh may be disabled)"
  fi

  # Drop redundant aliases so archive remains the single source of truth.
  rm -f /app/data/summaries/latest-en.md
  rm -f /app/data/summaries/horizon-summary-en.md /app/data/summaries/horizon-summary-zh.md
  rm -f "$ARCHIVE"/horizon-summary-en.md "$ARCHIVE"/horizon-summary-zh.md

  echo "[$(date)] Horizon finished."
done
