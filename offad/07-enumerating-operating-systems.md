# 22.3.1 — Enumerating Operating Systems

- Module: PEN-200 · 22. Active Directory Introduction and Enumeration
- Source: portal.offsec.com · module `active-directory-introduction-and-enumeration-45847` (§22.3.1)
- Code blocks: 3

> Pull OS/hostname straight from AD (no port scanning) via PowerView's `Get-NetComputer`.
> Output omitted.

```powershell
Get-NetComputer
```

```powershell
Get-NetComputer | select operatingsystem,dnshostname
```

```powershell
Get-NetComputer | select dnshostname,operatingsystem,operatingsystemversion
```

> Grab this early: it maps the estate (which hosts are DCs / servers / clients) and flags the
> **oldest OS** as a likely soft target. In the lab this exposes 6 machines — DC1, web04, files04
> (servers) plus client74/75/76 — and CLIENT76 running the oldest build (Win10 1709, `16299`).
