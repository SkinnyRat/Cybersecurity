
#### SOP for active directory 

1. Kerberoasting & as-rep roasting 
2. GenericAll (can change password) 
3. DCsync needs GetChanges & GetChangesAll (add rights with Add-DomainObjectAcl if WriteDACL) 
4. RBCD (needs SeMachineAccountPrivilege, WriteProperty on the domain machine) 


#### Unusual exploits 
SeManageVolumePrivilege = https://github.com/CsEnox/SeManageVolumeExploit then `icacls C:\Windows\System32` 
