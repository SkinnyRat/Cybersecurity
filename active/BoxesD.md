
#### SOP for active directory 

0. Always try `whoami /all` first 
1. Kerberoasting (needs SPN) & as-rep roasting 
2. GenericAll (can change password), GenericWrite, WriteDACL 
3. DCsync needs GetChanges & GetChangesAll (add rights with Add-DomainObjectAcl if WriteDACL) 
4. RBCD (needs SeMachineAccountPrivilege, WriteProperty on the domain machine) 


#### Unusual exploits 
- SeRestorePrivilege = in C:\Windows\system32 rename `cmd.exe` = Ultiman.exe (might need EnableSeRestorePrivilege.ps1 first) then rdesktop ~> Win+U 
- SeManageVolumePrivilege = https://github.com/CsEnox/SeManageVolumeExploit then `icacls C:\Windows\System32` 
- GenericWrite on Domain Policy = `SharpGPOAbuse.exe --AddLocalAdmin --GPOName "Default Domain Policy" --UserAccount {{USERNAME}}` 
- ReadLAPSPassword = `nxc ldap {{DC_IP}} -u {{USERNAME}} -p {{PASSWORD}} -M laps` 


> Have DACL control via WriteDACL? use bloodyAD to add rights, eg GenericAll, GenericWrite. <br/>
> Have GenericWrite over a target? use bloodyAD to modify attributes directly, eg adding shadow credentials, group memberships, or SPNs. 
