#!/usr/bin/env bash
# Continuous screenshot ring buffer with logrotate-style pruning.
# Always-on daemon: grabs a full-screen still every RING_INTERVAL seconds into a
# RAM-backed dir, keeping only the last RING_WINDOW seconds' worth. mark.sh freezes
# a copy of the current ring into an evidence bundle when you press the button.
source "${DOCRIG_HOME:-$HOME/docrig}/config.sh"

grab() {  # full-screen grab; jpg via ImageMagick, png via maim
  case "$SHOT_FMT" in
    jpg) import -silent -window root -quality 85 "$1" 2>/dev/null ;;
    *)   maim "$1" 2>/dev/null ;;
  esac
}

keep=$(( RING_WINDOW / RING_INTERVAL ))                    # e.g. 300/2 = 150 frames
while true; do
  grab "$RING_DIR/$(date +%s%3N).$SHOT_FMT"
  ls -1t "$RING_DIR"/*."$SHOT_FMT" 2>/dev/null | tail -n +$((keep+1)) | xargs -r rm -f
  sleep "$RING_INTERVAL"
done
