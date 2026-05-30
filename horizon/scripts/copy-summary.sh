#!/bin/bash
# Copy latest Horizon summary to n8n accessible paths
SRC_DIR="/Users/a2333/IDE/n8n/horizon/data/summaries"

# Copy to local .n8n-files
DST_DIR="/Users/a2333/.n8n-files"
mkdir -p "$DST_DIR"
cp "$SRC_DIR"/*.md "$DST_DIR/"

# Copy latest summary to n8n container
docker exec n8n cp /home/node/.n8n-files/horizon-summaries/horizon-summary-en.md /home/node/.n8n-files/horizon-summary-en.md 2>/dev/null || true

echo "Copied $(ls "$SRC_DIR"/*.md | wc -l) summary files to $DST_DIR and n8n container"
