# Section 20: ACL Enumeration

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1485
- Code/command blocks: 11

> Terminal output is omitted; only commands & scripts are captured.

## What to hunt for in the results

Each ACE has three fields to scan: **`SecurityIdentifier`** (who holds the right — you want **you** or **a group you're in**), **`ActiveDirectoryRights`** + **`ObjectAceType`** (the right itself — the juicy part), and **`ObjectDN`** (the target — you want something **more privileged** than you).

| Right (ActiveDirectoryRights / ObjectAceType) | Over a… | What you do | See |
|---|---|---|---|
| **GenericAll** | anything | Full control — jackpot. User→reset pw or set SPN; Group→add member; Computer→RBCD/LAPS | [21](21-acl-abuse-tactics.md) |
| **GenericWrite / WriteProperty** | user | Set an **SPN** → **targeted Kerberoast**; or set logon script | [21](21-acl-abuse-tactics.md) |
| **WriteDACL** | object / **domain** | Rewrite the ACL → grant yourself GenericAll, or **DCSync on the domain** | [22](22-dcsync.md) |
| **WriteOwner** | anything | Make yourself owner → then WriteDACL → GenericAll | [21](21-acl-abuse-tactics.md) |
| **User-Force-Change-Password** (`00299570-…`) | user | **Reset their password** without the current one | [21](21-acl-abuse-tactics.md) |
| **AllExtendedRights** | user / domain | Includes force-change-password (user) **and** DCSync (domain) | [22](22-dcsync.md) |
| **Self / AddMember (WriteProperty `member`)** | group | **Add yourself to the group** | [21](21-acl-abuse-tactics.md) |
| **DS-Replication-Get-Changes(-All)** (`1131f6aa/ad-…`) | **domain** | **DCSync** → dump all hashes | [22](22-dcsync.md) |
| **ReadLAPSPassword / ReadGMSAPassword** | computer / gMSA | Read the local-admin / service-account password in cleartext | — |

**Mindset — hunt a chain, not one ACE.** The win is a *path*: a principal you control has an abusable right over a slightly-more-privileged principal, who has a right over the next, up to DA. That's what the `Convert-NameToSid` + `Get-DomainObjectACL` hops below walk through. **BloodHound automates exactly this** ("shortest path to Domain Admins"); manual PowerView is the fallback.

**Ignore the noise.** `SYSTEM`, `Domain Admins`, `Enterprise Admins`, `Administrators`, and `SELF` holding rights is normal baseline. Hunt **non-default principals** (regular users / non-privileged groups) holding powerful rights. `Find-InterestingDomainAcl` pre-filters most built-in noise — it's the quick first pass.

```powershell
Find-InterestingDomainAcl
```

```powershell
Import-Module .\PowerView.ps1
$sid = Convert-NameToSid {{USERNAME}}
```

```powershell
Get-DomainObjectACL -Identity * | ? {$_.SecurityIdentifier -eq $sid}
```

```powershell
# 00299570-... = User-Force-Change-Password extended right (universal AD constant)
$guid= "00299570-246d-11d0-a768-00aa006e0529"
Get-ADObject -SearchBase "CN=Extended-Rights,$((Get-ADRootDSE).ConfigurationNamingContext)" -Filter {ObjectClass -like 'ControlAccessRight'} -Properties * |Select Name,DisplayName,DistinguishedName,rightsGuid| ?{$_.rightsGuid -eq $guid} | fl
```

```powershell
Get-DomainObjectACL -ResolveGUIDs -Identity * | ? {$_.SecurityIdentifier -eq $sid} 
```

```powershell
Get-ADUser -Filter * | Select-Object -ExpandProperty SamAccountName > ad_users.txt
```

```powershell
foreach($line in [System.IO.File]::ReadLines("C:\ad_users.txt")) {get-acl  "AD:\$(Get-ADUser $line)" | Select-Object Path -ExpandProperty Access | Where-Object {$_.IdentityReference -match '{{DOMAIN_NB}}\\{{USERNAME}}'}}
```

```powershell
$sid2 = Convert-NameToSid {{NEXT_USER}}
Get-DomainObjectACL -ResolveGUIDs -Identity * | ? {$_.SecurityIdentifier -eq $sid2} -Verbose
```

```powershell
Get-DomainGroup -Identity "{{GROUP_NAME}}" | select memberof
```

```powershell
$groupsid = Convert-NameToSid "{{GROUP_NAME}}"
Get-DomainObjectACL -ResolveGUIDs -Identity * | ? {$_.SecurityIdentifier -eq $groupsid} -Verbose
```

```powershell
$nextuserid = Convert-NameToSid {{NEXT_USER}} 
Get-DomainObjectACL -ResolveGUIDs -Identity * | ? {$_.SecurityIdentifier -eq $nextuserid} -Verbose
```
