#!/usr/bin/env bash
# docrig shared config. Edit locations here, then re-run install-kali.sh.
export DOCRIG_HOME="${DOCRIG_HOME:-$HOME/docrig}"
export EVIDENCE_DIR="${EVIDENCE_DIR:-$HOME/oscp-evidence}"
export RING_DIR="${RING_DIR:-/dev/shm/docrig-ring}"        # RAM-backed: fast, no SSD wear
export EVENT_LOG="${EVENT_LOG:-$EVIDENCE_DIR/events.log}"
export CMD_LOG_DIR="${CMD_LOG_DIR:-$EVIDENCE_DIR/tmux-logs}"
export SHELL_CMD_LOG="${SHELL_CMD_LOG:-$EVIDENCE_DIR/commands-local.log}"
export RING_INTERVAL="${RING_INTERVAL:-2}"                 # seconds between frames
export RING_WINDOW="${RING_WINDOW:-300}"                   # retain window (5 min)
export SHOT_FMT="${SHOT_FMT:-jpg}"                         # jpg = small/fast ring; png = crisp
export AUDIO_MAX="${AUDIO_MAX:-600}"                       # narration auto-stop (10 min)
mkdir -p "$EVIDENCE_DIR" "$RING_DIR" "$CMD_LOG_DIR"
