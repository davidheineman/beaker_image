#!/bin/bash

source /root/.bashrc

# Authenticate with git
gitlogin || true
gcplogin || true

# Authenticate with Docker
dockerlogin || true

# Start VS code servers
# export PATH="/root/.vscode-server/bin:/root/.vscode-server/bin/bin:$PATH"
# export PATH="/root/.cursor-server/bin:/root/.cursor-server/bin/bin:$PATH"
# code-server --accept-server-license-terms --connection-token=remotessh --start-server
# nohup code-server --bind-addr 0.0.0.0:8080 --accept-server-license-terms > /tmp/code-server.log 2>&1 &
# nohup cursor-server --bind-addr 0.0.0.0:8080 --accept-server-license-terms > /tmp/cursor-server.log 2>&1 &

# Start OpenSSH server
exec /usr/sbin/sshd -D
