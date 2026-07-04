# Section 32: Hardening Active Directory

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1277
- Code/command blocks: 1

> Terminal output is omitted; only commands & scripts are captured.

## 1. `powershell` _(output omitted)_

```powershell
Get-ADGroup -Identity "Protected Users" -Properties Name,Description,Members
```

