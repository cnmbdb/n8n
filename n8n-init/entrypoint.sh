#!/bin/sh
# n8n entrypoint wrapper - runs all init scripts in /docker-init-scripts/
# then exec's the original n8n entrypoint (tini + /docker-entrypoint.sh)

set -e

# Skip if we are ourselves an init script (avoid recursion)
SCRIPT_NAME=$(basename "$0")

echo "[n8n-wrapper] Running init scripts in /docker-init-scripts/..."
if [ -d /docker-init-scripts ]; then
  for s in /docker-init-scripts/*.sh; do
    [ -f "$s" ] || continue
    name=$(basename "$s")
    [ "$name" = "$SCRIPT_NAME" ] && continue
    echo "[n8n-wrapper] -> $s"
    sh "$s" || echo "[n8n-wrapper] Warning: $s exited non-zero"
  done
fi

echo "[n8n-wrapper] Init done, handing off to n8n entrypoint..."
exec tini -- /docker-entrypoint.sh "$@"
