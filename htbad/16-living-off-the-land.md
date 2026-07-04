# Section 16: Living Off the Land

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1360
- Code/command blocks: 16

> Terminal output is omitted; only commands & scripts are captured.

## 1. `powershell` _(output omitted)_

```powershell
Get-Module
Get-ExecutionPolicy -List
whoami
Get-ChildItem Env: | ft key,value
```

## 2. `powershell` _(output omitted)_

```powershell
Get-host
powershell.exe -version 2
Get-host
get-module
```

## 3. `powershell` _(output omitted)_

```powershell
netsh advfirewall show allprofiles
```

## 4. `cmd` _(output omitted)_

```cmd
sc query windefend
```

## 5. `powershell` _(output omitted)_

```powershell
Get-MpComputerStatus
```

## 6. `powershell` _(output omitted)_

```powershell
qwinsta
```

## 7. `powershell` _(output omitted)_

```powershell
arp -a
```

## 8. `powershell` _(output omitted)_

```powershell
route print
```

## 9. `powershell` _(output omitted)_

```powershell
wmic ntdomain get Caption,Description,DnsForestName,DomainName,DomainControllerAddress
```

## 10. `powershell` _(output omitted)_

```powershell
net group /domain
```

## 11. `powershell` _(output omitted)_

```powershell
net user /domain wrouse
```

## 12. `powershell` _(output omitted)_

```powershell
dsquery user
```

## 13. `powershell` _(output omitted)_

```powershell
dsquery computer
```

## 14. `powershell` _(output omitted)_

```powershell
dsquery * "CN=Users,DC=INLANEFREIGHT,DC=LOCAL"
```

## 15. `powershell` _(output omitted)_

```powershell
dsquery * -filter "(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=32))" -attr distinguishedName userAccountControl
```

## 16. `powershell` _(output omitted)_

```powershell
dsquery * -filter "(userAccountControl:1.2.840.113556.1.4.803:=8192)" -limit 5 -attr sAMAccountName
```

