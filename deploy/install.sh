#!/usr/bin/env bash
# Install the workflowhelper systemd service on Kali (or any systemd Linux).
# Run from anywhere:   sudo ./deploy/install.sh
# It auto-detects the repo path and the user to run as.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run with sudo:  sudo $0" >&2
  exit 1
fi

# The unprivileged user who owns the clone (the one who invoked sudo).
RUN_USER="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
REPO_DIR="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
SERVE="$REPO_DIR/deploy/serve.sh"
UNIT="/etc/systemd/system/workflowhelper.service"

chmod +x "$SERVE"

echo "Installing $UNIT"
echo "  repo : $REPO_DIR"
echo "  user : $RUN_USER"
echo "  url  : http://127.0.0.1:18888/WorkflowHelper.html"

cat > "$UNIT" <<EOF
[Unit]
Description=WorkflowHelper — git pull, notes on :18888, toolbox on :80
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$RUN_USER
WorkingDirectory=$REPO_DIR
ExecStart=$SERVE
# Let the unprivileged user bind port 80 for the toolbox server (no root needed).
AmbientCapabilities=CAP_NET_BIND_SERVICE
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now workflowhelper.service

echo
systemctl --no-pager --full status workflowhelper.service | head -n 12 || true
echo
echo "Done. Open  http://127.0.0.1:18888/WorkflowHelper.html"
echo "Logs:  journalctl -u workflowhelper -f"
