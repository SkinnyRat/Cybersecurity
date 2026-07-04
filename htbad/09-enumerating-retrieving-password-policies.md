# Section 9: Enumerating & Retrieving Password Policies

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1490
- Code/command blocks: 12

> Terminal output is omitted; only commands & scripts are captured.

## 1. `shellsession` _(output omitted)_

```bash
crackmapexec smb 172.16.5.5 -u avazquez -p Password123 --pass-pol
```

## 2. `shellsession` _(output omitted)_

```bash
rpcclient -U "" -N 172.16.5.5
```

## 3. `shellsession` _(output omitted)_

```bash
enum4linux -P 172.16.5.5
```

## 4. `shellsession` _(output omitted)_

```bash
enum4linux-ng -P 172.16.5.5 -oA ilfreight
```

## 5. `shellsession` _(output omitted)_

```bash
cat ilfreight.json 
```

## 6. `cmd` _(output omitted)_

```cmd
net use \\DC01\ipc$ "" /u:""
```

## 7. `cmd` _(output omitted)_

```cmd
net use \\DC01\ipc$ "" /u:guest
```

## 8. `cmd` _(output omitted)_

```cmd
net use \\DC01\ipc$ "password" /u:guest
```

## 9. `cmd` _(output omitted)_

```cmd
net use \\DC01\ipc$ "password" /u:guest
```

## 10. `shellsession` _(output omitted)_

```bash
ldapsearch -h 172.16.5.5 -x -b "DC=INLANEFREIGHT,DC=LOCAL" -s sub "*" | grep -m 1 -B 10 pwdHistoryLength
```

## 11. `cmd` _(output omitted)_

```cmd
net accounts
```

## 12. `powershell` _(output omitted)_

```powershell
import-module .\PowerView.ps1
Get-DomainPolicy
```

