# 24.1.2 — PsExec

- Module: PEN-200 · 24. Lateral Movement in Active Directory
- Source: portal.offsec.com · module `lateral-movement-in-active-directory-47888` (§24.1.2)
- Code blocks: 1

> SysInternals PsExec gives an **interactive** remote shell — directly, no reverse shell/Kali
> needed. Output omitted.

## Requirements

1. Authenticating user is in the target's **local Administrators** group.
2. **ADMIN$** share available (default on Windows Server).
3. **File and Printer Sharing** on (default).

## Interactive remote shell

```powershell
.\PsExec64.exe -i \\{{COMPUTER_NAME}} -u {{DOMAIN_NB}}\{{USERNAME}} -p {{PASSWORD}} cmd
```

> Under the hood PsExec drops `psexesvc.exe` into `C:\Windows`, creates+starts a service, and runs
> your command as its child. Verify with `hostname` / `whoami` on the returned shell.
