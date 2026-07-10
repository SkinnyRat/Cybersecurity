# 22.2.3 — Adding Search Functionality to Our Script

- Module: PEN-200 · 22. Active Directory Introduction and Enumeration
- Source: portal.offsec.com · module `active-directory-introduction-and-enumeration-45847` (§22.2.3)
- Code blocks: 6

> Add search on top of the LDAP path from §22.2.2 using two `System.DirectoryServices` classes:
> **DirectoryEntry** (encapsulates the LDAP path / search root) and **DirectorySearcher** (runs
> the LDAP query; `FindAll()` returns all matches). Output omitted.

## Basic searcher (all objects, then filtered to users)

```powershell
$PDC  = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().PdcRoleOwner.Name
$DN   = ([adsi]'').distinguishedName
$LDAP = "LDAP://$PDC/$DN"

$direntry    = New-Object System.DirectoryServices.DirectoryEntry($LDAP)
$dirsearcher = New-Object System.DirectoryServices.DirectorySearcher($direntry)
$dirsearcher.filter="samAccountType=805306368"   # 0x30000000 = all normal user accounts
$dirsearcher.FindAll()
```

> `samAccountType` applies to all user/computer/group objects; `805306368` filters to normal users.
> Without a filter, `FindAll()` dumps every object in the domain.

## Print selected attributes (nested loops)

```powershell
$result = $dirsearcher.FindAll()
Foreach($obj in $result)
{
    Foreach($prop in $obj.Properties)
    {
        $prop            # e.g. $prop.memberof to show only group membership
    }
    Write-Host "-------------------------------"
}
```

> Change `$dirsearcher.filter="name=jeffadmin"` and use `$prop.memberof` to confirm a single
> user's groups (e.g. jeffadmin → Domain Admins, Builtin\Administrators).

## Turn it into a reusable function (`function.ps1`)

```powershell
function LDAPSearch {
    param (
        [string]$LDAPQuery
    )

    $PDC = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().PdcRoleOwner.Name
    $DistinguishedName = ([adsi]'').distinguishedName

    $DirectoryEntry = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$PDC/$DistinguishedName")
    $DirectorySearcher = New-Object System.DirectoryServices.DirectorySearcher($DirectoryEntry, $LDAPQuery)

    return $DirectorySearcher.FindAll()
}
```

Import and use it:

```powershell
Import-Module .\function.ps1

LDAPSearch -LDAPQuery "(samAccountType=805306368)"   # all users
LDAPSearch -LDAPQuery "(objectclass=group)"          # all groups (incl. domain-local ones net.exe misses)
```

## Unravel nested groups

```powershell
# list every group's members
foreach ($group in $(LDAPSearch -LDAPQuery "(objectCategory=group)")) {
    $group.properties | select {$_.cn}, {$_.member}
}

# focus one group, then walk the chain of nested groups
$group = LDAPSearch -LDAPQuery "(&(objectCategory=group)(cn={{GROUP_NAME}}))"
$group.properties.member
```

> This LDAP approach reveals **nested groups** (e.g. Development Dept is a member of Sales Dept,
> Management Dept is a member of Development Dept) that `net.exe` completely missed. Members
> inherit membership up the chain — a common source of unintended privilege.
