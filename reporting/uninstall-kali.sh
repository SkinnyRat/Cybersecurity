#!/usr/bin/env bash
# Remove the docrig rig. Keeps your captured evidence (never deletes ~/oscp-evidence).
# Run as your normal user:  ./reporting/uninstall-kali.sh
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run as your normal user, not sudo." >&2; exit 1
fi

DOCRIG_HOME="$HOME/docrig"
AUTOSTART="$HOME/.config/autostart"

# stop daemons (leave sxhkd running — you may use it for other things)
pkill -f "$DOCRIG_HOME/ring-capture.sh" 2>/dev/null || true
pkill -f "$DOCRIG_HOME/event-logger.sh" 2>/dev/null || true

strip_block() {  # remove the marker-guarded block from a file, if present
  local file="$1"
  [ -f "$file" ] || return 0
  if grep -q '# >>> docrig >>>' "$file"; then
    local tmp; tmp="$(mktemp)"
    awk '/# >>> docrig >>>/{s=1} s==0{print} /# <<< docrig <<</{s=0}' "$file" > "$tmp"
    mv "$tmp" "$file"; echo "Cleaned $file"
  fi
}
strip_block "$HOME/.zshrc"
strip_block "$HOME/.tmux.conf"
strip_block "$HOME/.config/sxhkd/sxhkdrc"

rm -f "$AUTOSTART/docrig-ring.desktop" "$AUTOSTART/docrig-events.desktop" "$AUTOSTART/docrig-sxhkd.desktop"
rm -rf "$DOCRIG_HOME"

echo "Removed docrig. Evidence kept at ~/oscp-evidence."
echo "Reload with: source ~/.zshrc ; tmux source-file ~/.tmux.conf"
