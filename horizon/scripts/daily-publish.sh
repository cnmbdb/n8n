#!/bin/bash
# Run Horizon and keep summaries in data/summaries/archive
cd /Users/a2333/IDE/n8n/horizon

echo "[$(date)] Running Horizon..."
uv run horizon --hours 24 2>&1 || echo "Horizon completed with warnings"

echo "[$(date)] Organizing summaries..."
ARCHIVE="data/summaries/archive"
mkdir -p "$ARCHIVE"

mv data/summaries/horizon-*-en.md "$ARCHIVE/" 2>/dev/null || true
mv data/summaries/horizon-*-zh.md "$ARCHIVE/" 2>/dev/null || true
rm -f data/summaries/latest-en.md
rm -f data/summaries/horizon-summary-en.md data/summaries/horizon-summary-zh.md
rm -f "$ARCHIVE"/horizon-summary-en.md "$ARCHIVE"/horizon-summary-zh.md

LATEST=$(ls -t "$ARCHIVE"/horizon-*-en.md 2>/dev/null | head -1)
if [ -n "$LATEST" ] && [ -s "$LATEST" ]; then
  echo "[$(date)] Latest archive: $LATEST ($(wc -c < "$LATEST") bytes)"
else
  echo "[$(date)] ERROR: No archived summary file found"
  exit 1
fi

echo "[$(date)] Done!"
