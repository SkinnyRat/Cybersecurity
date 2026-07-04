#!/usr/bin/env bash
# Serve WorkflowHelper.html (and the repo) on 127.0.0.1:18888.
# Pulls the latest notes first, then starts a static HTTP server.
# Designed to be launched by the workflowhelper systemd service, but also
# runs fine standalone:  ./deploy/serve.sh
set -u

PORT="${PORT:-18888}"
BIND="${BIND:-127.0.0.1}"   # set BIND=0.0.0.0 to expose on the LAN (careful on hostile networks)

# Resolve the repo root from this script's own location, so paths don't matter.
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
REPO_DIR="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$SCRIPT_DIR/..")"
cd "$REPO_DIR" || exit 1

# Best-effort refresh; never let a failed pull stop the server (offline boot, etc.).
echo "[workflowhelper] pulling latest in $REPO_DIR"
git config --global --add safe.directory "$REPO_DIR" 2>/dev/null || true
timeout 20 git pull --ff-only 2>&1 || echo "[workflowhelper] git pull skipped/failed — serving current copy"

echo "[workflowhelper] serving http://$BIND:$PORT/WorkflowHelper.html"
exec python3 -m http.server "$PORT" --bind "$BIND" --directory "$REPO_DIR"
