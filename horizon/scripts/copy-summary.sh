#!/bin/bash
# Copy latest Horizon summary to n8n allowed directory
SRC_DIR="/Users/a2333/IDE/n8n/horizon/data/summaries"
DST_DIR="/Users/a2333/.n8n-files"
mkdir -p "$DST_DIR"
cp "$SRC_DIR"/*.md "$DST_DIR/"
echo "Copied $(ls "$SRC_DIR"/*.md | wc -l) summary files"
