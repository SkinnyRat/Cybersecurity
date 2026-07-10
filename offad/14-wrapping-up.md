# 22.5 — Wrapping Up

- Module: PEN-200 · 22. Active Directory Introduction and Enumeration
- Source: portal.offsec.com · module `active-directory-introduction-and-enumeration-45847` (§22.5)
- Code blocks: 0 _(summary)_

## What this module gave us

Enumeration of `corp.com` from a single low-priv foothold (`{{USERNAME}}`), using three escalating
toolsets — all ultimately talking **LDAP**:

1. **Built-in / legacy** — `net.exe`, `setspn.exe` (LOLBINs; miss nested groups & attributes).
2. **PowerShell + .NET / ADSI** — our own `LDAPSearch` function, and **PowerView** (catches nested
   groups, arbitrary attributes, ACLs, sessions, shares).
3. **Automated** — **SharpHound** collection → **BloodHound** graph analysis for shortest paths.

## The enumeration checklist (what to always pull)

- Users, groups, **nested** group membership; dormant accounts (`pwdlastset`/`lastlogon`).
- Computers + OS/build (spot the weakest hosts).
- Where our user is **local admin** (`Find-LocalAdminAccess`).
- **Logged-on sessions** (PsLoggedOn / SharpHound) → credential-theft targets.
- **SPNs** → service accounts (Kerberoast targets).
- **Object ACLs** → GenericAll/WriteDACL/etc. misconfigurations.
- **Domain shares** → SYSVOL GPP `cpassword`, loose creds in files.

## Next

The path we mapped (stephanie → CLIENT74 → jeffadmin → Domain Admins) gets **executed** in the
follow-on modules *Attacking Active Directory Authentication* and *Lateral Movement in Active
Directory* — mirrored by the attack notes in [[../htbad/README]]. Remember the core discipline:
after every new foothold, **rinse and repeat** the whole enumeration from the new standpoint.
