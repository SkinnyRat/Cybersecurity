# reporting/

Zero-AI evidence-capture rig ("docrig") for the OSCP exam. One button freezes the last
5 minutes of screen + GUI events + console activity into a timestamped folder and records
a voice-note of your reasoning, so you can write the report the next day.

Installed **separately** from the pentest toolbox in `deploy/` — this directory is purely
the reporting side.

> **Why it's built this way** (OffSec AI ban, the no-screencast rule, resource budget,
> the architecture) lives in **[oscp-reporting-rig.md](oscp-reporting-rig.md)**. This
> README is just install + usage.

```
reporting/
├── oscp-reporting-rig.md   # design doc: policy, architecture, cost, caveats
├── docrig/                 # the capture rig (deployed to ~/docrig by the installer)
│   ├── config.sh           # locations + tunables (edit here, then re-run installer)
│   ├── ring-capture.sh     # always-on screenshot ring buffer (last 5 min)
│   ├── event-logger.sh     # always-on GUI focus + mouse-click logger
│   ├── tmux-log-pane.sh    # per-pane console logger (ssh/tunnelled included)
│   └── mark.sh             # THE BIG RED BUTTON: freeze bundle + toggle narration
├── install-kali.sh         # sets up the rig on Kali (the real installer)
├── uninstall-kali.sh       # clean removal (keeps your evidence)
├── install-windows.ps1     # OPTIONAL: preps the host for the next-day compile phase
└── README.md
```

## What runs where

| Phase | Host | Component |
|-------|------|-----------|
| **Capture** (during exam) | **Kali VM** | ring buffer, event logger, tmux logging, `mark.sh` — X11/Linux only |
| **Compile** (next day) | Kali *or* Windows host | turn bundles into a report, transcribe narration |

The capture rig is X11-only, so it installs on Kali. Windows is optional and only for the
reporting/compile phase.

## Install (Kali)

Run as your **normal user** (not sudo — it configures your session; it calls sudo itself
only for apt):

```bash
cd Cybersecurity
./reporting/install-kali.sh
```

This:
1. installs missing packages (`maim imagemagick xdotool xinput x11-utils ffmpeg moreutils sxhkd flameshot tmux libnotify-bin`),
2. copies the rig to `~/docrig`,
3. adds marker-guarded blocks to `~/.zshrc`, `~/.tmux.conf`, `~/.config/sxhkd/sxhkdrc` (re-runnable, no duplication),
4. autostarts the two daemons via `~/.config/autostart/`,
5. starts everything now so you can test immediately.

Change the hotkey or locations:

```bash
HOTKEY="super + shift + r" ./reporting/install-kali.sh     # different key / macropad / footswitch
# or edit reporting/docrig/config.sh for RING_INTERVAL, RING_WINDOW, SHOT_FMT, paths — then re-run
```

Activate in already-open sessions: `source ~/.zshrc` and `tmux source-file ~/.tmux.conf`.

## Usage

- **Smash the button** (`super + shift + space` by default) → the last 5 min is frozen into
  `~/oscp-evidence/<timestamp>/` and narration recording **starts**. Now rant into your mic
  about why the writable SMB share and the high-port IIS connect.
- **Smash it again** → narration **stops** and saves.
- **`Print`** → a deliberate high-quality Flameshot screenshot for report proof (proof.txt etc.).

Each bundle:

```
~/oscp-evidence/20260716-143205/
├── frames/              # ~150 stills = last 5 min of screen
├── events.log          # GUI focus changes + mouse clicks
├── commands-local.log  # timestamped LOCAL shell commands
├── consoles/           # per-tmux-pane transcripts incl. ssh/tunnelled
└── narration.opus      # your voice-note
```

## Install (Windows, optional)

Only for the next-day compile phase (never capture):

```powershell
powershell -ExecutionPolicy Bypass -File .\reporting\install-windows.ps1
```

Installs `ffmpeg`, `pandoc`, `python` via winget. PDF export additionally needs a LaTeX
engine (TinyTeX/MiKTeX). For zero-AI transcription, use `whisper.cpp` locally.

## Two caveats

- **SSH / tunnelled commands:** the zsh hook only sees *local* commands; the **tmux
  pane-logging** is what captures remote/pivoted sessions. Both are installed — don't rely
  on the shell hook alone.
- **Transcription is the only AI-exposed step.** Everything else is deterministic. Type up
  `narration.opus` yourself, or use local on-device STT — never a cloud/LLM (banned during
  the exam *and* the reporting phase).

## Uninstall

```bash
./reporting/uninstall-kali.sh      # removes the rig + config blocks; keeps ~/oscp-evidence
```

## TODO

- [ ] `compile.sh` — walk each bundle into a Markdown report section (frames embedded,
      commands in code blocks, placeholder for transcribed narration).
- [ ] Pick the report backend: **SysReptor** (self-hosted, OSCP template) vs
      **Pandoc → OffSec Markdown template → PDF**. Both zero-AI.
- [ ] Test end-to-end on the live Kali VM (verify pane logs appear, timestamp slicing lines up).
