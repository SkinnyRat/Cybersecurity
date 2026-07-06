# Scanning & Enumeration

Enumeration playbook for standalone boxes. Notes here template with **BoxHelper.html**
(`{{TARGET_IP}}`, `{{DOMAIN}}`, `{{URL}}`, `{{SUBNET}}`, `{{NETWORK}}`, `{{WORDLIST}}`, …).

- [scanning.md](scanning.md) — PEN-200 Module 6 (Information Gathering): passive OSINT + active DNS/port/SMB/SMTP/SNMP enumeration — and Module 7 (Vulnerability Scanning): Nessus + Nmap NSE `vuln` scripts.

> **The one rule:** enumeration is a *loop*, not a checklist. Every fact you discover
> (a hostname, a version, a credential, a share, a new subnet) gets fed back in and you
> re-enumerate from the new vantage point. Most missed boxes are missed enumeration,
> not missed exploits.

---

## 1 · Always run first — every box, no exceptions

Kick off the **full TCP scan immediately**, then work the fast results while it finishes.
Do **not** tunnel-vision on port 80 before you know the whole port picture.

```bash
# fast top-ports for quick wins (start working these right away)
nmap -sC -sV --top-ports 1000 -oN nmap-top.txt {{TARGET_IP}}
```

```bash
# full TCP — the non-negotiable one; run it on EVERY box
nmap -p- --min-rate 2000 -oN nmap-allports.txt {{TARGET_IP}}
```

```bash
# then -sC -sV ONLY against the ports -p- actually found
nmap -sC -sV -p <comma,sep,ports> -oN nmap-services.txt {{TARGET_IP}}
```

```bash
# UDP top-ports — easy to forget, but SNMP(161)/TFTP(69)/SNMP often live here only
sudo nmap -sU --top-ports 50 -oN nmap-udp.txt {{TARGET_IP}}
```

> Why always: a service on port 61337 or a UDP-only SNMP daemon is invisible to a default
> scan, and that is exactly where the intended path often hides.

---

## 2 · Cycle / repeat as you learn more

Each discovery unlocks a follow-up scan. Loop until nothing new appears.

| You discover… | …so you re-run |
|---|---|
| A **hostname / domain** (TLS cert, HTTP redirect, SMB, LDAP) | Add to `/etc/hosts` → vhost/subdomain fuzz → re-run web scans against the name, not the IP |
| A **web app / tech stack** | `whatweb`, then content discovery; recurse into any dir you find; re-run with `-x` for the extensions in use |
| **Credentials** (any user:pass) | Re-run **authenticated** enum everywhere — SMB shares, web logins, DB, SNMP, WinRM |
| An **SMB null/guest session** | Enumerate shares, users, policies; pull readable files |
| An **SNMP community string** | `snmpwalk` more OIDs — users, processes, software, listening ports |
| **Usernames** (web, SMTP VRFY, SNMP) | Build a `{{USERLIST}}` → spray / brute the exposed login |
| A **foothold / shell** | Re-enumerate from inside: local ports (`ss -tlnp`), new subnets → sweep `{{NETWORK}}.1-254` / `{{SUBNET}}` |
| A **service + version** | `searchsploit` it, and run the Nmap NSE `vuln` category against the port (Nessus is exam-banned — NSE is the allowed automated check; see scanning.md §7.3) |

```bash
# targeted NSE once you know the service (examples)
nmap -p 445 --script "smb-os-discovery,smb-enum-shares,smb-enum-users" {{TARGET_IP}}
nmap -p 80,443 --script "http-title,http-headers,http-enum" {{TARGET_IP}}
sudo nmap -sV -p <found-ports> --script "vuln" {{TARGET_IP}}   # known-CVE checks
```

```bash
# web content discovery deepens with each finding
gobuster dir -u {{URL}} -w {{WORDLIST}} -x php,txt,html -o gobuster.txt
ffuf -u http://{{TARGET_IP}} -H "Host: FUZZ.{{DOMAIN}}" -w {{WORDLIST}} -fs 0   # vhosts
```

---

## 3 · What to pay attention to in the results

Read output like a lead-hunter, not a scanner. Signal to flag:

- **Every open port → a service → a known path.** Map each one. Unusual/high ports first — they're deliberate.
- **Exact version strings.** `searchsploit <product version>` on anything with a version. Note the version even if no exploit yet.
- **Hostnames & domains** anywhere (certs, redirects, SMB, LDAP, page source). Add to `/etc/hosts` — this unlocks vhosts and is a classic gate.
- **SMB:** null-session or guest-readable shares, and `smb-os-discovery` output (OS build, domain, hostname).
- **Web:** page title + `whatweb` stack, `robots.txt`, **directory indexing** (`Index of /`), login forms (try default creds), CMS name **and version**, verbose error messages / stack traces (leak paths, frameworks).
- **DNS:** zone transfer (`AXFR`), `TXT`/`SPF` (mail infra & third parties), brute-forced subdomains.
- **SNMP:** treat a readable community string as a jackpot — users, running processes, installed software, and listening TCP ports (internal recon for free).
- **Anything that names a user** → into `{{USERLIST}}`. Anything that names a path/file → try to reach it.
- **UDP hits** — don't ignore them just because TCP was "more interesting."

> Document as you go: keep a running ports/services/creds table (the BoxHelper template
> has one). If you can't answer "what have I *not* enumerated yet?", you're not done.

