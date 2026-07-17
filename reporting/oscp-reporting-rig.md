# OSCP Documentation Rig ("docrig")

A zero-AI evidence-capture toolkit for the OSCP exam: one button freezes the last
5 minutes of screen + GUI events + console activity into a timestamped folder and
records a voice-note of your reasoning, so you can write the report the next day.

> Status: design + scaffold scripts. Untested on a live Kali VM — treat as a
> starting point. `compile.sh` (bundle → report) is **not written yet** (see TODO).

---

## 1. Policy guardrails (why the design looks like this)

These are the OffSec rules that shaped every decision. **Re-check them close to your
exam date — OffSec updates this wording periodically.**

- **Interactive AI chatbots/LLMs are banned during BOTH the exam and the reporting
  phase** — OffSec KAI, ChatGPT, Gemini, Copilot, DeepSeek, "and similar AI
  assistants." Using one to write your report counts as third-party help *and* as
  sharing exam content with a third party.
- **Non-interactive / prompt-less AI features are explicitly permitted** — the policy
  names Notion's AI note-organization and Google's AI Overview as allowed. This is the
  carve-out that (probably) covers on-device OCR / speech-to-text, since they transcribe
  *your own* input rather than answering questions.
- **You may NOT video-record your own screen while interacting with exam machines** —
  a screen recording captures exam content (OffSec IP) that could be shared. This is why
  the rig uses a **burst/ring of still screenshots, not a screencast**.
- **Still screenshots of exam content are required and allowed** — you must screenshot
  proof/local flags and your steps for the report.
- **OffSec records your session** (screen-share + webcam, no audio feed) and keeps it
  ~6 months for audit. You can't access that footage; it's not for your report.
- **Recording your own voice locally is fine** — it's a voice note, functionally the
  same as written notes. The proctor can't hear you (no audio feed). The **only**
  AI-sensitive step is turning that audio into text next day.

**Net rule for this rig:** all capture + report-templating is deterministic (not even
in scope of the AI policy). The single AI-exposed surface is narration→text, which you
control after the exam: type it yourself (bulletproof) or use local STT (defensible),
never a cloud/LLM.

Sources:
- AI Usage Policy in OffSec Exams — https://help.offsec.com/hc/en-us/articles/35549468971156-AI-Usage-Policy-in-OffSec-Exams
- OSCP+ Exam Guide — https://help.offsec.com/hc/en-us/articles/360040165632-OSCP-Exam-Guide
- Proctored Exam Requirements FAQ — https://help.offsec.com/hc/en-us/articles/15295546432148-Proctored-Exam-Requirements-FAQ
- Is the proctoring session feed being recorded? — https://help.offsec.com/hc/en-us/articles/360040162232-Is-the-proctoring-session-feed-being-recorded

---

## 2. Architecture

Core principle: **every stream captures continuously and independently; the button
just plants a flag and freezes the last 5 minutes across all streams** into one folder.
Because capture is always-on, forgetting to press the button doesn't lose the data —
the button only marks "this moment matters."

Two phases, cleanly separated:

- **Capture layer** (during exam) — must be rock-solid and light. All deterministic.
- **Compile layer** (next day, offline) — walks the timestamped bundles into a report.
  Overhead here is irrelevant to exam performance.

A "bundle" produced by one button press:

```
oscp-evidence/20260716-143205/
├── frames/              # ~150 stills = last 5 min of screen
├── events.log           # GUI focus changes + mouse clicks (last 5 min)
├── commands-local.log   # timestamped LOCAL shell commands (last 5 min)
├── consoles/            # per-tmux-pane transcripts incl. SSH/tunnelled (last 5 min)
└── narration.opus       # your voice-note explaining the reasoning
```

---

## 3. Capability recap

| Capability | How it's captured | Rotation / storage | Cost (CPU / RAM / disk) | Key caveat |
|---|---|---|---|---|
| **Screenshots, not screencast** | `maim`/`import` ring loop every ~2 s → tmpfs | Keep newest 150 frames (5 min), prune by count; button copies them to the bundle | ~1% of 1 core · ~30–60 MB flat (RAM) · no GPU | Stills not video → policy-clean. JPEG for the ring, crisp PNG for deliberate proof shots |
| **GUI events, multiple windows** | `xprop -spy` focus watcher + `xinput` click watcher → one `events.log` | Append-only, sliced by timestamp on press | ~0% (event-driven) · KB of text | RDP is one client window: you get its title + click coords + the frame, not remote app titles |
| **Console commands, multi-terminal incl. SSH/tunnelled** | tmux `pipe-pane` per-pane (+ `ts` timestamps); local `preexec` index | Per-pane logs + local command index, sliced on press | negligible | **Shell hooks only see local commands** — tmux pane-logging is what captures ssh / tunnelled / pivoted sessions |
| **Narration (rap battles)** | `ffmpeg -f pulse -c:a libopus`, toggled by the button | One `narration.opus` per bundle, auto-stops at 10 min | ~1–3% of 1 core · ~200 KB/min · no GPU | Recording = fine (voice note). **Transcribing next day is the only AI-policy-sensitive step** |
| **The button (glue)** | `mark.sh` toggle via sxhkd / footswitch | Freezes ring + slices logs → `evidence/<ts>/`, starts/stops audio | one-shot, trivial | Toggle state lives in a marker file; 2nd press stops audio |
| **Next-day compile** | Jinja2/Markdown → SysReptor or Pandoc→PDF | Reads bundles; you edit prose | offline; LaTeX / headless-Chromium render is the only heavy bit | Keep templating deterministic = zero-AI report |

---

## 4. Resource budget (1080p, Kali VM)

- **Idle steady-state (whole rig):** ~0% CPU, ~20–40 MB RAM, no GPU.
- **Ring buffer:** bounded (logrotate-style prune), **flat ~30–60 MB** in tmpfs, ~1% of
  one core sustained. Not a video encoder → no persistent encode thread, no GPU needed.
- **Per button press:** copies ~150 frames (~30–60 MB) into the bundle + text slices.
- **Cumulative disk over 24 h:** driven only by how often you press the button.
  ~50 presses ≈ low single-digit GB. **Budget 20–50 GB free and forget it.**
- **Audio:** the cheapest component — ~200 KB/min (Opus), ~1–3% of a core while recording.
- **Levers:** `SHOT_FMT=jpg` halves ring disk vs png; `RING_INTERVAL` trades resolution
  of the replay for CPU/disk (1 s catches fast double-clicks, 2 s is the sweet spot).

---

## 5. Scripts (`~/docrig/`)

### `~/docrig/config.sh` — shared settings
```bash
#!/usr/bin/env bash
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
```

### `~/docrig/ring-capture.sh` — continuous screenshot ring + prune
```bash
#!/usr/bin/env bash
source "$HOME/docrig/config.sh"
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
```

### `~/docrig/event-logger.sh` — GUI focus changes + mouse clicks
```bash
#!/usr/bin/env bash
source "$HOME/docrig/config.sh"
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
```

### `~/docrig/tmux-log-pane.sh` — timestamps each pane's byte-stream (called by tmux)
```bash
#!/usr/bin/env bash
source "$HOME/docrig/config.sh"
mkdir -p "$CMD_LOG_DIR"
exec ts '%Y-%m-%dT%H:%M:%S ' >> "$CMD_LOG_DIR/$1.log"     # reads pane output on stdin
```

### `~/docrig/mark.sh` — THE BIG RED BUTTON (toggle: freeze bundle + start/stop narration)
```bash
#!/usr/bin/env bash
source "$HOME/docrig/config.sh"
STATE="$RING_DIR/.recording"
notify(){ command -v notify-send >/dev/null && notify-send -t 2500 "docrig" "$1"; echo "$1"; }

if [ -f "$STATE" ]; then                                   # --- 2nd press: stop narration ---
  read -r BUNDLE APID < "$STATE"
  kill -INT "$APID" 2>/dev/null                            # let ffmpeg finalize the file
  rm -f "$STATE"; notify "⏹ narration saved → $BUNDLE"; exit 0
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

ffmpeg -hide_banner -loglevel error -f pulse -i default \
       -ac 1 -c:a libopus -b:a 24k -t "$AUDIO_MAX" "$BUNDLE/narration.opus" &   # -f alsa if no Pulse
printf '%s %s\n' "$BUNDLE" "$!" > "$STATE"
notify "🔴 bundle frozen + REC — smash again to stop"
```

---

## 6. Wiring

```bash
# ~/.config/sxhkd/sxhkdrc   (bind your macropad/footswitch key here)
super + shift + space
    ~/docrig/mark.sh
Print
    flameshot gui                      # deliberate high-quality PNG proof shot

# ~/.tmux.conf   (auto-log every pane, incl. SSH/tunnelled — needs moreutils `ts`)
set-hook -g session-created    "pipe-pane -o '~/docrig/tmux-log-pane.sh #{session_name}_#{window_index}_#{pane_index}'"
set-hook -g after-new-window   "pipe-pane -o '~/docrig/tmux-log-pane.sh #{session_name}_#{window_index}_#{pane_index}'"
set-hook -g after-split-window "pipe-pane -o '~/docrig/tmux-log-pane.sh #{session_name}_#{window_index}_#{pane_index}'"

# ~/.zshrc   (precise, timestamped LOCAL command index — does NOT see remote/ssh commands)
preexec() { print -r -- "$(date +%FT%T.%3N)\t$PWD\t$1" >> "$HOME/oscp-evidence/commands-local.log" }

# ~/.xprofile   (start the two always-on daemons at login)
~/docrig/ring-capture.sh & ~/docrig/event-logger.sh &
```

### Dependencies
```bash
sudo apt install maim imagemagick xdotool xinput x11-utils ffmpeg \
                 moreutils sxhkd flameshot tmux libnotify-bin
chmod +x ~/docrig/*.sh
```

---

## 7. Caveats to remember

- **SSH / tunnelled commands:** the `preexec` hook gives a clean *local* command
  timeline but goes blind the moment you `ssh` into a box (keystrokes go to the remote
  shell). **tmux `pipe-pane` logging is the layer that captures remote and pivoted
  sessions**, because it records the pane's byte-stream regardless of where the shell
  lives. That's why both exist — don't rely on the shell hook alone.
- **Transcription is the only AI-exposed surface.** Everything else is deterministic.
  Next day, type up `narration.opus` yourself, or run local on-device STT
  (whisper.cpp / Vosk) — never cloud/LLM.
- **RDP windows:** you get the client window title + click coords + the frames, not the
  semantic titles of remote apps. The frames carry that context.
- **tmux pane logs are raw byte-streams** (ANSI/TUI redraw noise possible with
  full-screen TUIs). Fine for line-oriented tool output; strip ANSI at compile time if
  needed.
- **Audio input:** `-f pulse -i default` assumes Pulse/PipeWire. Use `-f alsa -i default`
  on a pure-ALSA setup.
- **Cross-filesystem note:** `RING_DIR` is tmpfs and the bundle is on disk, so `mark.sh`
  does a real `cp` (not a hardlink). ~30–60 MB, sub-second — fine.

---

## 8. TODO

- [ ] `compile.sh` — walk each `evidence/<ts>/` bundle into a Markdown report section:
      embed frames, commands in code blocks, a placeholder for the transcribed narration.
- [ ] Decide report backend: **SysReptor** (self-hosted, has an OSCP template) vs
      **Pandoc → OffSec Markdown template → PDF**. Both deterministic / zero-AI.
- [ ] Test on the live Kali VM; verify pane-log files actually appear and event slicing
      lines up on timestamps.
- [ ] Optional: physical footswitch / macropad for `mark.sh`.
- [ ] Move this into a real repo and version the scripts.
```
