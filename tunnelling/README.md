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

## 1 · Enumerate the pivot before you tunnel

The moment you get a shell on a dual-homed host, map what it can see — that defines every tunnel.

```bash
ip addr; ip route            # second interface / extra subnet = your pivot path
ss -ntplu                    # local-only services now reachable via a forward
for i in $(seq 1 254); do nc -zv -w1 <NEWNET>.$i 445; done   # sweep the new subnet
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
