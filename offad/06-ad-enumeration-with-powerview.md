# 22.2.4 — AD Enumeration with PowerView

- Module: PEN-200 · 22. Active Directory Introduction and Enumeration
- Source: portal.offsec.com · module `active-directory-introduction-and-enumeration-45847` (§22.2.4)
- Code blocks: 7

> PowerView is a pre-built PowerShell script that wraps the same .NET/LDAP calls we wrote by hand,
> with far more functions. On CLIENT75 it's in `C:\Tools`. Output omitted.

## Import

```powershell
Import-Module .\PowerView.ps1
```

## Domain / user / group basics

```powershell
Get-NetDomain
```

```powershell
Get-NetUser
Get-NetUser | select cn
Get-NetUser | select cn,pwdlastset,lastlogon
```

> `pwdlastset` + `lastlogon` surface **dormant accounts** (quieter to take over) and accounts
> whose password predates a policy change (likely weaker → better spray/brute targets).

```powershell
Get-NetGroup | select cn
```

```powershell
Get-NetGroup "{{GROUP_NAME}}" | select member
```

> Pipe into `select` to pick only the attributes you care about — much cleaner than the raw
> loop-based script from §22.2.3. PowerView also enumerates domain-local groups that `net.exe`
> misses. Full function list: see the PowerView reference.
