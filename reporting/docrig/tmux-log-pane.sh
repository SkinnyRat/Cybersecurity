#!/usr/bin/env bash
# Called by tmux (via pipe-pane) for every pane. Reads the pane's byte-stream on
# stdin, timestamps each line with `ts` (moreutils), appends to a per-pane log.
# This captures ssh / tunnelled / pivoted sessions too, because it records at the
# terminal layer — not the local shell (which only sees local commands).
#   arg $1 = pane id, e.g. main_0_1
source "${DOCRIG_HOME:-$HOME/docrig}/config.sh"
mkdir -p "$CMD_LOG_DIR"
exec ts '%Y-%m-%dT%H:%M:%S ' >> "$CMD_LOG_DIR/$1.log"
