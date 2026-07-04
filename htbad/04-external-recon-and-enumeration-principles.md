# Section 4: External Recon and Enumeration Principles

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1264
- Code blocks: 2

## Block 1 — `shellsession`

```shellsession
flickpeesai@htb[/htb]$ nslookup ns1.inlanefreight.com

Server:     192.168.186.1
Address:    192.168.186.1#53

Non-authoritative answer:
Name:   ns1.inlanefreight.com
Address: 178.128.39.165

nslookup ns2.inlanefreight.com
Server:     192.168.86.1
Address:    192.168.86.1#53

Non-authoritative answer:
Name:   ns2.inlanefreight.com
Address: 206.189.119.186
```

## Block 2 — `shellsession`

```shellsession
flickpeesai@htb[/htb]$ sudo python3 dehashed.py -q {{DOMAIN}} -p

id : 5996447501
email : roger.grimes@{{DOMAIN}}
username : rgrimes
password : Ilovefishing!
hashed_password : 
name : Roger Grimes
vin : 
address : 
phone : 
database_name : ModBSolutions

id : 7344467234
email : jane.yu@{{DOMAIN}}
username : jyu
password : Starlight1982_!
hashed_password : 
name : Jane Yu
vin : 
address : 
phone : 
database_name : MyFitnessPal

<SNIP>
```
