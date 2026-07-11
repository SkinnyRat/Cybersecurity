# 22.2.1 — Enumeration Using Legacy Windows Tools (`net.exe`)

- Module: PEN-200 · 22. Active Directory Introduction and Enumeration
- Source: portal.offsec.com · module `active-directory-introduction-and-enumeration-45847` (§22.2.1)
- Code blocks: 6

> Assumed breach: we authenticate to a domain-joined Win11 box as the low-priv user `{{USERNAME}}`
> and start with the "low-hanging fruit". Terminal output omitted.

## Connect over RDP

```bash
xfreerdp /u:{{USERNAME}} /d:{{DOMAIN}} /v:{{TARGET_IP}}
```

```bash
# non-interactive: accept the target cert and pass the password inline
xfreerdp /cert:ignore /u:{{USERNAME}} /d:{{DOMAIN}} /p:{{PASSWORD}} /v:{{TARGET_IP}}
```

> **Prefer RDP over WinRM / PowerShell Remoting.** WinRM triggers the **Kerberos double-hop**
> problem, which breaks onward domain-enumeration tools. RDP sidesteps it.

## Enumerate users with `net.exe` (built-in LOLBIN, every Windows)

```cmd
net user /domain
```

```cmd
net user {{TARGET_USER}} /domain
```

> Look at the `Global Group memberships` line — e.g. jeffadmin shows `*Domain Admins`. Admins
> often prefix/suffix privileged accounts (`...admin`), so inspect those first.

## Enumerate groups with `net.exe`

```cmd
net group /domain
```

```cmd
net group "{{GROUP_NAME}}" /domain
```

> **Key limitation:** `net group` lists only **user** members — it silently misses **nested
> groups** (a group inside a group) and can't show arbitrary attributes. Use the LDAP/PowerView
> methods in the next sections to catch nested membership. This is why custom tooling wins.
