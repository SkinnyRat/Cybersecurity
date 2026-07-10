# OffSec PEN-200 — Active Directory Notes (Modules 22–24)

Commands and scripts consolidated from the three **Active Directory** modules of the OffSec
**PEN-200 (OSCP+)** course:

- **22. Active Directory Introduction and Enumeration** — recon
- **23. Attacking Active Directory Authentication** — credential/ticket attacks
- **24. Lateral Movement in Active Directory** — movement + persistence

This is the OffSec companion to [`../htbad/`](../htbad/README.md) (the HTB "AD Enumeration &
Attacks" module). Same spirit: one file per section, **flat sequential numbering `01…N`** across
all three modules (like htbad's `01…36`), commands kept, terminal **output omitted**, scripts kept
in full, and reusable command inputs parameterized with `{{VAR}}` placeholders that
**[WorkflowHelper.html](../WorkflowHelper.html)** fills in. Each file's H1 carries its OffSec
section number (e.g. `23.2.3`) for traceability.

## The lab scenario (referenced throughout)

Assumed breach of `corp.com`. The chain runs low-priv user → local admin → Domain Admin across
CLIENT74/75/76, FILES04, WEB04, and DC1. Placeholder mapping:

| Placeholder | Typical lab value | Meaning |
|---|---|---|
| `{{DOMAIN}}` / `{{DOMAIN_NB}}` | corp.com / corp | domain (FQDN / NetBIOS) |
| `{{USERNAME}}` / `{{PASSWORD}}` | stephanie, jeff, jen, pete… | account we operate/move as |
| `{{TARGET_USER}}` | jeffadmin, dave, iis_service, krbtgt | victim (roast / dcsync / forge) |
| `{{TARGET_IP}}` / `{{COMPUTER_NAME}}` | 192.168.50.73 / files04 | host we act against |
| `{{DC_IP}}` | 192.168.50.70 | DC1 (also DNS) |
| `{{NTLM_HASH}}` / `{{SID}}` | — | hash for PtH/forge / domain SID |
| `{{LHOST}}` / `{{LPORT}}` | 192.168.118.2 / 443 | Kali listener for reverse shells |

`{{SID}}` is intentionally left unregistered in WorkflowHelper (fill it by hand), matching the
htbad convention.

## Sections

### Module 22 — Introduction & Enumeration
| # | Section | File |
|---|---------|------|
| 22.1 | Active Directory — introduction | [01](01-active-directory-introduction.md) |
| 22.1.1 | Enumeration — defining our goals | [02](02-enumeration-defining-our-goals.md) |
| 22.2.1 | Enumeration using legacy Windows tools (`net.exe`) | [03](03-enumeration-using-legacy-windows-tools.md) |
| 22.2.2 | Enumerating AD using PowerShell & .NET classes | [04](04-powershell-and-net-classes.md) |
| 22.2.3 | Adding search functionality to our script | [05](05-adding-search-functionality-to-our-script.md) |
| 22.2.4 | AD enumeration with PowerView | [06](06-ad-enumeration-with-powerview.md) |
| 22.3.1 | Enumerating operating systems | [07](07-enumerating-operating-systems.md) |
| 22.3.2 | Permissions & logged-on users | [08](08-permissions-and-logged-on-users.md) |
| 22.3.3 | Enumeration through SPNs | [09](09-enumeration-through-service-principal-names.md) |
| 22.3.4 | Enumerating object permissions (ACLs) | [10](10-enumerating-object-permissions.md) |
| 22.3.5 | Enumerating domain shares | [11](11-enumerating-domain-shares.md) |
| 22.4.1 | Collecting data with SharpHound | [12](12-collecting-data-with-sharphound.md) |
| 22.4.2 | Analysing data with BloodHound | [13](13-analysing-data-with-bloodhound.md) |
| 22.5 | Wrapping up | [14](14-wrapping-up.md) |

### Module 23 — Attacking AD Authentication
| # | Section | File |
|---|---------|------|
| 23.1.1 | NTLM authentication | [15](15-ntlm-authentication.md) |
| 23.1.2 | Kerberos authentication | [16](16-kerberos-authentication.md) |
| 23.1.3 | Cached AD credentials (Mimikatz) | [17](17-cached-ad-credentials.md) |
| 23.2.1 | Password attacks (spraying) | [18](18-password-attacks.md) |
| 23.2.2 | AS-REP Roasting | [19](19-as-rep-roasting.md) |
| 23.2.3 | Kerberoasting | [20](20-kerberoasting.md) |
| 23.2.4 | Silver Tickets | [21](21-silver-tickets.md) |
| 23.2.5 | Domain Controller Synchronization (DCSync) | [22](22-domain-controller-synchronization.md) |
| 23.3 | Wrapping up | [23](23-attacking-ad-authentication-wrapping-up.md) |

### Module 24 — Lateral Movement
| # | Section | File |
|---|---------|------|
| 24.1.1 | WMI and WinRM | [24](24-wmi-and-winrm.md) |
| 24.1.2 | PsExec | [25](25-psexec.md) |
| 24.1.3 | Pass the Hash | [26](26-pass-the-hash.md) |
| 24.1.4 | Overpass the Hash | [27](27-overpass-the-hash.md) |
| 24.1.5 | Pass the Ticket | [28](28-pass-the-ticket.md) |
| 24.1.6 | DCOM | [29](29-dcom.md) |
| 24.2.1 | Golden Ticket | [30](30-golden-ticket.md) |
| 24.2.2 | Shadow Copies | [31](31-shadow-copies.md) |
| 24.3 | Wrapping up | [32](32-lateral-movement-wrapping-up.md) |

_Source: PEN-200 course, portal.offsec.com — modules `...-45847`, `...-46102`, `...-47888`._
_Conceptual sections (22.1, 22.1.1, 22.5, 23.1.1, 23.1.2, 23.3, 24.3) are kept as short theory/summary notes._
