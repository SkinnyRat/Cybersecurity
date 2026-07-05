#!/usr/bin/env bash
# Started by the workflowhelper systemd service (also runs standalone).
# Serves two things:
#   1. WorkflowHelper.html + notes on 127.0.0.1:18888  (localhost only)
#   2. A file-transfer "toolbox" dir on 0.0.0.0:80      (reachable by targets)
# Pulls the latest notes first.
set -u

# --- Notes server (localhost) ---
PORT="${PORT:-18888}"
BIND="${BIND:-127.0.0.1}"

# --- Toolbox transfer server (target-facing) ---
TOOLBOX_DIR="${TOOLBOX_DIR:-/home/user/Documents}"
TOOLBOX_PORT="${TOOLBOX_PORT:-80}"
TOOLBOX_BIND="${TOOLBOX_BIND:-0.0.0.0}"   # set to a tun0 IP to limit exposure to the VPN

# Resolve the repo root from this script's own location, so paths don't matter.
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
REPO_DIR="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$SCRIPT_DIR/..")"
cd "$REPO_DIR" || exit 1

# Best-effort refresh; never let a failed pull stop the servers.
echo "[workflowhelper] pulling latest in $REPO_DIR"
git config --global --add safe.directory "$REPO_DIR" 2>/dev/null || true
timeout 20 git pull --ff-only 2>&1 || echo "[workflowhelper] git pull skipped/failed — serving current copy"

# Toolbox transfer server in the background (skipped if its dir is missing).
TOOLBOX_PID=""
if [[ -d "$TOOLBOX_DIR" ]]; then
  echo "[workflowhelper] toolbox: http://$TOOLBOX_BIND:$TOOLBOX_PORT/  ($TOOLBOX_DIR)"
  python3 -m http.server "$TOOLBOX_PORT" --bind "$TOOLBOX_BIND" --directory "$TOOLBOX_DIR" &
  TOOLBOX_PID=$!
else
  echo "[workflowhelper] toolbox dir '$TOOLBOX_DIR' not found — skipping transfer server"
fi
# On Ctrl+C / stop of a standalone run, take the background server down too.
# (Under systemd, KillMode=control-group already reaps the whole cgroup.)
trap '[[ -n "$TOOLBOX_PID" ]] && kill "$TOOLBOX_PID" 2>/dev/null' INT TERM EXIT

echo "[workflowhelper] notes:   http://$BIND:$PORT/WorkflowHelper.html"
python3 -m http.server "$PORT" --bind "$BIND" --directory "$REPO_DIR"
