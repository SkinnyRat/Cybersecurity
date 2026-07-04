# Section 15: Credentialed Enumeration - from Windows

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1421
- Code/command blocks: 19

> Terminal output is omitted; only commands & scripts are captured.

```powershell
Get-Module
```

```powershell
Import-Module ActiveDirectory
Get-Module
```

```powershell
Get-ADDomain
```

```powershell
Get-ADUser -Filter {ServicePrincipalName -ne "$null"} -Properties ServicePrincipalName
```

```powershell
Get-ADTrust -Filter *
```

```powershell
Get-ADGroup -Filter * | select name
```

```powershell
Get-ADGroup -Identity "Backup Operators"
```

```powershell
Get-ADGroupMember -Identity "Backup Operators"
```

```powershell
cd C:\Tools\
PS C:\Tools> Import-Module .\PowerView.ps1
Get-DomainUser -Identity mmorgan -Domain {{DOMAIN}} | Select-Object -Property name,samaccountname,description,memberof,whencreated,pwdlastset,lastlogontimestamp,accountexpires,admincount,userprincipalname,serviceprincipalname,useraccountcontrol
```

```powershell
 Get-DomainGroupMember -Identity "Domain Admins" -Recurse
```

```powershell
Get-DomainTrustMapping
```

```powershell
Test-AdminAccess -ComputerName ACADEMY-EA-MS01
```

```powershell
Get-DomainUser -SPN -Properties samaccountname,ServicePrincipalName
```

```powershell
.\SharpView.exe Get-DomainUser -Help
```

```powershell
.\SharpView.exe Get-DomainUser -Identity {{USERNAME}}
```

```bash
Snaffler.exe -s -d {{DOMAIN}} -o snaffler.log -v data
```

```powershell
.\Snaffler.exe  -d {{DOMAIN_UPPER}} -s -v data
```

```powershell
 .\SharpHound.exe --help
```

```powershell
.\SharpHound.exe -c All --zipfilename ILFREIGHT
```

