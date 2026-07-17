#!/usr/bin/env bash
# Install the OSCP documentation rig ("docrig") on Kali / any X11 Linux.
#
# Run as your NORMAL user (NOT sudo) — it configures your graphical session and
# dotfiles. It calls sudo itself only to install missing apt packages.
#   ./reporting/install-kali.sh
#
# Locations (override by editing docrig/config.sh, then re-running):
#   ~/docrig            runtime scripts
#   ~/oscp-evidence     captured bundles
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run this as your normal user, not root/sudo — it edits your user session." >&2
  echo "It will call sudo itself only for 'apt-get install'." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
SRC="$SCRIPT_DIR/docrig"
DOCRIG_HOME="$HOME/docrig"
EVIDENCE_DIR="$HOME/oscp-evidence"
AUTOSTART="$HOME/.config/autostart"
SXHKD_CFG="$HOME/.config/sxhkd/sxhkdrc"
ZSHRC="$HOME/.zshrc"
TMUXCONF="$HOME/.tmux.conf"
HOTKEY="${HOTKEY:-super + shift + space}"                 # bind your macropad/footswitch key here

echo "docrig install"
echo "  source   : $SRC"
echo "  runtime  : $DOCRIG_HOME"
echo "  evidence : $EVIDENCE_DIR"
echo "  hotkey   : $HOTKEY"
echo

# --- 1. dependencies (check each binary, install only what's missing) ---
declare -A PKG=(
  [maim]=maim [import]=imagemagick [xdotool]=xdotool [xinput]=xinput
  [xprop]=x11-utils [ffmpeg]=ffmpeg [ts]=moreutils [sxhkd]=sxhkd
  [flameshot]=flameshot [tmux]=tmux [notify-send]=libnotify-bin
)
missing=()
for bin in "${!PKG[@]}"; do
  command -v "$bin" >/dev/null 2>&1 || missing+=("${PKG[$bin]}")
done
if ((${#missing[@]})); then
  mapfile -t missing < <(printf '%s\n' "${missing[@]}" | sort -u)
  echo "Installing packages: ${missing[*]}"
  sudo apt-get update -qq
  sudo apt-get install -y "${missing[@]}"
else
  echo "All dependencies present."
fi

# --- 2. deploy the rig scripts ---
mkdir -p "$DOCRIG_HOME" "$EVIDENCE_DIR"
cp "$SRC"/*.sh "$DOCRIG_HOME"/
chmod +x "$DOCRIG_HOME"/*.sh
echo "Installed scripts -> $DOCRIG_HOME"

# --- helper: idempotent, marker-guarded block in a config file ---
apply_block() {  # $1=file ; block content on stdin (must include the markers)
  local file="$1" tmp
  mkdir -p "$(dirname "$file")"; touch "$file"
  if grep -q '# >>> docrig >>>' "$file"; then              # strip any previous block first
    tmp="$(mktemp)"
    awk '/# >>> docrig >>>/{s=1} s==0{print} /# <<< docrig <<</{s=0}' "$file" > "$tmp"
    mv "$tmp" "$file"
  fi
  cat >> "$file"
  echo "Configured $file"
}

# --- 3. shell command index (zsh preexec; local commands only — tmux covers ssh) ---
apply_block "$ZSHRC" <<EOF
# >>> docrig >>>
autoload -Uz add-zsh-hook
_docrig_cmdlog() { print -r -- "\$(date +%FT%T.%3N)\t\$PWD\t\$1" >> "$EVIDENCE_DIR/commands-local.log" }
add-zsh-hook preexec _docrig_cmdlog
# <<< docrig <<<
EOF

# --- 4. tmux auto-logging of every pane (captures ssh/tunnelled sessions) ---
apply_block "$TMUXCONF" <<EOF
# >>> docrig >>>
set-hook -g session-created    "pipe-pane -o '$DOCRIG_HOME/tmux-log-pane.sh #{session_name}_#{window_index}_#{pane_index}'"
set-hook -g after-new-window   "pipe-pane -o '$DOCRIG_HOME/tmux-log-pane.sh #{session_name}_#{window_index}_#{pane_index}'"
set-hook -g after-split-window "pipe-pane -o '$DOCRIG_HOME/tmux-log-pane.sh #{session_name}_#{window_index}_#{pane_index}'"
# <<< docrig <<<
EOF

# --- 5. hotkeys (sxhkd) ---
apply_block "$SXHKD_CFG" <<EOF
# >>> docrig >>>
$HOTKEY
    $DOCRIG_HOME/mark.sh
Print
    flameshot gui
# <<< docrig <<<
EOF

# --- 6. autostart the two always-on daemons in the graphical session ---
# (XDG autostart, not systemd: these need the live X display / audio session.)
mkdir -p "$AUTOSTART"
gen_autostart() {  # $1=basename  $2=exec
  cat > "$AUTOSTART/$1.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$1
Exec=$2
X-GNOME-Autostart-enabled=true
NoDisplay=true
EOF
  echo "Autostart -> $AUTOSTART/$1.desktop"
}
gen_autostart docrig-ring   "$DOCRIG_HOME/ring-capture.sh"
gen_autostart docrig-events "$DOCRIG_HOME/event-logger.sh"
gen_autostart docrig-sxhkd  "sxhkd"                         # remove if you already run sxhkd

# --- 7. start now so you can test without logging out ---
pgrep -f "$DOCRIG_HOME/ring-capture.sh" >/dev/null || setsid "$DOCRIG_HOME/ring-capture.sh" >/dev/null 2>&1 &
pgrep -f "$DOCRIG_HOME/event-logger.sh" >/dev/null || setsid "$DOCRIG_HOME/event-logger.sh" >/dev/null 2>&1 &
if pgrep -x sxhkd >/dev/null; then pkill -USR1 -x sxhkd; else setsid sxhkd >/dev/null 2>&1 & fi

echo
echo "Done. To activate in existing sessions:"
echo "  - new/reloaded shell : source ~/.zshrc"
echo "  - tmux               : tmux source-file ~/.tmux.conf   (or start a new session)"
echo "Test: press '$HOTKEY' -> a bundle appears in $EVIDENCE_DIR ; press again to stop narration."
echo "Uninstall: ./reporting/uninstall-kali.sh"
