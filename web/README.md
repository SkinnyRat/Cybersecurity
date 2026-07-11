# Web Application Attacks

Playbook for the **web** side of the OSCP standalone track — enumerating an app, then exploiting the common
vulnerability classes to reach a foothold. Covers PEN-200 **Modules 8, 9, 10**. Notes template with
**BoxHelper.html** (`{{TARGET_IP}}`, `{{URL}}`, `{{LHOST}}`, `{{LPORT}}`, `{{USERNAME}}`, `{{PASSWORD}}`,
`{{WORDLIST}}`).

| Note | Covers | OffSec source |
|---|---|---|
| [enumeration.md](enumeration.md) | Assessment methodology, tooling (Nmap/whatweb, Gobuster/ffuf, **Burp**), source/header/sitemap inspection, **API enumeration & abuse** | Module 8 §8.1–8.3, 8.5 |
| [directories_files.md](directories_files.md) | **Directory traversal**, **file inclusion** (LFI+log-poisoning / PHP wrappers / RFI), **file upload**, **command injection** — plus PortSwigger bypass cheats | Module 9 §9.1–9.5 |
| [attacks.md](attacks.md) | **SQL injection** (error / UNION / blind, manual RCE) and **XSS** (stored/reflected/DOM, privesc) — plus PortSwigger cheat sheets | Module 10 (all) + Module 8 §8.4 |

> XSS lives in `attacks.md` (with SQLi), **not** in the enumeration note — both are injection attacks. Enumeration
> is everything *up to* finding the bug; the other two notes are the exploitation.

---

## The web loop — from a URL to a shell

1. **Fingerprint** the server + stack — `nmap -sV --script=http-enum`, `whatweb`, response headers. *(enumeration.md §8.2–8.3)*
2. **Map** content — `gobuster`/`ffuf` for dirs, files, vhosts, params; proxy everything through **Burp**; read source, `robots.txt`, sitemaps; enumerate APIs. *(enumeration.md)*
3. **Classify the bug** by what the input touches:
   - a **file path** rendered back → directory traversal *(read)*
   - a **file path** included/executed → LFI/RFI *(→ RCE)*
   - a **filename/upload** → file upload *(webshell / overwrite `authorized_keys`)*
   - input into an **OS command** → command injection
   - input into a **SQL query** → SQL injection
   - input reflected into **HTML/JS** → XSS
4. **Exploit** with the matching payload set. *(directories_files.md / attacks.md)*
5. **Upgrade** — webshell → reverse shell → stabilise → re-enumerate, and feed any looted creds/keys/hashes back
   into `../exploits` (cracking, reuse) and `../scanning` (new services).

---

## Exam notes (OSCP)

- **Burp Suite Community** is allowed (manual Proxy/Repeater/Intruder; Intruder is rate-limited — fine for small keyspaces).
- **`sqlmap` is banned** (automatic-exploitation tool). Use it in the labs to save time, but **know the manual SQLi
  method cold** for the exam (attacks.md §10.2). `sqlninja` is likewise banned. See [[oscp-exam-banned-tools]].
- No automated web vulnerability scanners (Nessus/OpenVAS/Nikto's active exploitation, etc.). `gobuster`/`ffuf`/`whatweb`/
  Nmap NSE are fine — they enumerate, they don't auto-exploit.
- Everything here is **manual and repeatable** by design; that's exactly what the exam rewards.

---

## Quick reference

```bash
# enumerate
whatweb {{URL}}; curl -I {{URL}}; curl -s {{URL}}/robots.txt
gobuster dir -u {{URL}} -w {{WORDLIST}} -x php,txt,html -o gobuster.txt
ffuf -w {{WORDLIST}} -u {{URL}}/FUZZ -e .php,.txt -fc 404

# traversal / LFI test
curl "{{URL}}/index.php?page=../../../../../../../../etc/passwd"
curl "{{URL}}/index.php?page=php://filter/convert.base64-encode/resource=index.php"

# upload webshell then run it (extension bypass)
curl "{{URL}}/uploads/shell.pHP?cmd=id"

# command injection (URL-encoded separator)
curl -X POST --data 'param=git%3Bwhoami' {{URL}}/endpoint

# SQLi (manual) — confirm, bypass, dump
'                                    # error => injectable
' UNION SELECT null,username,password,null,null FROM users -- //

# reverse shell catcher
nc -nvlp {{LPORT}}
```

> Document as you go: the vulnerable **parameter**, the exact **payload** that worked, and the resulting access.
> Web bugs are the classic external foothold and a common internal lateral-movement vector.
