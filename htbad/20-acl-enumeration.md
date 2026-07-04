# Section 20: ACL Enumeration

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1485
- Code/command blocks: 11

> Terminal output is omitted; only commands & scripts are captured.

## 1. `powershell` _(output omitted)_

```powershell
Find-InterestingDomainAcl
```

## 2. `powershell`

```powershell
Import-Module .\PowerView.ps1
$sid = Convert-NameToSid wley
```

## 3. `powershell` _(output omitted)_

```powershell
Get-DomainObjectACL -Identity * | ? {$_.SecurityIdentifier -eq $sid}
```

## 4. `powershell` _(output omitted)_

```powershell
$guid= "00299570-246d-11d0-a768-00aa006e0529"
Get-ADObject -SearchBase "CN=Extended-Rights,$((Get-ADRootDSE).ConfigurationNamingContext)" -Filter {ObjectClass -like 'ControlAccessRight'} -Properties * |Select Name,DisplayName,DistinguishedName,rightsGuid| ?{$_.rightsGuid -eq $guid} | fl
```

## 5. `powershell` _(output omitted)_

```powershell
Get-DomainObjectACL -ResolveGUIDs -Identity * | ? {$_.SecurityIdentifier -eq $sid} 
```

## 6. `powershell`

```powershell
Get-ADUser -Filter * | Select-Object -ExpandProperty SamAccountName > ad_users.txt
```

## 7. `powershell` _(output omitted)_

```powershell
foreach($line in [System.IO.File]::ReadLines("C:\Users\htb-student\Desktop\ad_users.txt")) {get-acl  "AD:\$(Get-ADUser $line)" | Select-Object Path -ExpandProperty Access | Where-Object {$_.IdentityReference -match 'INLANEFREIGHT\\wley'}}
```

## 8. `powershell` _(output omitted)_

```powershell
$sid2 = Convert-NameToSid damundsen
Get-DomainObjectACL -ResolveGUIDs -Identity * | ? {$_.SecurityIdentifier -eq $sid2} -Verbose
```

## 9. `powershell` _(output omitted)_

```powershell
Get-DomainGroup -Identity "Help Desk Level 1" | select memberof
```

## 10. `powershell` _(output omitted)_

```powershell
$itgroupsid = Convert-NameToSid "Information Technology"
Get-DomainObjectACL -ResolveGUIDs -Identity * | ? {$_.SecurityIdentifier -eq $itgroupsid} -Verbose
```

## 11. `powershell` _(output omitted)_

```powershell
$adunnsid = Convert-NameToSid adunn 
Get-DomainObjectACL -ResolveGUIDs -Identity * | ? {$_.SecurityIdentifier -eq $adunnsid} -Verbose
```

