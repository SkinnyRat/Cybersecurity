# 22.3.2 — Getting an Overview: Permissions & Logged-On Users

- Module: PEN-200 · 22. Active Directory Introduction and Enumeration
- Source: portal.offsec.com · module `active-directory-introduction-and-enumeration-45847` (§22.3.2)
- Code blocks: 5

> Build a map of **which user is logged in where** and **where we have admin** — the raw material
> for an attack path. Output omitted.

## Where do we have local admin?

```powershell
Find-LocalAdminAccess
```

> Sprays every domain computer, opening the SCM with `SC_MANAGER_ALL_ACCESS` (needs admin) — if it
> succeeds, our user is a local admin there. In the lab, `{{USERNAME}}` (stephanie) → **CLIENT74**.

## Who is logged on — PowerView (often blocked on modern Windows)

```powershell
Get-NetSession -ComputerName {{COMPUTER_NAME}}
Get-NetSession -ComputerName {{COMPUTER_NAME}} -Verbose
```

> Uses `NetWkstaUserEnum` (needs admin) + `NetSessionEnum` (level 10). On modern hosts this returns
> **"Access is denied"**. Keep it in the toolkit anyway — it still works against older systems.

## Why it's blocked — check the registry ACL

```powershell
Get-Acl -Path HKLM:SYSTEM\CurrentControlSet\Services\LanmanServer\DefaultSecurity\ | fl
```

> `NetSessionEnum` reads the **SrvsvcSessionInfo** key. Since ~Win10 build 1709 / Server 2019 1809,
> normal domain users no longer have remote read on this hive (least-privilege change), so session
> enumeration fails for us on default installs.

## Who is logged on — PsLoggedOn (Sysinternals)

```powershell
.\PsLoggedon.exe \\{{COMPUTER_NAME}}
```

> Reads `HKEY_USERS` SIDs + `NetSessionEnum`. **Requires the Remote Registry service** on the
> target (off by default on workstations since Win8; often on for servers). In the lab this reveals
> **jeff** logged on to FILES04 and **jeffadmin** logged on to CLIENT74 — where stephanie is admin.
> That combination is the attack path: admin-on-CLIENT74 + jeffadmin-session-on-CLIENT74 ⇒ steal
> Domain Admin creds.
