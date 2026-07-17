#!/usr/bin/env bash
# Always-on daemon: logs GUI activity across all windows to EVENT_LOG.
#   FOCUS lines = which window you switched to, and when (Bloodhound / Burp / RDP / ...)
#   CLICK lines = mouse-click coordinates (best-effort, needs xinput)
# Together with the screenshot ring, this lets you reconstruct exactly what you
# clicked without a high frame rate.
source "${DOCRIG_HOME:-$HOME/docrig}/config.sh"

log_focus() {   # which GUI you're in, and when you switched
  xprop -spy -root _NET_ACTIVE_WINDOW 2>/dev/null | while read -r line; do
    wid=$(grep -o '0x[0-9a-fA-F]\+' <<<"$line" | head -n1); [ -z "$wid" ] && continue
    name=$(xdotool getwindowname "$wid" 2>/dev/null)
    printf '%s\tFOCUS\t%s\n' "$(date +%FT%T.%3N)" "$name" >> "$EVENT_LOG"
  done
}

log_clicks() {  # best-effort click coords (where you clicked in Bloodhound etc.)
  xinput test-xi2 --root 2>/dev/null | awk '
    /\(ButtonPress\)/ {b=1; next}
    b && /root:/ { c=$0; gsub(/[^0-9.\/]/,"",c); split(c,a,"/");
      ("date +%FT%T.%3N"|getline ts); close("date +%FT%T.%3N");
      printf "%s\tCLICK\t%s,%s\n", ts, a[1], a[2]; fflush(); b=0 }' >> "$EVENT_LOG"
}

log_focus & log_clicks & wait
