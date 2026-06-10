#!/bin/sh
# Horizon daily runner. Keeps summaries/ root clean:
#   summaries/horizon-summary-en.md   <- latest English (n8n reads this)
#   summaries/horizon-summary-zh.md   <- latest Chinese
#   summaries/archive/horizon-YYYY-MM-DD-{en,zh}.md  <- history

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

  # Move today's dated files into archive/
  mv /app/data/summaries/horizon-*-en.md "$ARCHIVE/" 2>/dev/null || true
  mv /app/data/summaries/horizon-*-zh.md "$ARCHIVE/" 2>/dev/null || true

  # Copy the most recent en/zh from archive back to root with stable names
  LATEST_EN=$(ls -t "$ARCHIVE"/horizon-*-en.md 2>/dev/null | head -1)
  LATEST_ZH=$(ls -t "$ARCHIVE"/horizon-*-zh.md 2>/dev/null | head -1)

  if [ -n "$LATEST_EN" ] && [ -s "$LATEST_EN" ]; then
    cp "$LATEST_EN" /app/data/summaries/horizon-summary-en.md
    echo "[$(date)] -> horizon-summary-en.md ($(wc -c < "$LATEST_EN") bytes)"
  else
    echo "[$(date)] WARNING: no en summary in archive"
  fi

  if [ -n "$LATEST_ZH" ] && [ -s "$LATEST_ZH" ]; then
    cp "$LATEST_ZH" /app/data/summaries/horizon-summary-zh.md
    echo "[$(date)] -> horizon-summary-zh.md ($(wc -c < "$LATEST_ZH") bytes)"
  else
    echo "[$(date)] WARNING: no zh summary in archive (languages.zh may be disabled)"
  fi

  # Drop the redundant alias
  rm -f /app/data/summaries/latest-en.md

  echo "[$(date)] Horizon finished."
done
