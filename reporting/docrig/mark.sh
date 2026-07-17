#!/usr/bin/env bash
# THE BIG RED BUTTON. Toggle:
#   1st press -> freeze the last RING_WINDOW seconds (frames + events + console +
#                local commands) into a timestamped bundle, and START narration.
#   2nd press -> STOP narration (ffmpeg finalizes the file).
source "${DOCRIG_HOME:-$HOME/docrig}/config.sh"
STATE="$RING_DIR/.recording"
notify(){ command -v notify-send >/dev/null && notify-send -t 2500 "docrig" "$1"; echo "$1"; }

if [ -f "$STATE" ]; then                                   # --- 2nd press: stop narration ---
  read -r BUNDLE APID < "$STATE"
  kill -INT "$APID" 2>/dev/null                            # let ffmpeg finalize the file
  rm -f "$STATE"; notify "⏹ narration saved -> $BUNDLE"; exit 0
fi

BUNDLE="$EVIDENCE_DIR/$(date +%Y%m%d-%H%M%S)"              # --- 1st press: freeze + record ---
mkdir -p "$BUNDLE/frames" "$BUNDLE/consoles"
cutoff_ms=$(date -d "-$RING_WINDOW seconds" +%FT%T.%3N)
cutoff_s=$(date  -d "-$RING_WINDOW seconds" +%FT%T)

cp "$RING_DIR"/*."$SHOT_FMT" "$BUNDLE/frames/" 2>/dev/null || true          # freeze last 5 min
awk -v c="$cutoff_ms" '$1>=c' "$EVENT_LOG"      > "$BUNDLE/events.log"         2>/dev/null
awk -v c="$cutoff_ms" '$1>=c' "$SHELL_CMD_LOG"  > "$BUNDLE/commands-local.log" 2>/dev/null
for f in "$CMD_LOG_DIR"/*.log; do [ -e "$f" ] || continue
  awk -v c="$cutoff_s" '$1>=c' "$f" > "$BUNDLE/consoles/$(basename "$f")" 2>/dev/null
done

# Narration: auto-stops after AUDIO_MAX as a safety net. Use `-f alsa` if no Pulse/PipeWire.
ffmpeg -hide_banner -loglevel error -f pulse -i default \
       -ac 1 -c:a libopus -b:a 24k -t "$AUDIO_MAX" "$BUNDLE/narration.opus" &
printf '%s %s\n' "$BUNDLE" "$!" > "$STATE"
notify "🔴 bundle frozen + REC — smash again to stop"
