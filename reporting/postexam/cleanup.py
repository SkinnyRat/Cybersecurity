#!/usr/bin/env python3
"""
Post-exam cleanup for docrig evidence bundles.

Fixes the two kinds of noise in the raw logs:
  1. commands-local.log -> tab-separated fields (real tabs OR the old literal '\\t')
                           reflowed into readable, aligned columns.
  2. consoles/*.log      -> strip ANSI colour/cursor codes + terminal mode sets, and
                           resolve carriage-return / backspace overwrites, leaving plain text.

Non-destructive by default: writes '<name>.clean.txt' next to each original; the raw
evidence is never modified. Use --inplace to overwrite (a '<name>.raw' backup is kept).

Note: commands-local.log is the AUTHORITATIVE record of what you typed. The consoles/
cleaner recovers command *output* well, but interactive command-entry lines can still
carry zsh-autosuggestion redraw residue (the shell literally redraws them per keystroke).

Usage:
  cleanup.py                 # clean every bundle under ~/oscp-evidence
  cleanup.py PATH [PATH...]  # an evidence root, a single bundle dir, or a log file
  cleanup.py --inplace PATH  # overwrite originals (keeps a .raw backup)
  cleanup.py --strip-ts PATH # also drop the per-line ISO timestamps in consoles/
"""
import argparse
import re
import sys
from pathlib import Path

# --- escape / control sequence stripping ------------------------------------
_ESC = re.compile(
    r'\x1b\[[0-?]*[ -/]*[@-~]'              # CSI:  ESC [ params interm final
    r'|\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)'   # OSC:  ESC ] ... (BEL | ST)
    r'|\x1b[@-Z\\-_]'                       # other C1 escapes
    r'|\x1b[=>]'                            # keypad application/normal mode
    r'|\x1b[()#][0-9A-Za-z]'               # charset / line-size selectors
)
# leftover control bytes to drop (keeps \t, \n; handles \r,\b before this)
_CTRL = re.compile(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]')
# the per-line timestamp `ts` prepends: e.g. "2026-07-29T20:31:39  " (trailing ws may be
# stripped by the time we test, so \s* not \s+)
_TS = re.compile(r'^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\s*')


def resolve_line(line: str) -> str:
    """Apply carriage-return overwrite and backspace within one physical line."""
    buf, col = [], 0
    for ch in line:
        if ch == '\r':
            col = 0
        elif ch == '\b':
            col = max(0, col - 1)
        else:
            if col < len(buf):
                buf[col] = ch
            else:
                buf.append(ch)
            col += 1
    return ''.join(buf)


def clean_console_text(raw: str, strip_ts: bool = False) -> str:
    text = _ESC.sub('', raw)
    out = []
    for line in text.split('\n'):
        line = _CTRL.sub('', resolve_line(line)).rstrip()
        m = _TS.match(line)
        if m and not line[m.end():].strip():
            out.append('')                  # timestamp-only line -> blank (collapsed below)
            continue
        if strip_ts and m:
            line = line[m.end():]
        out.append(line)
    # collapse runs of blank lines, trim leading/trailing blanks
    collapsed, blank = [], False
    for l in out:
        if not l.strip():
            if blank:
                continue
            blank = True
        else:
            blank = False
        collapsed.append(l)
    while collapsed and not collapsed[0].strip():
        collapsed.pop(0)
    while collapsed and not collapsed[-1].strip():
        collapsed.pop()
    return '\n'.join(collapsed) + '\n'


def clean_commands_text(raw: str) -> str:
    home = str(Path.home())
    out = []
    for line in raw.splitlines():
        if not line.strip():
            continue
        sep = '\t' if '\t' in line else ('\\t' if '\\t' in line else None)
        if sep is None:
            out.append(line)
            continue
        parts = line.split(sep, 2)
        ts = parts[0].replace('T', ' ').split('.')[0]        # -> "2026-07-29 20:27:51"
        cwd = parts[1] if len(parts) > 1 else ''
        cmd = parts[2] if len(parts) > 2 else ''
        if cwd.startswith(home):
            cwd = '~' + cwd[len(home):]
        out.append(f"{ts}  {cwd:<26} $ {cmd}")
    return '\n'.join(out) + '\n'


def clean_file(f: Path, inplace: bool, strip_ts: bool) -> None:
    raw = f.read_text(encoding='utf-8', errors='replace')
    if f.name == 'commands-local.log':
        cleaned = clean_commands_text(raw)
    else:
        cleaned = clean_console_text(raw, strip_ts)

    if inplace:
        backup = f.with_name(f.name + '.raw')
        if not backup.exists():
            backup.write_text(raw, encoding='utf-8')
        dest = f
    else:
        dest = f.with_suffix('.clean.txt')
    dest.write_text(cleaned, encoding='utf-8')
    print(f"  {f}  ->  {dest.name}")


def iter_targets(paths):
    for raw in paths:
        p = Path(raw).expanduser()
        if p.is_file():
            yield p
        elif p.is_dir():
            for f in sorted(p.rglob('*.log')):
                if f.name == 'commands-local.log' or f.parent.name == 'consoles':
                    yield f
        else:
            print(f"skip (not found): {p}", file=sys.stderr)


def main():
    ap = argparse.ArgumentParser(description="Clean docrig evidence logs.")
    ap.add_argument('paths', nargs='*', help="evidence root / bundle dir / log file "
                                             "(default: ~/oscp-evidence)")
    ap.add_argument('--inplace', action='store_true',
                    help="overwrite originals (keeps a .raw backup)")
    ap.add_argument('--strip-ts', action='store_true',
                    help="also drop per-line timestamps in consoles/")
    args = ap.parse_args()

    paths = args.paths or [str(Path.home() / 'oscp-evidence')]
    n = 0
    for f in iter_targets(paths):
        clean_file(f, args.inplace, args.strip_ts)
        n += 1
    print(f"cleaned {n} file(s).")
    if n == 0:
        print("nothing found — pass a bundle dir or a log file explicitly.", file=sys.stderr)


if __name__ == '__main__':
    main()
