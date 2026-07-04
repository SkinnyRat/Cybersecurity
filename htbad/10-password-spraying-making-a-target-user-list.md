# Section 10: Password Spraying - Making a Target User List

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1455
- Code/command blocks: 7

> Terminal output is omitted; only commands & scripts are captured.

## 1. `shellsession` _(output omitted)_

```bash
enum4linux -U {{DC_IP}}  | grep "user:" | cut -f2 -d"[" | cut -f1 -d"]"
```

## 2. `shellsession` _(output omitted)_

```bash
rpcclient -U "" -N {{DC_IP}}
```

## 3. `shellsession` _(output omitted)_

```bash
crackmapexec smb {{DC_IP}} --users
```

## 4. `shellsession` _(output omitted)_

```bash
ldapsearch -h {{DC_IP}} -x -b "DC={{DOMAIN_NB}},DC=LOCAL" -s sub "(&(objectclass=user))"  | grep sAMAccountName: | cut -f2 -d" "
```

## 5. `shellsession` _(output omitted)_

```bash
./windapsearch.py --dc-ip {{DC_IP}} -u "" -U
```

## 6. `shellsession` _(output omitted)_

```bash
 kerbrute userenum -d {{DOMAIN}} --dc {{DC_IP}} /opt/jsmith.txt 
```

## 7. `shellsession` _(output omitted)_

```bash
sudo crackmapexec smb {{DC_IP}} -u htb-student -p Academy_student_AD! --users
```

