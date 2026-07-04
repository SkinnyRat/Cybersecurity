# Section 15: Credentialed Enumeration - from Windows

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1421
- Code/command blocks: 19

> Terminal output is omitted; only commands & scripts are captured.

## 1. `powershell` _(output omitted)_

```powershell
Get-Module
```

## 2. `powershell` _(output omitted)_

```powershell
Import-Module ActiveDirectory
Get-Module
```

## 3. `powershell` _(output omitted)_

```powershell
Get-ADDomain
```

## 4. `powershell` _(output omitted)_

```powershell
Get-ADUser -Filter {ServicePrincipalName -ne "$null"} -Properties ServicePrincipalName
```

## 5. `powershell` _(output omitted)_

```powershell
Get-ADTrust -Filter *
```

## 6. `powershell` _(output omitted)_

```powershell
Get-ADGroup -Filter * | select name
```

## 7. `powershell` _(output omitted)_

```powershell
Get-ADGroup -Identity "Backup Operators"
```

## 8. `powershell` _(output omitted)_

```powershell
Get-ADGroupMember -Identity "Backup Operators"
```

## 9. `powershell` _(output omitted)_

```powershell
cd C:\Tools\
PS C:\Tools> Import-Module .\PowerView.ps1
Get-DomainUser -Identity mmorgan -Domain {{DOMAIN}} | Select-Object -Property name,samaccountname,description,memberof,whencreated,pwdlastset,lastlogontimestamp,accountexpires,admincount,userprincipalname,serviceprincipalname,useraccountcontrol
```

## 10. `powershell` _(output omitted)_

```powershell
 Get-DomainGroupMember -Identity "Domain Admins" -Recurse
```

## 11. `powershell` _(output omitted)_

```powershell
Get-DomainTrustMapping
```

## 12. `powershell` _(output omitted)_

```powershell
Test-AdminAccess -ComputerName ACADEMY-EA-MS01
```

## 13. `powershell` _(output omitted)_

```powershell
Get-DomainUser -SPN -Properties samaccountname,ServicePrincipalName
```

## 14. `powershell` _(output omitted)_

```powershell
.\SharpView.exe Get-DomainUser -Help
```

## 15. `powershell` _(output omitted)_

```powershell
.\SharpView.exe Get-DomainUser -Identity {{USERNAME}}
```

## 16. `bash`

```bash
Snaffler.exe -s -d {{DOMAIN}} -o snaffler.log -v data
```

## 17. `powershell` _(output omitted)_

```powershell
.\Snaffler.exe  -d {{DOMAIN_UPPER}} -s -v data
```

## 18. `powershell` _(output omitted)_

```powershell
 .\SharpHound.exe --help
```

## 19. `powershell` _(output omitted)_

```powershell
.\SharpHound.exe -c All --zipfilename ILFREIGHT
```

