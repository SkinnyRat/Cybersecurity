# Section 5: Initial Enumeration of the Domain

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1265
- Code/command blocks: 14

> Terminal output is omitted; only commands & scripts are captured.

```bash
sudo -E wireshark
```

```bash
sudo tcpdump -i ens224
```

```bash
sudo responder -I ens224 -A
```

```bash
fping -asgq 172.16.5.0/23
```

```bash
sudo nmap -v -A -iL hosts.txt -oN /home/htb-student/Documents/host-enum
```

```bash
nmap -A 172.16.5.100
```

```bash
sudo git clone https://github.com/ropnop/kerbrute.git
```

```bash
make help
```

```bash
sudo make all
```

```bash
ls dist/
```

```bash
./kerbrute_linux_amd64 
```

```bash
echo $PATH
```

```bash
sudo mv kerbrute_linux_amd64 /usr/local/bin/kerbrute
```

```bash
kerbrute userenum -d {{DOMAIN_UPPER}} --dc {{DC_IP}} jsmith.txt -o valid_ad_users
```
