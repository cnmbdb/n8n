#!/bin/bash
# Run Horizon and copy summary for n8n
cd /Users/a2333/IDE/n8n/horizon

echo "[$(date)] Running Horizon..."
uv run horizon --hours 24 2>&1 || echo "Horizon completed with warnings"

echo "[$(date)] Copying latest summary..."
LATEST=$(ls -t data/summaries/horizon-*-en.md 2>/dev/null | head -1)
if [ -n "$LATEST" ]; then
  # Only overwrite if the new file has real content (more than 200 bytes)
  FILESIZE=$(wc -c < "$LATEST")
  if [ "$FILESIZE" -gt 200 ]; then
    cp "$LATEST" /Users/a2333/.n8n-files/horizon-summary-en.md
    echo "[$(date)] Copied $LATEST ($FILESIZE bytes)"
  else
    echo "[$(date)] WARNING: Summary too small ($FILESIZE bytes), keeping previous version"
  fi
else
  echo "[$(date)] ERROR: No summary file found"
  exit 1
fi

echo "[$(date)] Done!"
