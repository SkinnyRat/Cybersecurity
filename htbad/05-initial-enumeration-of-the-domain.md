# Section 5: Initial Enumeration of the Domain

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1265
- Code/command blocks: 14

> Terminal output is omitted; only commands & scripts are captured.

## 1. `shellsession` _(output omitted)_

```bash
sudo -E wireshark
```

## 2. `shellsession`

```bash
sudo tcpdump -i ens224
```

## 3. `bash`

```bash
sudo responder -I ens224 -A
```

## 4. `shellsession` _(output omitted)_

```bash
fping -asgq 172.16.5.0/23
```

## 5. `bash`

```bash
sudo nmap -v -A -iL hosts.txt -oN /home/htb-student/Documents/host-enum
```

## 6. `shellsession` _(output omitted)_

```bash
nmap -A 172.16.5.100
```

## 7. `shellsession` _(output omitted)_

```bash
sudo git clone https://github.com/ropnop/kerbrute.git
```

## 8. `shellsession` _(output omitted)_

```bash
make help
```

## 9. `shellsession` _(output omitted)_

```bash
sudo make all
```

## 10. `shellsession` _(output omitted)_

```bash
ls dist/
```

## 11. `shellsession` _(output omitted)_

```bash
./kerbrute_linux_amd64 
```

## 12. `shellsession` _(output omitted)_

```bash
echo $PATH
```

## 13. `shellsession`

```bash
sudo mv kerbrute_linux_amd64 /usr/local/bin/kerbrute
```

## 14. `shellsession` _(output omitted)_

```bash
kerbrute userenum -d INLANEFREIGHT.LOCAL --dc 172.16.5.5 jsmith.txt -o valid_ad_users
```
