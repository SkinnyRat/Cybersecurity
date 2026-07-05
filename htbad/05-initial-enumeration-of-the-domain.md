# Section 5: Initial Enumeration of the Domain

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1265
- Code/command blocks: 14

> Terminal output is omitted; only commands & scripts are captured.

```bash
sudo tcpdump -i tun0
```

```bash
sudo responder -I tun0 -A
```

```bash
fping -asgq {{SUBNET}}
```

```bash
sudo nmap -v -A -iL hosts.txt -oN /home/user/Documents/host-enum
```

```bash
nmap -A 172.16.5.100
```

```bash
sudo git clone https://github.com/ropnop/kerbrute.git
```

```bash
sudo make all
```

```bash
sudo mv kerbrute_linux_amd64 /usr/local/bin/kerbrute
```

```bash
kerbrute userenum -d {{DOMAIN}} --dc {{DC_IP}} {{USERLIST}} -o valid_ad_users
```

## Find the domain controller (from a foothold)

> 90% shortcut: in an AD domain the box's **DNS server = the DC**, so `ipconfig /all` (Windows) or `/etc/resolv.conf` (Linux) usually hands you the DC IP. The `nltest` / `LOGONSERVER` commands then confirm it by name.

### Windows foothold

```cmd
echo %LOGONSERVER%                        :: the DC that logged you in (\\DCNAME)
nltest /dsgetdc:{{DOMAIN}}               :: DC name + IP + site
nltest /dclist:{{DOMAIN}}                :: list ALL DCs
systeminfo | findstr /B /C:"Domain"      :: confirm the domain name
ipconfig /all                            :: DNS server ~= the DC
nslookup -type=srv _ldap._tcp.dc._msdcs.{{DOMAIN}}
```

```powershell
$env:LOGONSERVER
Resolve-DnsName -Type SRV _ldap._tcp.dc._msdcs.{{DOMAIN}}
```

### Linux foothold

```bash
cat /etc/resolv.conf                     # nameserver is usually the DC
nslookup -type=SRV _ldap._tcp.dc._msdcs.{{DOMAIN}}
dig SRV _ldap._tcp.dc._msdcs.{{DOMAIN}}
```

## SPN enumeration (Windows, LOLBIN)

> Built-in `setspn.exe` — no tools to drop. Works from any domain context (domain user, or SYSTEM / machine account on a domain-joined host).

List every SPN in the domain:

```cmd
setspn.exe -T {{DOMAIN}} -Q */*
```

Query a specific SPN to find the account it's registered to (answers "submit the account name"):

```cmd
setspn.exe -Q {{SPN}}
```

Pure-LDAP alternative (no RSAT needed):

```powershell
([adsisearcher]'(servicePrincipalName={{SPN}})').FindAll().Properties.samaccountname
```
