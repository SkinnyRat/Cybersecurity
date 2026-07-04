# Section 27: Domain Trusts Primer

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1488
- Code/command blocks: 7

> Terminal output is omitted; only commands & scripts are captured.

```powershell
Import-Module activedirectory
Get-ADTrust -Filter *
```

```powershell
Get-DomainTrust 
```

```powershell
Get-DomainTrustMapping
```

```powershell
Get-DomainUser -Domain LOGISTICS.{{DOMAIN_UPPER}} | select SamAccountName
```

```cmd
netdom query /domain:{{DOMAIN}} trust
```

```cmd
netdom query /domain:{{DOMAIN}} dc
```

```cmd
netdom query /domain:{{DOMAIN}} workstation
```

