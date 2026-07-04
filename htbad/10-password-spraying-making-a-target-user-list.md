# Section 10: Password Spraying - Making a Target User List

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1455
- Code/command blocks: 7

> Terminal output is omitted; only commands & scripts are captured.

## 1. `shellsession` _(output omitted)_

```bash
enum4linux -U 172.16.5.5  | grep "user:" | cut -f2 -d"[" | cut -f1 -d"]"
```

## 2. `shellsession` _(output omitted)_

```bash
rpcclient -U "" -N 172.16.5.5
```

## 3. `shellsession` _(output omitted)_

```bash
crackmapexec smb 172.16.5.5 --users
```

## 4. `shellsession` _(output omitted)_

```bash
ldapsearch -h 172.16.5.5 -x -b "DC=INLANEFREIGHT,DC=LOCAL" -s sub "(&(objectclass=user))"  | grep sAMAccountName: | cut -f2 -d" "
```

## 5. `shellsession` _(output omitted)_

```bash
./windapsearch.py --dc-ip 172.16.5.5 -u "" -U
```

## 6. `shellsession` _(output omitted)_

```bash
 kerbrute userenum -d inlanefreight.local --dc 172.16.5.5 /opt/jsmith.txt 
```

## 7. `shellsession` _(output omitted)_

```bash
sudo crackmapexec smb 172.16.5.5 -u htb-student -p Academy_student_AD! --users
```

