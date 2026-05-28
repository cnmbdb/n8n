#!/bin/sh
# Install community node if not already installed
if [ ! -d /home/node/.n8n/nodes/node_modules ]; then
  echo "Installing wechat community node..."
  mkdir -p /home/node/.n8n/nodes
  cd /home/node/.n8n/nodes
  npm init -y > /dev/null 2>&1
  npm install n8n-nodes-wechat-offiaccount@0.3.6 > /dev/null 2>&1
  cd /
fi
exec /docker-entrypoint.sh n8n start