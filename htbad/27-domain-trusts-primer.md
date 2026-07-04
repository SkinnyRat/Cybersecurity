# Section 27: Domain Trusts Primer

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1488
- Code/command blocks: 7

> Terminal output is omitted; only commands & scripts are captured.

## 1. `powershell` _(output omitted)_

```powershell
Import-Module activedirectory
Get-ADTrust -Filter *
```

## 2. `powershell` _(output omitted)_

```powershell
Get-DomainTrust 
```

## 3. `powershell` _(output omitted)_

```powershell
Get-DomainTrustMapping
```

## 4. `powershell` _(output omitted)_

```powershell
Get-DomainUser -Domain LOGISTICS.INLANEFREIGHT.LOCAL | select SamAccountName
```

## 5. `cmd` _(output omitted)_

```cmd
netdom query /domain:inlanefreight.local trust
```

## 6. `cmd` _(output omitted)_

```cmd
netdom query /domain:inlanefreight.local dc
```

## 7. `cmd` _(output omitted)_

```cmd
netdom query /domain:inlanefreight.local workstation
```

