# 22.2.2 — Enumerating AD with PowerShell & .NET Classes

- Module: PEN-200 · 22. Active Directory Introduction and Enumeration
- Source: portal.offsec.com · module `active-directory-introduction-and-enumeration-45847` (§22.2.2)
- Code blocks: 4

> Goal: a **dependency-free** LDAP enumerator that needs only basic privileges (no RSAT, no admin).
> RSAT cmdlets like `Get-ADUser` are only on DCs by default. We build our own with .NET + ADSI.

## LDAP path theory

```
LDAP://HostName[:PortNumber][/DistinguishedName]
```

- **HostName** — best to target the **PDC** (Primary Domain Controller), the DC holding the most
  up-to-date info (the `PdcRoleOwner`). There is only one PDC per domain.
- **PortNumber** — optional; auto-selected by SSL/non-SSL. Only set it for non-default ports.
- **DistinguishedName (DN)** — uniquely identifies an object, e.g. `CN=Stephanie,CN=Users,DC=corp,DC=com`.
  Read **right → left**. `CN` = Common Name; `DC` = **Domain Component** (here, not "Domain
  Controller"). For our LDAP path we want the domain DN only: `DC=corp,DC=com`.

## Bypass execution policy first

```powershell
powershell -ep bypass
```

## Get the domain object / find the PDC

```powershell
[System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
```

> The `PdcRoleOwner` property in the output is the PDC hostname (e.g. `DC1.corp.com`).

## Build the full LDAP path dynamically (`enumeration.ps1`)

```powershell
# Grab the PDC name and the domain DN, then assemble LDAP://PDC/DN
$PDC  = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().PdcRoleOwner.Name
$DN   = ([adsi]'').distinguishedName
$LDAP = "LDAP://$PDC/$DN"
$LDAP
```

> `([adsi]'')` (two single quotes = start at the top of the AD hierarchy) returns the domain DN
> already formatted for LDAP (`DC=corp,DC=com`) — no manual string-splitting of `corp.com` needed.
> The script is fully dynamic, so it's reusable against any domain in a real engagement.
