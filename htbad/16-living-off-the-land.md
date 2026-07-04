# Section 16: Living Off the Land

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1360
- Code/command blocks: 16

> Terminal output is omitted; only commands & scripts are captured.

```powershell
Get-Module
Get-ExecutionPolicy -List
whoami
Get-ChildItem Env: | ft key,value
```

```powershell
Get-host
powershell.exe -version 2
Get-host
get-module
```

```powershell
netsh advfirewall show allprofiles
```

```cmd
sc query windefend
```

```powershell
Get-MpComputerStatus
```

```powershell
qwinsta
```

```powershell
arp -a
```

```powershell
route print
```

```powershell
wmic ntdomain get Caption,Description,DnsForestName,DomainName,DomainControllerAddress
```

```powershell
net group /domain
```

```powershell
net user /domain wrouse
```

```powershell
dsquery user
```

```powershell
dsquery computer
```

```powershell
dsquery * "CN=Users,DC={{DOMAIN_NB}},DC=LOCAL"
```

```powershell
dsquery * -filter "(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=32))" -attr distinguishedName userAccountControl
```

```powershell
dsquery * -filter "(userAccountControl:1.2.840.113556.1.4.803:=8192)" -limit 5 -attr sAMAccountName
```

