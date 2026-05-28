#!/bin/sh
while true; do
  echo "[$(date)] Running Horizon..."
  uv run horizon --hours 24
  echo "[$(date)] Copying latest summary..."
  LATEST=$(ls -t /app/data/summaries/*-en.md 2>/dev/null | head -1)
  if [ -n "$LATEST" ] && [ -s "$LATEST" ]; then
    cp "$LATEST" /app/data/summaries/latest-en.md
    cp "$LATEST" /app/data/summaries/horizon-summary-en.md
    echo "[$(date)] Copied $(basename "$LATEST") -> latest-en.md & horizon-summary-en.md"
  else
    echo "[$(date)] No summary found, skipping copy"
  fi
  echo "[$(date)] Horizon finished, sleeping 24h..."
  sleep 86400
done
