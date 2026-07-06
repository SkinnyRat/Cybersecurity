# Scanning & Enumeration — Information Gathering

- Module: PEN-200 / Module 6 — Information Gathering (OSCP)
- URL: https://portal.offsec.com/courses/pen-200-44065/learning/information-gathering-44134
- Code/command blocks: 31

> Terminal output is omitted; only commands & scripts are captured.
> Placeholders: `{{DOMAIN}}` target domain, `{{TARGET_IP}}` a single host, `{{SUBNET}}` full CIDR (e.g. `192.168.50.0/24`), `{{NETWORK}}` 3-octet prefix (e.g. `192.168.50`).

---

# 6.2 — Passive Information Gathering

> Passive = no packets touch the target directly; a third party (search engine, WHOIS server, Netcraft, Shodan) does the interacting. OSINT first, then go active.

## 6.2.1 Whois enumeration

> Forward lookup (domain → registrar/nameservers/contacts) and reverse lookup (IP → owning org). `-h` points WHOIS at a specific server — in the PWK lab that relay is `192.168.50.251`; on the real internet you normally omit `-h`.

```bash
whois {{DOMAIN}} -h 192.168.50.251
```

Reverse — WHOIS an IP:

```bash
whois 38.100.193.70 -h 192.168.50.251
```

## 6.2.2 Google hacking (dorks)

> Search operators refine results down to exposed files, directories and tech stacks. Operators work across most engines. Prefix `-` excludes.

```text
site:{{DOMAIN}}                         # limit search to one domain + subdomains
ext:php                                 # find pages by extension (also ext:xml, ext:py)
site:{{DOMAIN}} -filetype:html          # exclude HTML to surface interesting non-HTML pages
intitle:"index of" "parent directory"  # find open directory listings
```

> Also check `{{DOMAIN}}/robots.txt` — `Allow`/`Disallow` entries can leak hidden paths (e.g. `/nanites.php`) that were never meant to be found.

## 6.2.3 Netcraft

> Web portal — no CLI. Passive: Netcraft interacts with the target, not you.
> - DNS search: `https://searchdns.netcraft.com/` → enumerate `*.{{DOMAIN}}` subdomains and shared netblocks.
> - Site report: per-host tech stack + hosting history.

## 6.2.4 Open-source code

> Search public code repos for leaked creds, tech stack, internal hostnames. These platforms support the same Google-style operators.
> - GitHub · GitHub Gist · GitLab · SourceForge

## 6.2.5 Shodan

> Search engine for internet-connected devices (servers, routers, IoT) — indexes banners/services, not web content. Free account needed. Still passive: Shodan did the scanning, not you.

```text
hostname:{{DOMAIN}}     # IPs, open services and banners for the domain's footprint
```

## 6.2.6 Security headers and SSL/TLS

> Third-party scanners that blur passive/active (the site, not you, initiates the check).
> - Security Headers — `https://securityheaders.com/` → flags missing `Content-Security-Policy`, `X-Frame-Options`, etc.
> - Qualys SSL Labs — `https://www.ssllabs.com/ssltest/` → TLS config, weak ciphers/protocols.

---

# 6.3 — LLM-powered passive information gathering

> Awareness only (not on the OSCP exam). Feed collected OSINT to an LLM to summarise a target's footprint, infer org structure, and draft candidate subdomain/username wordlists. Always verify — LLMs hallucinate hosts.

---

# 6.4 — Active Information Gathering

> Active = you send packets to the target. Louder, but far richer: live hosts, open ports, service versions, shares, users.

## 6.4.1 DNS enumeration

> Query record types, then brute-force subdomains and reverse-sweep netblocks. NS/MX/TXT records map the mail + name infrastructure.

```bash
host www.{{DOMAIN}}                 # A record
host -t mx {{DOMAIN}}               # mail servers
host -t txt {{DOMAIN}}              # SPF/verification strings
host idontexist.{{DOMAIN}}          # NXDOMAIN => name not found (compare vs valid)
```

Forward brute-force from a wordlist:

```bash
for ip in $(cat list.txt); do host $ip.{{DOMAIN}}; done
```

Reverse sweep across a discovered netblock (filter the misses):

```bash
for ip in $(seq 64 79); do host 167.114.21.$ip; done | grep -Ev "not found|timed out"
```

Automated tooling:

```bash
dnsrecon -d {{DOMAIN}} -t std          # standard enum (SOA/NS/MX/A/TXT)
dnsrecon -d {{DOMAIN}} -D ~/list.txt -t brt   # brute-force subdomains
dnsenum {{DOMAIN}}
```

From Windows (querying an internal AD DNS server directly):

```cmd
nslookup mail.megacorptwo.com
nslookup -type=TXT info.megacorptwo.com 192.168.50.151
```

> RDP into a Windows lab host to run the above:
```bash
xfreerdp /u:student /p:lab /v:{{TARGET_IP}}
```

## 6.4.2 TCP/UDP port scanning theory (netcat)

> Netcat as a crude scanner when nmap isn't available. `-z` zero-I/O (just check), `-w 1` 1s timeout, `-u` UDP.

```bash
nc -nvv -w 1 -z {{TARGET_IP}} 3388-3390        # TCP port range
nc -nv -u -z -w 1 {{TARGET_IP}} 120-123        # UDP port range
```

## 6.4.3 Port scanning with Nmap

> The workhorse. Below: measuring scan cost, scan types, host discovery / sweeps, service+OS detection, and NSE.

Measure how noisy a scan is (iptables byte accounting):

```bash
sudo iptables -I INPUT 1 -s {{TARGET_IP}} -j ACCEPT
sudo iptables -I OUTPUT 1 -d {{TARGET_IP}} -j ACCEPT
sudo iptables -Z                               # zero counters, then scan, then re-check
sudo iptables -vn -L                           # read bytes in/out
```

Basic + full-range scan:

```bash
nmap {{TARGET_IP}}                             # default top-1000 TCP
nmap -p 1-65535 {{TARGET_IP}}                  # all TCP ports
```

Scan types:

```bash
sudo nmap -sS {{TARGET_IP}}                    # SYN / stealth (default as root)
nmap -sT {{TARGET_IP}}                         # full TCP connect (no root)
sudo nmap -sU {{TARGET_IP}}                    # UDP
sudo nmap -sU -sS {{TARGET_IP}}                # UDP + TCP SYN together
```

Host discovery + network sweeps (`-oG` = greppable output):

```bash
nmap -sn {{NETWORK}}.1-253                     # ping sweep, no port scan
nmap -v -sn {{NETWORK}}.1-253 -oG ping-sweep.txt
grep Up ping-sweep.txt | cut -d " " -f 2       # extract live hosts
```

```bash
nmap -p 80 {{NETWORK}}.1-253 -oG web-sweep.txt # who has 80 open
grep open web-sweep.txt | cut -d" " -f2
```

```bash
nmap -sT -A --top-ports=20 {{NETWORK}}.1-253 -oG top-port-sweep.txt
cat /usr/share/nmap/nmap-services              # port->service DB nmap ranks from
```

Service / OS fingerprinting:

```bash
sudo nmap -O {{TARGET_IP}} --osscan-guess      # OS detection
nmap -sT -A {{TARGET_IP}}                       # version + default scripts + traceroute
```

Nmap Scripting Engine (NSE):

```bash
nmap --script http-headers {{TARGET_IP}}
nmap --script-help http-headers                # what a script does before you run it
```

From Windows without nmap:

```powershell
Test-NetConnection -Port 445 {{TARGET_IP}}     # single-port check
1..1024 | % {echo ((New-Object Net.Sockets.TcpClient).Connect("{{TARGET_IP}}", $_)) "TCP port $_ is open"} 2>$null
```

## 6.4.4 SMB enumeration

> Ports 139/445. Find hosts, resolve NetBIOS names, then NSE scripts for OS/share detail.

```bash
nmap -v -p 139,445 -oG smb.txt {{NETWORK}}.1-254
cat smb.txt
```

```bash
sudo nbtscan -r {{SUBNET}}                      # NetBIOS name sweep
```

```bash
ls -1 /usr/share/nmap/scripts/smb*              # available SMB NSE scripts
nmap -v -p 139,445 --script smb-os-discovery {{TARGET_IP}}
```

From Windows:

```cmd
net view \\dc01 /all                            # list shares on a host
```

## 6.4.5 SMTP enumeration

> Port 25. Abuse `VRFY` to validate usernames. Banner grab first, then verify users.

```bash
nc -nv {{TARGET_IP}} 25                          # banner grab; try VRFY <user>
```

Python VRFY user-enumeration script:

```python
#!/usr/bin/python
import socket
import sys

if len(sys.argv) != 3:
        print("Usage: vrfy.py <username> <target_ip>")
        sys.exit(0)

# Create a Socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Connect to the Server
ip = sys.argv[2]
connect = s.connect((ip,25))

# Receive the banner
banner = s.recv(1024)
print(banner)

# VRFY a user
user = (sys.argv[1]).encode()
s.send(b'VRFY ' + user + b'\r\n')
result = s.recv(1024)
print(result)

# Close the socket
s.close()
```

```bash
python3 smtp.py root {{TARGET_IP}}
python3 smtp.py johndoe {{TARGET_IP}}
```

From Windows:

```powershell
Test-NetConnection -Port 25 {{TARGET_IP}}
dism /online /Enable-Feature /FeatureName:TelnetClient   # enable telnet client
telnet {{TARGET_IP}} 25
```

## 6.4.6 SNMP enumeration

> UDP 161. Weak community strings (`public`/`private`) leak users, processes, installed software, open ports. Sweep → brute community strings → walk the MIB.

```bash
sudo nmap -sU --open -p 161 {{NETWORK}}.1-254 -oG open-snmp.txt
```

Brute-force community strings with onesixtyone:

```bash
echo public > community
echo private >> community
echo manager >> community
for ip in $(seq 1 254); do echo {{NETWORK}}.$ip; done > ips
onesixtyone -c community -i ips
```

Walk the MIB tree (`-c` community, `-v1` version 1):

```bash
snmpwalk -c public -v1 -t 10 {{TARGET_IP}}                              # full walk (10s timeout)
snmpwalk -c public -v1 {{TARGET_IP}} 1.3.6.1.4.1.77.1.2.25             # Windows users
snmpwalk -c public -v1 {{TARGET_IP}} 1.3.6.1.2.1.25.4.2.1.2           # running processes
snmpwalk -c public -v1 {{TARGET_IP}} 1.3.6.1.2.1.25.6.3.1.2           # installed software
snmpwalk -c public -v1 {{TARGET_IP}} 1.3.6.1.2.1.6.13.1.3             # open TCP ports
```

---

# 6.5 — LLM-powered active information gathering

> Awareness only (not on the OSCP exam). Use an LLM to generate targeted subdomain/username wordlists (e.g. "produce 1000 unique lowercase subdomain candidates for {{DOMAIN}}") and to parse/summarise raw nmap/enum output. Validate everything against real scans.

---

# 6.6 — Wrapping up

> Workflow: passive OSINT (WHOIS, dorks, Netcraft, Shodan, code repos) → active DNS + port scanning (nmap/nc) → per-service enumeration (SMB, SMTP, SNMP). Feed everything into the next phase: vulnerability scanning and initial foothold.
